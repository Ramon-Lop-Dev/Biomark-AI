#!/usr/bin/env bash
# Compila el frontend web y lo sube al VPS en un solo paso.
# Uso: ./scripts/deploy-frontend-web.sh
set -euo pipefail

VPS_HOST="biomark@84.247.164.97"
VPS_PATH="/opt/biomark-ai/frontend-web"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../frontend/flutter"

if [[ ! -f .env ]]; then
  echo "Falta frontend/flutter/.env. Copia .env.example y completa Firebase Web." >&2
  exit 1
fi

set -a
source .env
set +a

BIOMARK_API_URL="${BIOMARK_API_URL:-https://biomark-api.duckdns.org}"
GOOGLE_WEB_CLIENT_ID="${GOOGLE_WEB_CLIENT_ID:-}"

echo "==> Compilando Flutter web..."
flutter build web \
  --dart-define=BIOMARK_API_URL="$BIOMARK_API_URL" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID"

echo "==> Subiendo build/web al VPS..."
rsync -avz --delete build/web/ "$VPS_HOST:$VPS_PATH/"

echo "==> Listo: https://biomark-api.duckdns.org"
