# Guía de Despliegue de Biomark AI (`ai-service`) en RunPod

Esta guía explica paso a paso cómo desplegar el microservicio de inteligencia artificial de **Biomark AI** (`ai-service`) en una instancia GPU de **RunPod**, permitiendo ejecutar el modelo LLM, Whisper (ASR), TTS y visión con máxima velocidad y bajo costo.

---

## 1. Requisitos Previos en RunPod
- Cuenta activa en [RunPod.io](https://www.runpod.io/).
- Créditos disponibles (generalmente \$0.20 - \$0.40 / hora para una GPU RTX 3090 o RTX 4090).
- Claves de tu base de datos Supabase:
  - `SUPABASE_URL`
  - `SUPABASE_SERVICE_ROLE_KEY`
  - `AI_SERVICE_INTERNAL_KEY` (clave secreta compartida con el backend de Node.js).

---

## 2. Crear el Pod GPU en RunPod

1. En la consola de RunPod, ve a **Pods** -> **Deploy Pod**.
2. Selecciona una GPU con al menos **16 GB o 24 GB de VRAM**:
   - Recomendado: **NVIDIA RTX 3090 (24 GB)**, **RTX 4090 (24 GB)** o **A4000/A5000**.
3. **Template:**
   - Puedes usar la plantilla oficial: `RunPod PyTorch 2.1` (`runpod/pytorch:2.1.0-py3.10-cuda11.8.0-devel-ubuntu22.04`).
   - O construir y usar la imagen Docker con el archivo `Dockerfile` incluido en `ai-service/`.
4. **Almacenamiento (Volume & Container Disk):**
   - Container Disk: 20 GB.
   - Volume Disk (persistente): 30 GB o más (aquí se guardan los pesos de Hugging Face y ChromaDB).
5. **Puertos Expuestos:**
   - En **Expose HTTP Ports**, agrega el puerto `8000`.
6. Haz clic en **Continue** -> **Deploy**.

---

## 3. Configuración y Arranque del Servicio

Una vez que el Pod esté en estado **Running**:
1. Conéctate vía **Connect** -> **Start Web Terminal** (o vía SSH).
2. Clona o sube el directorio `ai-service`:
   ```bash
   cd /workspace
   git clone https://github.com/Ramon-Lop-Dev/Biomark-AI.git
   cd Biomark-AI/ai-service
   ```
3. Configura el archivo `.env`:
   ```bash
   cp .env.example .env
   nano .env
   ```
   Define los valores reales:
   ```ini
   AI_SERVICE_INTERNAL_KEY=tu_clave_secreta_compartida
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_SERVICE_ROLE_KEY=tu_supabase_service_role_key
   MODEL_ID=BiomarkAI/Biomark-AI-Produccion
   PORT=8000
   ```
4. Ejecuta el script de inicio automático:
   ```bash
   bash runpod_start.sh
   ```
   El script verificará la GPU con `nvidia-smi`, instalará `ffmpeg` y las dependencias de Python, y levantará el servidor en `0.0.0.0:8000`.

---

## 4. Conexión del Backend de Biomark al Pod de RunPod

RunPod provee un proxy público seguro para el puerto 8000:
- URL del Proxy: `https://<POD_ID>-8000.proxy.runpod.net`

En el servidor donde corre tu `backend` (VPS Contabo, Render o local):
1. Abre tu archivo `backend/.env`.
2. Actualiza la variable `AI_SERVICE_URL`:
   ```ini
   AI_SERVICE_URL=https://<POD_ID>-8000.proxy.runpod.net
   AI_SERVICE_INTERNAL_KEY=tu_clave_secreta_compartida
   ```
3. Reinicia tu backend (`pm2 restart biomark-backend` o `npm start`).

---

## 5. Verificación de Funcionamiento

Desde tu terminal o Postman, puedes probar la salud del servicio:
```bash
curl -i https://<POD_ID>-8000.proxy.runpod.net/health
```
Respuesta esperada:
```json
{"status": "ok", "service": "biomark-ai-service"}
```

Para probar una consulta con contexto clínico:
```bash
curl -X POST https://<POD_ID>-8000.proxy.runpod.net/chat \
  -H "Content-Type: application/json" \
  -H "X-AI-Internal-Key: tu_clave_secreta_compartida" \
  -d '{
    "message": "¿Qué es el sarampión?",
    "medical_context": {
      "perfil": {"sexo": "F", "fecha_nacimiento": "1995-04-10"}
    }
  }'
```
El servicio responderá con la explicación médica preventiva completa, sin prescripciones de medicamentos ni alucinaciones de diagnóstico concluyente.
