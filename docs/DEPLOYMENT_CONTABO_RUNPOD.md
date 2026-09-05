# Despliegue distribuido: Contabo + RunPod

Esta es la topología de producción recomendada:

```text
Flutter --HTTPS--> nginx (Contabo) --> backend (Contabo) --HTTPS--> ai-service (RunPod)
                                      |
                                      +--> n8n (Contabo)
                                      +--> Supabase
```

Contabo ejecuta `backend`, `nginx` y `n8n`. RunPod ejecuta únicamente `ai-service`. Supabase es compartido por backend y AI Service.

## Requisitos

- Docker Engine y Docker Compose v2 en Contabo.
- Un Pod con GPU y almacenamiento persistente en RunPod. El AI Service se ejecuta directamente con Python/Uvicorn; no se usa Docker en RunPod en el flujo operativo actual.
- Repositorio accesible desde ambos servidores.
- Dominio HTTPS para nginx en Contabo.
- Proyecto Supabase configurado con RLS, Storage y migraciones.
- Una clave aleatoria compartida únicamente entre backend y AI Service.

## 1. Supabase

Ejecuta una sola vez en el SQL Editor, en este orden:

```text
database/migrations/005_centros_salud_recomendador.sql
database/seeds/seed_centros_salud_managua.sql
```

El seed se ejecuta una sola vez por entorno. Confirma los centros críticos:

```sql
SELECT nombre, tipo, tipo_unidad, especialidades
FROM public.centros_salud
WHERE nombre ILIKE '%Mascota%'
   OR nombre ILIKE '%Bertha Calderón%';
```

## 2. Generar secretos

En una máquina segura, genera dos secretos diferentes:

```bash
openssl rand -hex 32  # AI_SERVICE_INTERNAL_KEY
openssl rand -hex 32  # N8N_WEBHOOK_SECRET
```

`AI_SERVICE_INTERNAL_KEY` debe ser idéntica en RunPod y Contabo. No la guardes en Git ni la pongas en Flutter.

## 3. Preparar RunPod

1. Crea un GPU Pod con almacenamiento persistente.
2. Expón el puerto HTTP `8000`.
3. Conéctate por SSH o por la terminal del Pod.
4. Clona el repositorio en un volumen persistente:

```bash
cd /workspace
git clone URL_DEL_REPOSITORIO biomark-ai
cd biomark-ai
```

Crea las variables fuera del repositorio:

```bash
nano /workspace/ai-service.env
```

```env
AI_SERVICE_INTERNAL_KEY=LA_CLAVE_COMPARTIDA
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_SERVICE_ROLE_KEY=TU_SERVICE_ROLE_KEY
PORT=8000
MODEL_ID=BiomarkAI/Biomark-AI-Produccion
SUPABASE_BUCKET_MINSA=documentos-minsa
UMBRAL_RELEVANCIA=0.75
```

Este Pod ejecuta el AI Service directamente con Python. El entorno virtual se instala una sola vez:

```bash
cd /workspace/biomark-ai
python3 -m venv --system-site-packages /workspace/biomark-venv
source /workspace/biomark-venv/bin/activate
pip install -r ai-service/requirements.txt
mkdir -p /workspace/.cache/huggingface /workspace/chroma-db
python -m py_compile ai-service/main.py ai-service/inference/service.py
```

Configura `/workspace/ai-service.env` con `AI_SERVICE_INTERNAL_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `PORT=8000`, `MODEL_ID`, `SUPABASE_BUCKET_MINSA` y `UMBRAL_RELEVANCIA`.

Inicia Uvicorn dentro de `tmux` para que sobreviva al cierre de la terminal:

```bash
apt-get update && apt-get install -y tmux
```

Ya dentro de la sesión `tmux`, ejecuta:

```bash
source /workspace/biomark-venv/bin/activate
set -a; source /workspace/ai-service.env; set +a
export PYTHONPATH=/workspace/biomark-ai/ai-service
uvicorn main:app --app-dir /workspace/biomark-ai/ai-service --host 0.0.0.0 --port 8000
```

Para crear la sesión antes de ejecutar esos comandos, usa:

```bash
tmux new -s biomark-ai
```

Para salir sin detener el servicio, pulsa `Ctrl+B` y después `D`. Verifica desde otra terminal:

```bash
curl -fsS http://127.0.0.1:8000/health
```

En RunPod copia la URL HTTPS exacta que aparece en `Connect` para el puerto `8000`; normalmente se parece a `https://POD_ID-8000.proxy.runpod.net`. No inventes la URL.

## 4. Preparar Contabo

Conéctate al VPS y prepara el sistema:

```bash
ssh root@IP_DE_CONTABO
apt update
apt install -y ca-certificates curl git openssl
```

Instala Docker Engine siguiendo la documentación oficial de Ubuntu/Debian y verifica:

```bash
docker --version
docker compose version
```

Clona el proyecto:

```bash
git clone URL_DEL_REPOSITORIO /opt/biomark-ai
cd /opt/biomark-ai
```

Configura el backend:

```bash
cp deploy/backend.env.example deploy/backend.env
cp deploy/.env.example deploy/.env
nano deploy/backend.env
nano deploy/.env
```

En `deploy/backend.env` usa:

