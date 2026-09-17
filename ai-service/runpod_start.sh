#!/usr/bin/env bash
# ==============================================================================
# Script de inicio para Biomark AI en RunPod (Pod GPU)
# Uso: bash runpod_start.sh
# ==============================================================================
set -e

echo "=================================================="
echo "   Iniciando Biomark AI (ai-service) en RunPod    "
echo "=================================================="

# 1. Comprobar aceleración GPU
if command -v nvidia-smi &> /dev/null; then
    echo "[GPU] Dispositivos NVIDIA disponibles:"
    nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader
else
    echo "[AVISO] No se detectó GPU NVIDIA disponible. Se ejecutará en CPU."
fi

# 2. Instalar paquetes de sistema para audio (ffmpeg, libsndfile1) si se corre en template base
if command -v apt-get &> /dev/null; then
    apt-get update -qq && apt-get install -y -qq ffmpeg libsndfile1 > /dev/null 2>&1 || true
fi

# 3. Preparar archivo .env
if [ ! -f ".env" ]; then
    if [ -f ".env.example" ]; then
        echo "[CONFIG] No existe .env. Copiando desde .env.example..."
        cp .env.example .env
        echo "[AVISO] Asegúrate de que .env tenga configuradas tus claves reales."
    fi
fi

# 4. Instalar o actualizar dependencias de Python
echo "[DEP] Verificando dependencias en requirements.txt..."
pip install -q --no-cache-dir -r requirements.txt

# 5. Iniciar servidor FastAPI
PORT="${PORT:-8000}"
echo "[INICIO] Arrancando FastAPI en 0.0.0.0:${PORT}..."
exec uvicorn main:app --host 0.0.0.0 --port "$PORT"
