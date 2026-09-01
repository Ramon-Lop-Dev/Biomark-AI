# Biomark AI — ai-service

Motor de inferencia modular: `main.py` orquesta `config.py`, `safety/`,
`rag/`, `inference/`, `voice/` y `vision/`. El mismo código sirve para
pruebas en Colab y para producción en un VPS — solo cambia cómo se arranca.

## Estructura

```
ai-service/
├── main.py                  # Orquestador: define todas las rutas HTTP
├── config.py                 # Variables de entorno, persona, dispositivo
├── requirements.txt
├── .env.example               # Plantilla — copiar como .env con credenciales reales
│
├── safety/
│   └── checker.py            # Capa de seguridad clínica
├── rag/
│   └── retriever.py          # Sincronización con Supabase + búsqueda RAG
├── inference/
│   ├── model_loader.py       # Carga del modelo de texto (GPU o CPU automático)
│   ├── generator.py          # Construcción de prompt + generación de texto
│   └── service.py            # Safety + RAG + generación, compartido por /chat, /voice, /vision
├── voice/
│   ├── asr.py                 # Voz -> texto (Whisper)
│   └── tts.py                 # Texto -> voz (VITS, facebook/mms-tts-spa)
└── vision/
    └── classifier.py          # Clasificación de imágenes: piel y garganta
```

## Endpoints

Todos (excepto `/health`) requieren el header `x-internal-key` con el
valor de `AI_SERVICE_INTERNAL_KEY`.

| Método | Ruta                | Descripción                                              |
|--------|----------------------|-----------------------------------------------------------|
| GET    | `/health`            | Estado del servicio y qué modelos cargaron                |
| POST   | `/chat`               | `{"message": "..."}` → respuesta de texto                 |
| POST   | `/voice`              | Sube un audio (`archivo`) → transcribe y responde          |
| POST   | `/audio/synthesize`   | `{"text": "..."}` → devuelve audio WAV                     |
| POST   | `/vision`             | Sube una imagen (`archivo`) + `?tipo=piel\|garganta`        |

Los tres canales de entrada (`/chat`, `/voice`, `/vision`) pasan por el
mismo `ClinicalService` (Safety Layer + RAG + generación), así que se
comportan igual sin importar cómo llegó la consulta.

### Modelo de garganta

A diferencia del modelo de piel (un solo `.keras`), el de garganta es un
pipeline de dos archivos publicado como Hugging Face Space
(`engrharis/Throat_Image_Classifier`): un extractor de características
MobileNetV2 (`.h5`) + un clasificador KNN (`.pkl`), con ~80% de precisión
reportada por su autor. `vision/classifier.py` descarga ambos automáticamente
la primera vez (se cachean localmente después). Si la descarga falla,
`/vision?tipo=garganta` responde `503` pero el resto del servicio sigue
funcionando con normalidad.

## Pruebas en Google Colab (por ahora)

**Celda 1 — Setup:**

```python
!pip install -q -r requirements.txt

# Sube tu .env real con tus credenciales, o créalo así:
%%writefile .env
SUPABASE_URL=https://tu-proyecto.supabase.co
SUPABASE_SERVICE_ROLE_KEY=tu_key_real
AI_SERVICE_INTERNAL_KEY=tu_key_real
```

```python
from pyngrok import ngrok
ngrok.kill()
ngrok.set_auth_token("TU_NGROK_TOKEN")
public_url = ngrok.connect("127.0.0.1:8000", "http")
print(f"URL pública: {public_url}")

from main import app
```

**Celda 2 — Arrancar el servidor:**

```python
import nest_asyncio, uvicorn
nest_asyncio.apply()
await uvicorn.Server(uvicorn.Config(app, host="0.0.0.0", port=8000)).serve()
```

Copia la URL pública impresa en la Celda 1 a `AI_SERVICE_URL` en el `.env`
de tu backend de Node.

> Si necesitas ver logs de peticiones que llegan desde afuera (Postman,
> tu backend) mientras el servidor corre en un `Thread` de Colab, redirige
> `stdout`/`stderr` a un archivo — Colab solo muestra en vivo el output de
> la celda que esté activa en ese momento, y las peticiones externas no
> tienen ninguna celda "activa" asociada.

## Migración a VPS (después)

1. Sube esta carpeta al VPS (sin `.env` — créalo ahí directamente, usa `.env.example` como base).
2. `python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt`
   - Si el VPS no tiene GPU y `bitsandbytes` falla al instalar, coméntalo en
     `requirements.txt` — no es obligatorio (ver nota en el archivo).
3. Prueba con arranque directo primero: `python main.py` (usa `if __name__ == "__main__"`, sin ngrok).
4. Para producción real, corre bajo `systemd` con `Restart=always` (plantilla
   lista en `deploy/ai-service.service`, ajusta `User`/`WorkingDirectory` a tu
   instalación) y pon Nginx o Caddy delante con HTTPS, en vez de exponer el
   puerto 8000 directo a internet.
5. Configura en el backend `AI_SERVICE_URL=http://ai-service:8000` cuando ambos servicios estén en el mismo `docker-compose`; no uses un dominio público para esta comunicación interna.

## Contrato interno de chat

El backend es el único cliente de este servicio. Cada petición requiere el header `X-Internal-Key` y usa este cuerpo:

```json
{
  "message": "Tengo fiebre desde ayer",
  "latitude": null,
  "longitude": null,
  "medical_context": null,
  "conversation_history": []
}
```

`POST /chat` devuelve `reply`, `risk_level`, `sources`, `suggested_action` y, si se enviaron coordenadas, `centro_sugerido`. `suggested_action` puede ser `REGISTER_PROGRESS`, `REGISTER_MEDICATION`, `REGISTER_REMINDER` o `SHOW_NEAREST_CENTER`.

La acción sugerida es una intención de UX, no una orden de escritura. El cliente debe pedir confirmación y el backend debe validar y persistir la operación. La IA no diagnostica, prescribe ni confirma por sí sola que un paciente mejoró.

Ejemplo:

```json
{
  "reply": "¿Quieres registrar cómo ha evolucionado la fiebre?",
  "risk_level": "LOW",
  "sources": ["Conocimiento general del modelo"],
  "suggested_action": "REGISTER_PROGRESS",
  "centro_sugerido": null
}
```

## Orden de arranque en VPS

1. Configura `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` y `AI_SERVICE_INTERNAL_KEY` únicamente en `deploy/ai-service.env`.
2. Inicia `ai-service` y verifica `curl http://127.0.0.1:8000/health` desde el contenedor o la red privada.
3. Inicia el backend con la misma `AI_SERVICE_INTERNAL_KEY` y `AI_SERVICE_URL=http://ai-service:8000`.
4. Verifica desde nginx `GET /health` y después prueba `POST /api/chat` con un JWT válido.

## Seguridad

- El `.env` real nunca se sube a git — usa `.env.example` como plantilla.
- `config.py` falla explícitamente si falta alguna variable de entorno
  obligatoria, en vez de arrancar con una llave de ejemplo filtrada como
  valor por defecto.
- Rota cualquier credencial que se haya expuesto antes de este cambio
  (Supabase, ngrok, llave interna).
