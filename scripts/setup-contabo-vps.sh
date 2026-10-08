#!/usr/bin/env bash
# ==============================================================================
# Biomark AI - Script de Aprovisionamiento Automatizado para VPS de Contabo
# ==============================================================================
# Este script prepara un VPS nuevo desde cero con:
# - Paquetes del sistema actualizados y herramientas esenciales
# - Docker Engine oficial y Docker Compose v2
# - Firewall UFW blindado (SSH, 80, 443; 3000 y 5678 bloqueados)
# - Repositorio clonado en /opt/biomark-ai
# - Certificados SSL (Bootstrap autofirmado -> Certbot Let's Encrypt)
# - Despliegue de backend, n8n y nginx
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }
log_err() { echo -e "${RED}[ERROR]${NC} $1" >&2; }

# 1. Verificar permisos de root
if [[ $EUID -ne 0 ]]; then
  log_err "Este script debe ejecutarse como root (o con sudo)."
  exit 1
fi

echo -e "${GREEN}======================================================"
echo -e "   Iniciando Aprovisionamiento de VPS Biomark AI"
echo -e "======================================================${NC}"

# 2. Actualizar repositorios y paquetes
log_info "Actualizando paquetes del sistema..."
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# 3. Instalar herramientas base
log_info "Instalando herramientas necesarias..."
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  git \
  ufw \
  certbot \
  rsync \
  openssl \
  jq

# 4. Instalar Docker Engine oficial si no está instalado
if ! command -v docker &> /dev/null; then
  log_info "Instalando Docker Engine oficial..."
  install -m 0755 -d /etc/apt/keyrings
  if [[ -f /etc/os-release ]] && grep -qi "debian" /etc/os-release; then
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  else
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  fi
  chmod a+r /etc/apt/keyrings/docker.asc
  apt-get update -y
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  systemctl enable --now docker
  log_success "Docker Engine instalado correctamente."
else
  log_success "Docker Engine ya se encuentra instalado."
fi

# 5. Configurar Firewall UFW
log_info "Configurando Firewall (UFW)..."
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH || ufw allow 22/tcp
ufw allow 80/tcp comment "HTTP Nginx"
ufw allow 443/tcp comment "HTTPS Nginx"
ufw deny 3000/tcp comment "Bloquear Express publico"
ufw deny 5678/tcp comment "Bloquear n8n publico"
ufw --force enable
log_success "Firewall UFW activado y protegido."

# 6. Preparar directorio /opt/biomark-ai
TARGET_DIR="/opt/biomark-ai"
log_info "Configurando directorio de aplicacion en $TARGET_DIR..."
mkdir -p "$TARGET_DIR"

if [[ ! -d "$TARGET_DIR/.git" ]]; then
  log_info "Clonando repositorio Biomark AI..."
  git clone https://github.com/Ramon-Lop-Dev/Biomark-AI.git "$TARGET_DIR"
else
  log_info "Actualizando repositorio existente con git pull..."
  git -C "$TARGET_DIR" fetch origin main
  git -C "$TARGET_DIR" checkout main
  git -C "$TARGET_DIR" pull origin main
fi

cd "$TARGET_DIR"
mkdir -p "$TARGET_DIR/frontend-web"
mkdir -p "$TARGET_DIR/nginx/certs"

# 7. Bootstrap de Certificados SSL
# Nginx no arrancará si faltan /etc/nginx/certs/fullchain.pem y privkey.pem.
# Creamos un certificado autofirmado inicial para que Nginx arranque de inmediato.
CERTS_DIR="$TARGET_DIR/nginx/certs"
if [[ ! -f "$CERTS_DIR/fullchain.pem" || ! -f "$CERTS_DIR/privkey.pem" ]]; then
  log_info "Generando certificados SSL bootstrap temporales..."
  openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout "$CERTS_DIR/privkey.pem" \
    -out "$CERTS_DIR/fullchain.pem" \
    -subj "/CN=biomark-api.duckdns.org/O=BiomarkAI/C=NI" > /dev/null 2>&1
  chmod 600 "$CERTS_DIR/privkey.pem"
  log_success "Certificados SSL bootstrap creados en $CERTS_DIR."
fi

# 8. Verificar archivos de entorno deploy/
if [[ ! -f "$TARGET_DIR/deploy/backend.env" || ! -f "$TARGET_DIR/deploy/.env" ]]; then
  log_warn "ATENCION: Faltan deploy/backend.env o deploy/.env."
  log_warn "Copia estos archivos desde tu máquina local mediante:"
  echo -e "${YELLOW}scp deploy/backend.env deploy/.env root@IP_DEL_VPS:$TARGET_DIR/deploy/${NC}"
  echo ""
  log_info "Creando archivos de ejemplo temporales para permitir comprobación de Compose..."
  [[ -f "$TARGET_DIR/deploy/backend.env" ]] || cp "$TARGET_DIR/deploy/backend.env.example" "$TARGET_DIR/deploy/backend.env"
  [[ -f "$TARGET_DIR/deploy/.env" ]] || cp "$TARGET_DIR/deploy/.env.example" "$TARGET_DIR/deploy/.env"
fi

# 9. Construir y levantar contenedores
log_info "Levantando servicios Docker (backend, n8n, nginx)..."
docker compose --env-file deploy/.env -f docker-compose.contabo.yml up -d --build backend n8n nginx

# 10. Comprobar estado de los servicios
log_info "Verificando contenedores activos..."
docker compose -f docker-compose.contabo.yml ps

echo -e "\n${GREEN}======================================================"
echo -e "   ¡Aprovisionamiento de Contabo Completado con Éxito!"
echo -e "======================================================${NC}"
echo -e "Pasos siguientes recomendados:"
echo -e "1. Asegúrate de que los archivos ${YELLOW}deploy/backend.env${NC} y ${YELLOW}deploy/.env${NC} tengan tus credenciales reales."
echo -e "2. Si ya apuntaste DuckDNS a la nueva IP del VPS, emite certificados reales de Let's Encrypt con:"
echo -e "   ${YELLOW}systemctl stop nginx 2>/dev/null || true${NC}"
echo -e "   ${YELLOW}docker stop biomark-ai-nginx-1 2>/dev/null || true${NC}"
echo -e "   ${YELLOW}certbot certonly --standalone -d biomark-api.duckdns.org -d biomark-n8n.duckdns.org${NC}"
echo -e "   ${YELLOW}cp /etc/letsencrypt/live/biomark-api.duckdns.org/fullchain.pem /opt/biomark-ai/nginx/certs/${NC}"
echo -e "   ${YELLOW}cp /etc/letsencrypt/live/biomark-api.duckdns.org/privkey.pem /opt/biomark-ai/nginx/certs/${NC}"
echo -e "   ${YELLOW}docker start biomark-ai-nginx-1${NC}"
echo -e "3. Sube el frontend web compilado desde tu máquina local ejecutando:"
echo -e "   ${YELLOW}./scripts/deploy-frontend-web.sh root@IP_DEL_VPS${NC}"
echo -e "4. Entra a ${BLUE}https://biomark-n8n.duckdns.org${NC}, crea tu usuario admin e importa ${YELLOW}n8n/workflows/n8n-eventos-backend.json${NC}."
