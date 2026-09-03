# DuckDNS y servicios en Contabo

## Arquitectura

Contabo aloja todos los servicios web y de negocio:

```text
biomark-api.duckdns.org  -> nginx -> backend Express:3000
biomark-n8n.duckdns.org  -> nginx -> n8n:5678
backend Express           -> HTTPS -> ai-service en RunPod
backend y ai-service      -> Supabase
```

RunPod no aloja backend, Express, nginx ni n8n. Solo ejecuta `ai-service` en el puerto 8000.

DuckDNS no sustituye el servidor: únicamente proporciona nombres DNS gratuitos. Los nombres del ejemplo son referencias; puedes elegir otros nombres disponibles en tu cuenta.

## 1. Crear los nombres en DuckDNS

1. Entra en `https://www.duckdns.org`.
2. Inicia sesión.
3. Crea dos dominios disponibles, por ejemplo:
   - `biomark-api.duckdns.org`
   - `biomark-n8n.duckdns.org`
4. En ambos dominios registra la IP pública de Contabo.
5. Conserva el token de DuckDNS fuera del repositorio.

DuckDNS normalmente se usa creando dos hostnames bajo `duckdns.org`; no dependas de un registro arbitrario como `n8n.biomark.duckdns.org` salvo que DuckDNS lo permita expresamente en tu cuenta.

Verifica desde cualquier máquina:

```bash
dig +short biomark-api.duckdns.org
dig +short biomark-n8n.duckdns.org
```

Ambos deben devolver la IP pública de Contabo.

## 2. Actualización de IP

Contabo normalmente tiene una IP pública fija, por lo que basta con actualizar DuckDNS al crear el dominio. Si la IP cambia, actualiza ambos hostnames desde una máquina segura:

```bash
curl "https://www.duckdns.org/update?domains=biomark-api&token=TU_TOKEN_DUCKDNS&ip="
curl "https://www.duckdns.org/update?domains=biomark-n8n&token=TU_TOKEN_DUCKDNS&ip="
```

No guardes estos comandos con el token en Git. Si necesitas automatizarlos, usa un archivo protegido con permisos `600` y un timer de systemd.

## 3. Variables de Contabo

En `/opt/biomark-ai/deploy/backend.env`:

```env
NODE_ENV=production
PORT=3000
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_SERVICE_ROLE_KEY=TU_SERVICE_ROLE_KEY
SUPABASE_ANON_KEY=TU_ANON_KEY
AI_SERVICE_URL=https://POD_ID-8000.proxy.runpod.net
AI_SERVICE_INTERNAL_KEY=LA_MISMA_CLAVE_CONFIGURADA_EN_RUNPOD
CORS_ORIGINS=https://biomark-api.duckdns.org
N8N_WEBHOOK_URL=http://n8n:5678/webhook/biomark-events
N8N_WEBHOOK_SECRET=TU_SECRETO_DE_N8N
```

En `/opt/biomark-ai/deploy/.env`:

```env
N8N_HOST=biomark-n8n.duckdns.org
N8N_PROTOCOL=https
WEBHOOK_URL=https://biomark-n8n.duckdns.org/
N8N_EDITOR_BASE_URL=https://biomark-n8n.duckdns.org/
N8N_SECURE_COOKIE=true
N8N_ENCRYPTION_KEY=UNA_CLAVE_LARGA_Y_PERMANENTE
GENERIC_TIMEZONE=America/Managua
TZ=America/Managua
```

`N8N_WEBHOOK_URL` del backend es interno porque backend y n8n comparten la red Docker. `WEBHOOK_URL` de n8n es público porque n8n necesita generar URLs externas correctas.

## 4. Firewall de Contabo

```bash
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw deny 3000/tcp
ufw deny 5678/tcp
ufw enable
ufw status verbose
```

Nunca publiques directamente los puertos 3000 o 5678. nginx será el único servicio expuesto.

## 5. nginx

La configuración actual enruta `/api/` al backend y `/n8n/` a n8n. Para usar hostnames separados, configura nginx con estos nombres reales:

```nginx
server_name biomark-api.duckdns.org;
```

Para el segundo bloque:

```nginx
server_name biomark-n8n.duckdns.org;
location / {
    proxy_pass http://n8n:5678;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
}
```

En el bloque de la API conserva:

```nginx
location /api/ {
    proxy_pass http://backend:3000;
    proxy_read_timeout 240s;
    proxy_send_timeout 240s;
}
```

No uses el hostname de n8n para la API ni el hostname de la API para enviar secretos de n8n.

## 6. HTTPS con Let's Encrypt

Después de que los dos nombres resuelvan a Contabo y el puerto 80 sea accesible:

```bash
apt update
apt install -y certbot
systemctl stop nginx
certbot certonly --standalone \
  -d biomark-api.duckdns.org \
  -d biomark-n8n.duckdns.org
systemctl start nginx
```

Como nginx corre en Docker, los certificados quedarán en `/etc/letsencrypt`. Monta los certificados en el contenedor o cópialos a `nginx/certs/` con permisos restringidos. Luego configura nginx para escuchar `443 ssl` con:

```nginx
ssl_certificate /etc/nginx/certs/fullchain.pem;
ssl_certificate_key /etc/nginx/certs/privkey.pem;
```

Renueva antes del vencimiento:

```bash
certbot renew --dry-run
```

Después de renovar, reinicia nginx:

```bash
docker compose --env-file deploy/.env -f docker-compose.contabo.yml restart nginx
```

## 7. Levantar Contabo

Desde `/opt/biomark-ai`:

```bash
docker compose --env-file deploy/.env -f docker-compose.contabo.yml config
docker compose --env-file deploy/.env -f docker-compose.contabo.yml build backend
docker compose --env-file deploy/.env -f docker-compose.contabo.yml up -d backend n8n nginx
docker compose --env-file deploy/.env -f docker-compose.contabo.yml ps
```

No ejecutes el Compose principal en Contabo porque también define un AI Service local.

## 8. Verificación

```bash
curl -I https://biomark-api.duckdns.org/health
curl -I https://biomark-n8n.duckdns.org/
curl -fsS https://POD_ID-8000.proxy.runpod.net/health
```

Desde Contabo valida el AI Service con la clave interna:

```bash
read -rsp 'AI_SERVICE_INTERNAL_KEY: ' AI_KEY; echo
curl -fsS \
  -H "X-Internal-Key: $AI_KEY" \
  -H 'Content-Type: application/json' \
  -d '{"message":"emergencia pediátrica","latitude":12.12,"longitude":-86.25}' \
  https://POD_ID-8000.proxy.runpod.net/chat
unset AI_KEY
```

Finalmente prueba desde Flutter usando:

```text
https://biomark-api.duckdns.org
```

Flutter nunca debe usar la URL de RunPod ni la URL de n8n.
