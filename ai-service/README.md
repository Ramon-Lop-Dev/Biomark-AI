# Biomark AI — AI Service (Python & FastAPI)

Microservicio interno de inferencia clínica y asistencia de salud preventiva desarrollado con **FastAPI**, **PyTorch** y **Hugging Face Transformers**. Proporciona procesamiento de lenguaje natural médico, transcripción y síntesis de voz, clasificación asistida de imágenes y búsqueda de normativas del MINSA mediante RAG.

---

## 1. Arquitectura de Módulos

```text
ai-service/
├── main.py                     # Servidor FastAPI y definición de rutas de inferencia
├── config.py                    # Variables de entorno y directrices de personalidad médica
├── requirements.txt             # Dependencias optimizadas para GPU (CUDA) y CPU
│
├── safety/
│   └── checker.py               # Capa determinista de seguridad clínica (bloqueo de prescripción y diagnóstico)
├── rag/
│   └── retriever.py             # Persistencia incremental en ChromaDB (indexed_files.json) y normativas MINSA
├── inference/
│   ├── model_loader.py          # Carga cuantizada de BioMistral 7B (BiomarkAI/Biomark-AI-Produccion)
│   ├── generator.py             # Construcción de prompts para Mistral Instruct y generación determinista
│   └── service.py               # Servicio unificado para chat, detección de progreso (REGISTER_PROGRESS), voz y visión
├── voice/
│   ├── asr.py                   # Whisper ASR para transcripción precisa de notas de voz
│   └── tts.py                   # Facebook MMS-TTS para síntesis de voz natural en español
├── vision/
│   └── classifier.py            # Red neuronal para evaluación de imágenes dermatológicas y faríngeas
└── gis/
    ├── specialty_mapper.py      # Mapeo de síntomas hacia especialidades médicas del MINSA
    └── locator.py               # Selección y enrutamiento a centros de salud
```

---

## 2. Directrices de Seguridad Clínica, IA y Accesibilidad

1. **Blindaje contra prescripción médica:** El modelo tiene terminantemente prohibido indicar nombres de fármacos, dosis o modificaciones de tratamientos médicos. Ante cualquier solicitud de recetas, orienta hacia la consulta médica presencial.
2. **Orientación preventiva sin diagnóstico definitivo:** Las respuestas identifican posibilidades y medidas de autocuidado preventivo sin emitir un diagnóstico conclusivo.
3. **Lenguaje claro y sin jerga técnica (Accesibilidad Universal):** Las respuestas se redactan en un lenguaje sencillo, comprensible para personas de cualquier nivel de alfabetización o familias de comunidades rurales, explicando términos médicos en palabras cotidianas.
4. **Contextualización con antecedentes del paciente:** Si el backend provee el historial clínico (alergias, hipertensión, diabetes, medicamentos), el asistente adapta sus consejos para evitar recomendaciones contraproducentes.
5. **Detección proactiva de evolución de síntomas:** En `sugerir_accion()`, evalúa expresiones en lenguaje natural (*"ya mejoré"*, *"sigo igual"*, *"empeoré"*, *"aún me duele"*) y emite la acción sugerida `REGISTER_PROGRESS` para desplegar la tarjeta de registro interactivo en el cliente.
6. **Persistencia incremental en ChromaDB:** Módulo RAG con manifiesto local (`chroma_db/indexed_files.json`) que omite la re-descarga y re-vectorización de documentos normativos ya procesados, reduciendo los tiempos de arranque a milisegundos.
7. **Modelo clínico especializado:** Adaptado para el modelo de producción en Hugging Face [`BiomarkAI/Biomark-AI-Produccion`](https://huggingface.co/BiomarkAI/Biomark-AI-Produccion) con plantilla de turnos compatible con Mistral.

---

## 3. Endpoints Disponibles

Todos los endpoints (con excepción del chequeo de disponibilidad `/health`) requieren autenticación a través del encabezado HTTP `X-Internal-Key`:

| Método | Ruta | Descripción |
| :--- | :--- | :--- |
| `GET` | `/health` | Verificación del estado del pod y modelos en memoria |
| `POST` | `/chat` | Inferencia de texto con antecedentes clínicos y contexto geográfico |
| `POST` | `/voice` | Entrada de audio (`.m4a` / `.wav`) -> Transcripción + Orientación + Audio sintetizado |
| `POST` | `/audio/synthesize` | Generación directa de audio WAV a partir de texto en español |
| `POST` | `/vision` | Análisis visual y orientación clínica (`?tipo=piel`, `?tipo=garganta`, `?tipo=receta`, `?tipo=examen`) |

---

## 4. Despliegue en RunPod (GPU Cloud)

Para producción con aceleración por hardware NVIDIA (VRAM recomendada $\ge 16\text{ GB}$):

1. **Instancia:** Seleccionar plantilla con PyTorch y soporte para CUDA 12.1.
2. **Puerto público:** Exponer el puerto `8000` mediante el proxy HTTP de RunPod.
3. **Variables de entorno (`.env`):**
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=tu_service_role_key
   AI_SERVICE_INTERNAL_KEY=tu_clave_interna_compartida
   DEVICE=cuda
   ```
4. **Ejecución del servicio:**
   ```bash
   pip install -r requirements.txt
   python main.py
   ```

---

## 5. Pruebas Automatizadas

```bash
# Verificación de filtros de seguridad clínica y clasificación de evolución
TESTING=1 python3 -m unittest discover -s . -p "test_*.py"
```
