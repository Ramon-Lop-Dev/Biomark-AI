# Biomark AI — AI Service

Servicio interno de inferencia modular y asistencia en salud preventiva desarrollado con **FastAPI**, **PyTorch** y **Hugging Face Transformers**. Proporciona procesamiento de lenguaje natural clínico con barreras de seguridad deterministas, síntesis y transcripción de voz, clasificación de imágenes y contextualización con antecedentes médicos.

---

## 1. Arquitectura y Módulos

```text
ai-service/
├── main.py                     # Orquestador FastAPI y rutas de inferencia
├── config.py                    # Carga estricta de variables de entorno y configuración
├── requirements.txt             # Dependencias optimizadas para GPU y CPU
│
├── safety/
│   └── checker.py               # Capa de seguridad clínica determinista (no prescripción ni diagnóstico)
├── rag/
│   └── retriever.py             # Sincronización con Supabase y búsqueda RAG de normativas MINSA
├── inference/
│   ├── model_loader.py          # Carga dinámica del LLM (4-bit/8-bit GPU o CPU)
│   ├── generator.py             # Construcción de prompts contextuales y generación determinista
│   └── service.py               # ClinicalService compartido por chat, voz y visión
├── voice/
│   ├── asr.py                   # Whisper ASR (transcripción de consultas de voz)
│   └── tts.py                   # Facebook MMS-TTS (síntesis de voz en español formato audio)
├── vision/
│   └── classifier.py            # Red neuronal para imágenes dermatológicas y orofaríngeas
└── gis/
    ├── specialty_mapper.py      # Mapeo síntoma -> especialidad médica requerida
    └── locator.py               # Selección determinista de centros de salud MINSA
```

---

## 2. Protocolos de Seguridad Clínica y Prevención de Alucinaciones

1. **No Prescripción Médica:** La IA tiene estrictamente prohibido recetar fármacos o alterar posologías médicas. Cualquier solicitud de medicamentos devuelve una advertencia preventiva y la indicación de acudir a un centro de salud o médico tratante.
2. **No Diagnóstico Final:** El asistente no emite diagnósticos definitivos; ofrece orientación probabilística y pautas de autocuidado preventivo.
3. **Capacidad Educativa e Informativa:** Responde preguntas sobre condiciones médicas (ej. *¿Qué es el sarampión?*, *¿Cuáles son los síntomas del dengue?*) con rigor científico y normativas del MINSA.
4. **Seguimiento de Evolución de Síntomas:** Reconoce y clasifica estados clínicos de evolución:
   - `MEJORO`: Reducción o remisión de síntomas.
   - `IGUAL`: Síntomas estables sin variación significativa.
   - `EMPEORO`: Aumento en severidad o aparición de signos de alarma.
   - `NO_SEGURO`: Información insuficiente para determinar la trayectoria.
5. **Inyección de Contexto Clínico:** Cuando el backend provee antecedentes (`medical_context`), el LLM toma en cuenta alergias, enfermedades crónicas y medicamentos activos para evitar recomendaciones contraindicadas.

---

## 3. Endpoints del Servicio

Todos los endpoints (salvo `/health`) requieren autenticación mediante el header `X-Internal-Key: <AI_SERVICE_INTERNAL_KEY>`.

| Método | Ruta | Descripción |
|---|---|---|
| GET | `/health` | Chequeo de salud del pod y modelos cargados |
| POST | `/chat` | Consulta de texto con contexto clínico y ubicación opcional |
| POST | `/voice` | Entrada de audio (`.wav`/`.m4a`) -> Transcripción + Respuesta + Audio de voz |
| POST | `/audio/synthesize` | Síntesis directa de texto a audio WAV |
| POST | `/vision` | Análisis fotográfico de piel o garganta (`?tipo=piel\|garganta`) |

---

## 4. Despliegue en RunPod (GPU Cloud)

Para producción con aceleración por hardware (NVIDIA GPU con VRAM >= 16 GB):

1. **Crear Pod en RunPod:** Seleccionar plantilla con PyTorch / CUDA 12.1.
2. **Exponer Puerto:** Configurar el puerto `8000` como puerto HTTP público.
3. **Variables de Entorno (`.env`):**
   ```bash
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key
   AI_SERVICE_INTERNAL_KEY=tu_clave_interna_secreta
   DEVICE=cuda
   ```
4. **Instalar y Ejecutar:**
   ```bash
   pip install -r requirements.txt
   python main.py
   ```
5. **Conexión con Backend (Contabo):**
   En el backend en Contabo, configurar `AI_SERVICE_URL=https://POD_ID-8000.proxy.runpod.net`.
