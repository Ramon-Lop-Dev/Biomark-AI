# AI Service: despliegue VPS

Construcción: `docker build -f Dockerfile.ai-service -t biomark-ai .`. En Compose se expone solo dentro de la red Docker en `http://ai-service:8000`.

Pruebas: desde esta carpeta ejecuta `python3 -m unittest test_safety.py`. La suite no sustituye validación clínica ni pruebas de carga.

Copia `.env.example` a `deploy/ai-service.env` y usa la misma `AI_SERVICE_INTERNAL_KEY` del backend. No expongas `/chat`, `/voice` ni `/vision` directamente a Internet: todos exigen la llave interna, pero la red privada es defensa adicional.

El servicio puede consumir varios GB de RAM al cargar LLM, embeddings, ASR, TTS y visión. Usa un VPS con RAM suficiente, disco persistente para `/root/.cache/huggingface` y `/app/chroma_db`, y un solo worker salvo que exista GPU y memoria probada. Revisa `/health` y `/ready` después de cada actualización.

El modelo de visión requiere validación clínica antes de producción; sus resultados son apoyo informativo y no diagnóstico.
