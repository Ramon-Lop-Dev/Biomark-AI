# Dockerfile optimizado para correr Biomark AI (ai-service) en RunPod GPU o servidores con aceleración CUDA.
FROM python:3.11-slim

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PORT=8000

# Herramientas del sistema necesarias para ASR/TTS (ffmpeg, libsndfile) y compilación
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ffmpeg \
    libsndfile1 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar PyTorch con aceleración CUDA 12.1
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Instalar dependencias del proyecto
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el código fuente completo
COPY . .

# Exponer el puerto HTTP del servicio
EXPOSE 8000

# Arrancar uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
