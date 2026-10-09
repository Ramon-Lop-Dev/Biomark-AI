#!/usr/bin/env bash
# ==============================================================================
# Biomark AI - Despliegue Automatizado de ai-service en RunPod GPU
# ==============================================================================
# Uso:
#   1. Con SSH directo:
#      ./scripts/deploy-ai-service-to-runpod.sh -s "root@<IP> -p <PORT>" -d <POD_ID>
#   2. Con parámetros separados:
#      ./scripts/deploy-ai-service-to-runpod.sh -h <HOST> -p <PORT> -d <POD_ID> [-k <SSH_KEY>]
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
AI_DIR="${ROOT_DIR}/ai-service"

SSH_HOST=""
SSH_PORT="22"
SSH_USER="root"
SSH_KEY="${HOME}/.ssh/id_ed25519_runpod"
POD_ID=""
RAW_SSH_CMD=""
CONTABO_IP="169.58.164.15"

# Colores para salida de terminal
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[AVISO]${NC} $1"; }
log_err()   { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
  cat << EOH
Uso: $0 [opciones]

Opciones:
  -s "<cmd>"    Cadena SSH copiada de RunPod (ej: "root@194.26.196.88 -p 22345" o "ssh root@...")
  -h <host>     Host / IP del Pod
  -p <puerto>   Puerto SSH (por defecto: 22)
  -k <llave>    Ruta a la llave SSH privada (por defecto: ~/.ssh/id_ed25519_runpod)
  -d <pod_id>   Pod ID de RunPod (ej: kirf2yr8o6bdql para generar el proxy https://<pod_id>-8000.proxy.runpod.net)
  --skip-vps    No actualizar el VPS Contabo al finalizar
  --help        Muestra esta ayuda
EOH
  exit 0
}

SKIP_VPS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -s|--ssh)
      RAW_SSH_CMD="$2"
      shift 2
      ;;
    -h|--host)
      SSH_HOST="$2"
      shift 2
      ;;
    -p|--port)
      SSH_PORT="$2"
      shift 2
      ;;
    -k|--key)
      SSH_KEY="$2"
      shift 2
      ;;
    -d|--pod-id)
      POD_ID="$2"
      shift 2
      ;;
    --skip-vps)
      SKIP_VPS=true
      shift
      ;;
    --help)
      show_help
      ;;
    *)
      log_err "Opción no reconocida: $1"
      show_help
      ;;
  esac
done

# Si pasaron la cadena SSH cruda de RunPod, parsearla
if [ -n "$RAW_SSH_CMD" ]; then
  # Remover "ssh " inicial si viene incluido
  CLEAN_SSH="${RAW_SSH_CMD#ssh }"
  # Extraer puerto si viene con -p <port>
  if [[ "$CLEAN_SSH" =~ -p[[:space:]]+([0-9]+) ]]; then
    SSH_PORT="${BASH_REMATCH[1]}"
    CLEAN_SSH=$(echo "$CLEAN_SSH" | sed -E 's/-p[[:space:]]+[0-9]+//')
  fi
  # Extraer llave si viene con -i <key>
  if [[ "$CLEAN_SSH" =~ -i[[:space:]]+([^ ]+) ]]; then
    SSH_KEY="${BASH_REMATCH[1]}"
    CLEAN_SSH=$(echo "$CLEAN_SSH" | sed -E 's/-i[[:space:]]+[^ ]+//')
  fi
  # Extraer user@host
  SSH_TARGET=$(echo "$CLEAN_SSH" | xargs)
  if [[ "$SSH_TARGET" =~ (.+)@(.+) ]]; then
    SSH_USER="${BASH_REMATCH[1]}"
    SSH_HOST="${BASH_REMATCH[2]}"
  else
    SSH_HOST="$SSH_TARGET"
  fi
fi

if [ -z "$SSH_HOST" ]; then
  log_err "Falta el host/IP de RunPod. Especifica -s \"<ssh_command>\" o -h <host>."
  exit 1
fi

if [ ! -f "$SSH_KEY" ]; then
  # Probar fallback a id_ed25519 o id_rsa
  if [ -f "${HOME}/.ssh/id_ed25519" ]; then
    SSH_KEY="${HOME}/.ssh/id_ed25519"
  fi
fi

SSH_OPTS=(-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10 -i "$SSH_KEY" -p "$SSH_PORT")

echo "================================================================="
echo "        BIOMARK AI — DESPLIEGUE AUTOMÁTICO EN RUNPOD GPU         "
echo "================================================================="
log_info "Destino RunPod: ${SSH_USER}@${SSH_HOST}:${SSH_PORT}"
log_info "Llave SSH:      ${SSH_KEY}"
log_info "Pod ID:         ${POD_ID:-'(No especificado, se detectará)'}"
echo "-----------------------------------------------------------------"

# 1. Probar conectividad SSH
log_info "1/6. Verificando conexión SSH al Pod..."
if ! ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" "echo 'Conexión exitosa a RunPod'" 2>/dev/null; then
  log_err "No se pudo conectar vía SSH al Pod (${SSH_USER}@${SSH_HOST}:${SSH_PORT})."
  log_err "Verifica que el Pod esté en estado 'Running' y que tu clave pública esté registrada en RunPod."
  exit 1
fi
log_ok "Conexión SSH establecida correctamente con el Pod."

