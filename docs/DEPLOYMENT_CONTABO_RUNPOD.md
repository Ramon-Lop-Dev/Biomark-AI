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
- Un Pod con GPU y almacenamiento persistente en RunPod.
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

Construye y ejecuta el AI Service desde la raíz del repositorio. El contexto debe ser la raíz porque el Dockerfile copia `ai-service/`:

```bash
docker build -f Dockerfile.ai-service -t biomark-ai-service:latest .
mkdir -p /workspace/huggingface-cache /workspace/chroma-db
docker run -d \
  --name biomark-ai-service \
  --gpus all \
  --restart unless-stopped \
  --env-file /workspace/ai-service.env \
  -p 8000:8000 \
  -v /workspace/huggingface-cache:/root/.cache/huggingface \
  -v /workspace/chroma-db:/app/chroma_db \
  biomark-ai-service:latest
```

Comprueba el servicio dentro del Pod:

```bash
curl -fsS http://127.0.0.1:8000/health
docker logs --tail=200 biomark-ai-service
```

En RunPod copia la URL HTTPS exacta mostrada para el puerto 8000. Suele tener un formato parecido a:

```text
https://POD_ID-8000.proxy.runpod.net
```

No inventes la URL; usa la que muestre RunPod en `Connect`.

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
N8N_HOST=TU_DOMINIO_PUBLICO
N8N_PROTOCOL=http
WEBHOOK_URL=http://TU_DOMINIO_PUBLICO/n8n/
N8N_EDITOR_BASE_URL=http://TU_DOMINIO_PUBLICO/n8n/
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

Finalmente prueba `POST /api/chat` con un JWT real. Con ubicación autorizada, la respuesta debe contener `centro_sugerido`. Prueba estos casos:

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
git pull
docker build -f Dockerfile.ai-service -t biomark-ai-service:latest .
docker rm -f biomark-ai-service
docker run -d \
  --name biomark-ai-service \
  --gpus all \
  --restart unless-stopped \
  --env-file /workspace/ai-service.env \
  -p 8000:8000 \
  -v /workspace/huggingface-cache:/root/.cache/huggingface \
  -v /workspace/chroma-db:/app/chroma_db \
  biomark-ai-service:latest
```

Conserva el almacenamiento persistente de RunPod. Sin él, se volverían a descargar los modelos y el índice RAG.
