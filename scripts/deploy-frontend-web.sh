#!/usr/bin/env bash
# Compila el frontend web y lo sube al VPS en un solo paso.
# Uso: ./scripts/deploy-frontend-web.sh
set -euo pipefail

VPS_HOST="biomark@84.247.164.97"
VPS_PATH="/opt/biomark-ai/frontend-web"

BIOMARK_API_URL="https://biomark-api.duckdns.org"
GOOGLE_WEB_CLIENT_ID="780734083560-ab3t99hnitsm0l98mbhgpi23orqu8d1j.apps.googleusercontent.com"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/../frontend/flutter"

echo "==> Compilando Flutter web..."
flutter build web \
  --dart-define=BIOMARK_API_URL="$BIOMARK_API_URL" \
  --dart-define=GOOGLE_WEB_CLIENT_ID="$GOOGLE_WEB_CLIENT_ID"

echo "==> Subiendo build/web al VPS..."
rsync -avz --delete build/web/ "$VPS_HOST:$VPS_PATH/"

echo "==> Listo: https://biomark-api.duckdns.org"
