# Biomark AI — ai-service

Motor de inferencia modular: `main.py` orquesta `config.py`, `safety/`,
`rag/`, e `inference/`. El mismo código sirve para pruebas en Colab y para
producción en un VPS — solo cambia cómo se arranca.

## Estructura

```
ai-service/
├── main.py                  # Orquestador: define /health y /chat
├── config.py                 # Variables de entorno, persona, dispositivo
├── requirements.txt

├── safety/
│   └── checker.py            # Capa de seguridad clínica
├── rag/
│   └── retriever.py          # Sincronización con Supabase + búsqueda RAG
├── inference/
│   ├── model_loader.py       # Carga del modelo (GPU o CPU automático)
│   └── generator.py          # Construcción de prompt + generación
├── voice/                    # Reservado para futuro
└── vision/                   # Reservado para futuro
```



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

## Migración a VPS (después)

1. Sube esta carpeta al VPS (sin `.env` — créalo ahí directamente).
2. `python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt`
3. Arranque directo: `python main.py` (usa `if __name__ == "__main__"`, sin ngrok).
4. Para producción real: correr bajo `systemd` (con `Restart=always`) y poner
   Nginx/Caddy delante con HTTPS, en vez de exponer el puerto 8000 directo.
5. Actualizar `AI_SERVICE_URL` en el backend de Node al dominio del VPS.

## Seguridad

- El `.env` real nunca se sube a git — usa `.env.example` como plantilla.
- `config.py` ahora **falla explícitamente** si falta alguna variable de
  entorno obligatoria, en vez de arrancar con una llave de ejemplo filtrada
  como valor por defecto (como pasaba en la versión anterior de `main.py`).
- Rota cualquier credencial que se haya expuesto antes de este cambio
  (Supabase, ngrok, llave interna).