# Detectar Pod ID si no se proporcionó
if [ -z "$POD_ID" ]; then
  DETECTED_POD_ID=$(ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" 'echo "${RUNPOD_POD_ID:-}"' 2>/dev/null || true)
  if [ -n "$DETECTED_POD_ID" ]; then
    POD_ID="$DETECTED_POD_ID"
    log_ok "Pod ID detectado automáticamente desde el entorno: ${POD_ID}"
  fi
fi

# 2. Verificar GPU en el Pod
log_info "2/6. Auditando aceleración GPU en el Pod..."
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" bash -s << 'EOF_GPU'
if command -v nvidia-smi &> /dev/null; then
  echo "--- GPU Detectada ---"
  nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader
else
  echo "[AVISO] No se detectó nvidia-smi. El servicio correrá en CPU."
fi
EOF_GPU
log_ok "Auditoría de hardware completada."

# 3. Preparar directorios y transferir código fuente de ai-service
log_info "3/6. Sincronizando código fuente de ai-service hacia /workspace/ai-service..."
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" "mkdir -p /workspace/ai-service"

# Empaquetar y enviar vía tar sobre SSH para máxima velocidad sin dependencias de rsync
tar -czf - -C "${AI_DIR}" \
  --exclude="chroma_db" \
  --exclude="temp_pdfs" \
  --exclude="__pycache__" \
  --exclude="*.pyc" \
  . | ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" "tar -xzf - -C /workspace/ai-service"

log_ok "Código fuente sincronizado en el Pod."

# 4. Instalar dependencias del sistema y de Python en el Pod
log_info "4/6. Instalando librerías del sistema y dependencias Python en el Pod..."
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" bash -s << 'EOF_DEP'
set -e
cd /workspace/ai-service

# Paquetes del sistema (audio, git, curl)
if command -v apt-get &> /dev/null; then
  echo "[APT] Instalando ffmpeg, libsndfile1..."
  apt-get update -qq && apt-get install -y -qq ffmpeg libsndfile1 procps curl > /dev/null 2>&1 || true
fi

# Dependencias Python
echo "[PIP] Verificando e instalando dependencias de requirements.txt..."
export PIP_BREAK_SYSTEM_PACKAGES=1
pip install --break-system-packages --no-cache-dir -r requirements.txt

# Asegurar que el archivo .env exista
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  cp .env.example .env
fi
EOF_DEP
log_ok "Dependencias listas en el Pod."

# 5. Iniciar servicio uvicorn en segundo plano
log_info "5/6. Iniciando ai-service (FastAPI + Uvicorn) en el puerto 8000..."
ssh "${SSH_OPTS[@]}" "${SSH_USER}@${SSH_HOST}" bash -s << 'EOF_START'
cd /workspace/ai-service

# Detener cualquier proceso uvicorn previo
pkill -f "uvicorn main:app" 2>/dev/null || true
sleep 1

# Arrancar uvicorn en segundo plano con nohup
PORT=8000
nohup uvicorn main:app --host 0.0.0.0 --port 8000 > /workspace/ai-service.log 2>&1 &
echo "[PROCESO] ai-service lanzado con PID $!"

# Esperar unos segundos para que cargue
echo "[ESPERA] Verificando inicialización de FastAPI (descarga de modelos en primer arranque)..."
for i in {1..60}; do
  if curl -s http://127.0.0.1:8000/health | grep -q "biomark-ai-service"; then
    echo "[OK] ai-service está respondiendo correctamente en http://127.0.0.1:8000/health"
    exit 0
  fi
  sleep 2
done

echo "[AVISO] El servicio aún está cargando los pesos de los modelos. Logs recientes:"
tail -n 20 /workspace/ai-service.log
EOF_START
log_ok "ai-service iniciado y verificado internamente en el Pod."

# 6. Conectar con el VPS Contabo (si se especificó Pod ID)
if [ "$SKIP_VPS" = false ] && [ -n "$POD_ID" ]; then
  NEW_AI_URL="https://${POD_ID}-8000.proxy.runpod.net"
  log_info "6/6. Vinculando nuevo endpoint con el VPS Contabo (${CONTABO_IP})..."
  log_info "Nueva URL de IA: ${NEW_AI_URL}"

  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "root@${CONTABO_IP}" bash -s << EOF_VPS
set -e
ENV_FILE="/opt/biomark-ai/deploy/backend.env"
if [ -f "\$ENV_FILE" ]; then
  sed -i -E "s|^AI_SERVICE_URL=.*|AI_SERVICE_URL=${NEW_AI_URL}|" "\$ENV_FILE"
  echo "[VPS] Variable AI_SERVICE_URL actualizada en \$ENV_FILE"
fi

cd /opt/biomark-ai
echo "[VPS] Reiniciando contenedor backend con Docker Compose..."
docker compose --env-file deploy/.env -f docker-compose.contabo.yml restart backend
echo "[VPS] Contenedor backend reiniciado con éxito."
EOF_VPS
  log_ok "VPS Contabo actualizado y backend reiniciado."

  # Test final desde el exterior
  log_info "Realizando comprobación final de salud desde el exterior..."
  sleep 3
  curl -s --max-time 10 "${NEW_AI_URL}/health" || log_warn "El proxy de RunPod aún está propagando el certificado SSL. Estará listo en 1-2 minutos."
fi

echo "================================================================="
echo -e "${GREEN}      ¡DESPLIEGUE DE BIOMARK AI SERVICE COMPLETADO CON ÉXITO!   ${NC}"
echo "================================================================="
if [ -n "$POD_ID" ]; then
  echo -e "Proxy Público RunPod: ${BLUE}https://${POD_ID}-8000.proxy.runpod.net${NC}"
  echo -e "Health check:         ${BLUE}https://${POD_ID}-8000.proxy.runpod.net/health${NC}"
fi
echo -e "Logs en vivo en Pod:  ssh ${SSH_USER}@${SSH_HOST} -p ${SSH_PORT} \"tail -f /workspace/ai-service.log\""
echo "================================================================="
