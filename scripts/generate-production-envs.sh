#!/usr/bin/env bash
# Genera los archivos deploy/backend.env y deploy/.env listos para subir al VPS de Contabo.
# Extrae credenciales reales desde backend/.env y genera claves criptográficas para n8n.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKEND_ENV="$ROOT_DIR/backend/.env"
TARGET_DEPLOY_DIR="$ROOT_DIR/deploy"

if [[ ! -f "$BACKEND_ENV" ]]; then
  echo "Error: No se encontró $BACKEND_ENV" >&2
  exit 1
fi

echo "==> Leyendo credenciales desde backend/.env..."

get_env_val() {
  local key="$1"
  grep -E "^${key}=" "$BACKEND_ENV" | head -n 1 | cut -d '=' -f 2- | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

SUPABASE_URL="$(get_env_val SUPABASE_URL)"
SUPABASE_ANON_KEY="$(get_env_val SUPABASE_ANON_KEY)"
SUPABASE_SERVICE_ROLE_KEY="$(get_env_val SUPABASE_SERVICE_ROLE_KEY)"
AI_SERVICE_URL="$(get_env_val AI_SERVICE_URL)"
AI_SERVICE_INTERNAL_KEY="$(get_env_val AI_SERVICE_INTERNAL_KEY)"
FIREBASE_PROJECT_ID="$(get_env_val FIREBASE_PROJECT_ID)"
FIREBASE_CLIENT_EMAIL="$(get_env_val FIREBASE_CLIENT_EMAIL)"
FIREBASE_PRIVATE_KEY="$(get_env_val FIREBASE_PRIVATE_KEY)"

# Generar secretos criptográficos seguros para n8n
N8N_ENCRYPTION_KEY="$(openssl rand -hex 32)"
N8N_WEBHOOK_SECRET="$(openssl rand -hex 24)"

mkdir -p "$TARGET_DEPLOY_DIR"

echo "==> Generando $TARGET_DEPLOY_DIR/backend.env..."
cat <<EOF > "$TARGET_DEPLOY_DIR/backend.env"
NODE_ENV=production
PORT=3000
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}
SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}
AI_SERVICE_URL=${AI_SERVICE_URL:-https://kirf2yr8o6bdql-8000.proxy.runpod.net}
AI_SERVICE_INTERNAL_KEY=${AI_SERVICE_INTERNAL_KEY}
CORS_ORIGINS=https://biomark-api.duckdns.org
N8N_WEBHOOK_URL=http://n8n:5678/webhook/eventos-backend
N8N_WEBHOOK_SECRET=${N8N_WEBHOOK_SECRET}
FIREBASE_PROJECT_ID=${FIREBASE_PROJECT_ID}
FIREBASE_CLIENT_EMAIL=${FIREBASE_CLIENT_EMAIL}
FIREBASE_PRIVATE_KEY=${FIREBASE_PRIVATE_KEY}
EOF

chmod 600 "$TARGET_DEPLOY_DIR/backend.env"

echo "==> Generando $TARGET_DEPLOY_DIR/.env..."
cat <<EOF > "$TARGET_DEPLOY_DIR/.env"
N8N_HOST=biomark-n8n.duckdns.org
N8N_PROTOCOL=https
WEBHOOK_URL=https://biomark-n8n.duckdns.org/
N8N_EDITOR_BASE_URL=https://biomark-n8n.duckdns.org/
N8N_SECURE_COOKIE=true
N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
N8N_WEBHOOK_SECRET=${N8N_WEBHOOK_SECRET}
GENERIC_TIMEZONE=America/Managua
TZ=America/Managua
SUPABASE_URL=${SUPABASE_URL}
SUPABASE_SERVICE_ROLE_KEY=${SUPABASE_SERVICE_ROLE_KEY}
FCM_PROJECT_ID=${FIREBASE_PROJECT_ID}
BACKEND_INTERNAL_URL=http://backend:3000
EOF

chmod 600 "$TARGET_DEPLOY_DIR/.env"

echo "==> ¡Archivos generados exitosamente en deploy/!"
echo "    - $TARGET_DEPLOY_DIR/backend.env (Permisos 600)"
echo "    - $TARGET_DEPLOY_DIR/.env (Permisos 600)"
