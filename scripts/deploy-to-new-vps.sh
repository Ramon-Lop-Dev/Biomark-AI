#!/usr/bin/env bash
# ==============================================================================
# Biomark AI - Despliegue Completo Automatizado hacia el Nuevo VPS de Contabo
# ==============================================================================
# Uso:
#   ./scripts/deploy-to-new-vps.sh root@IP_DE_CONTABO
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ $# -lt 1 ]]; then
  echo -e "${RED}Error: Debes especificar el host remoto SSH.${NC}"
  echo "Ejemplo: ./scripts/deploy-to-new-vps.sh root@161.97.xxx.xxx"
  exit 1
fi

REMOTE_TARGET="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${GREEN}======================================================"
echo -e "   Desplegando Biomark AI hacia: $REMOTE_TARGET"
echo -e "======================================================${NC}"

# Paso 1: Generar variables de entorno de producción localmente
echo -e "${BLUE}==> [Paso 1/4] Generando variables de entorno seguras...${NC}"
"$SCRIPT_DIR/generate-production-envs.sh"

# Paso 2: Subir script de setup y variables de entorno al VPS
echo -e "${BLUE}==> [Paso 2/4] Transfiriendo configuraciones iniciales al VPS...${NC}"
ssh -o StrictHostKeyChecking=accept-new "$REMOTE_TARGET" "mkdir -p /opt/biomark-ai/deploy /opt/biomark-ai/scripts"
scp "$ROOT_DIR/deploy/backend.env" "$ROOT_DIR/deploy/.env" "$REMOTE_TARGET:/opt/biomark-ai/deploy/"
scp "$SCRIPT_DIR/setup-contabo-vps.sh" "$REMOTE_TARGET:/opt/biomark-ai/scripts/"

# Paso 3: Ejecutar aprovisionamiento en el VPS
echo -e "${BLUE}==> [Paso 3/4] Ejecutando aprovisionamiento en el servidor remoto...${NC}"
ssh "$REMOTE_TARGET" "bash /opt/biomark-ai/scripts/setup-contabo-vps.sh"

# Paso 4: Compilar y desplegar Flutter Web
echo -e "${BLUE}==> [Paso 4/4] Compilando y desplegando Frontend Web de Flutter...${NC}"
BIOMARK_VPS_HOST="$REMOTE_TARGET" "$SCRIPT_DIR/deploy-frontend-web.sh"

echo -e "\n${GREEN}======================================================"
echo -e "   ¡Despliegue hacia $REMOTE_TARGET Finalizado con Éxito!"
echo -e "======================================================${NC}"