```env
NODE_ENV=production
PORT=3000
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_SERVICE_ROLE_KEY=TU_SERVICE_ROLE_KEY
SUPABASE_ANON_KEY=TU_ANON_KEY
AI_SERVICE_URL=https://POD_ID-8000.proxy.runpod.net
AI_SERVICE_INTERNAL_KEY=LA_MISMA_CLAVE_DE_RUNPOD
CORS_ORIGINS=https://TU_DOMINIO_PUBLICO
N8N_WEBHOOK_URL=http://n8n:5678/webhook/biomark-events
N8N_WEBHOOK_SECRET=EL_SECRETO_DE_N8N
```

En `deploy/.env` configura n8n. Para una primera prueba local detrás de nginx:

```env
N8N_HOST=biomark-n8n.duckdns.org
N8N_PROTOCOL=http
WEBHOOK_URL=http://biomark-n8n.duckdns.org/
N8N_EDITOR_BASE_URL=http://biomark-n8n.duckdns.org/
N8N_SECURE_COOKIE=false
N8N_ENCRYPTION_KEY=UNA_CLAVE_LARGA_Y_PERMANENTE
GENERIC_TIMEZONE=America/Managua
TZ=America/Managua
```

En producción cambia n8n a HTTPS después de instalar el certificado.

## 5. Arrancar únicamente Contabo

No uses el Compose principal, porque también define un AI Service local. Usa el Compose distribuido:

```bash
cd /opt/biomark-ai
docker compose --env-file deploy/.env -f docker-compose.contabo.yml config
docker compose --env-file deploy/.env -f docker-compose.contabo.yml build backend
docker compose --env-file deploy/.env -f docker-compose.contabo.yml up -d backend n8n nginx
docker compose --env-file deploy/.env -f docker-compose.contabo.yml ps
```

El Compose de Contabo no publica el puerto 3000 ni el 5678. nginx es el único punto de entrada público.

## 6. Firewall de Contabo

Permite únicamente SSH, HTTP y HTTPS:

```bash
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw deny 3000/tcp
ufw deny 5678/tcp
ufw enable
ufw status
```

El puerto 8000 se administra en RunPod. No pongas la clave interna en una URL.

## 7. HTTPS en nginx

La configuración base del repositorio escucha HTTP. Antes de producción debes instalar un certificado para el dominio de Contabo y configurar nginx para escuchar `443 ssl`. Flutter debe usar únicamente:

```text
https://TU_DOMINIO_PUBLICO/api
```

La URL del AI Service también debe ser HTTPS, normalmente mediante el proxy HTTPS de RunPod. No envíes JWT, datos médicos ni claves por HTTP público.

## 8. Verificación por capas

Desde RunPod:

```bash
curl -fsS http://127.0.0.1:8000/health
```

Desde Contabo, prueba la URL de RunPod:

```bash
curl -fsS https://POD_ID-8000.proxy.runpod.net/health
```

Prueba el contrato protegido del AI Service sin dejar la clave escrita en el historial:

```bash
read -rsp 'AI_SERVICE_INTERNAL_KEY: ' AI_KEY; echo
curl -fsS \
  -H "X-Internal-Key: $AI_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"message":"emergencia pediátrica","latitude":12.12,"longitude":-86.25}' \
  https://POD_ID-8000.proxy.runpod.net/chat
unset AI_KEY
```

Desde Contabo:

```bash
curl -fsS http://127.0.0.1/health
curl -fsS http://127.0.0.1/ready
```

Finalmente prueba `POST /api/chat` con un JWT real. Sin coordenadas, una consulta sintomática debe contener `ubicacion_requerida: true`; con ubicación autorizada debe contener `centro_sugerido`. Prueba estos casos:

```text
emergencia pediátrica
estoy embarazada y tengo sangrado
```

## 9. Operación y actualizaciones

Contabo:

```bash
cd /opt/biomark-ai
git pull
docker compose --env-file deploy/.env -f docker-compose.contabo.yml build backend
docker compose --env-file deploy/.env -f docker-compose.contabo.yml up -d backend nginx n8n
```

RunPod:

```bash
cd /workspace/biomark-ai
git pull --ff-only origin main
find ai-service -type d -name __pycache__ -prune -exec rm -rf {} +
source /workspace/biomark-venv/bin/activate
python3 -m py_compile ai-service/main.py ai-service/inference/service.py ai-service/safety/checker.py
set -a; source /workspace/ai-service.env; set +a
export PYTHONPATH=/workspace/biomark-ai/ai-service
tmux attach -t biomark-ai
```

Dentro de la sesión, detén Uvicorn con `Ctrl+C` y ejecuta:

```bash
source /workspace/biomark-venv/bin/activate
set -a; source /workspace/ai-service.env; set +a
export PYTHONPATH=/workspace/biomark-ai/ai-service
uvicorn main:app --app-dir /workspace/biomark-ai/ai-service --host 0.0.0.0 --port 8000
```

Si ya existe la sesión, usa `tmux attach -t biomark-ai` en vez de crear otra. Para pausar el gasto, pulsa `Ctrl+C`, sal de la terminal y detén el Pod desde RunPod. Conserva el almacenamiento persistente para no perder modelos, caché e índice RAG.
