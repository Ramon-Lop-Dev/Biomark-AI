# Manual de instalación y despliegue

La arquitectura oficial de producción es distribuida. Para el procedimiento completo consulta [DEPLOYMENT_CONTABO_RUNPOD.md](DEPLOYMENT_CONTABO_RUNPOD.md). Este archivo resume la operación común de los servidores.

## Requisitos

- Ubuntu 22.04/24.04.
- Docker Engine y Docker Compose v2.
- DNS apuntando al VPS.
- Firewall con 80/443 abiertos y puertos 3000/8000/5678 cerrados.
- Supabase configurado con schema, RLS, Storage y proveedores Auth.
- VPS con memoria suficiente para los modelos AI; 8 GB es un mínimo práctico para comenzar y debe validarse con carga real.

## 1. Preparar Contabo

```bash
sudo apt update
sudo apt install -y ca-certificates curl git openssl
# Instalar Docker siguiendo la documentación oficial del sistema.
sudo systemctl enable --now docker
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

## 2. Descargar el proyecto en Contabo

```bash
git clone URL_DEL_REPOSITORIO biomark-ai
cd biomark-ai
```

No copiar `backend/.env` al VPS. Si alguna clave estuvo expuesta, rotarla antes.

## 3. Crear secretos y variables

```bash
mkdir -p deploy
cp deploy/backend.env.example deploy/backend.env
cp deploy/.env.example deploy/.env
openssl rand -hex 32
```

En Contabo se editan `deploy/backend.env` y `deploy/.env`. El archivo `deploy/ai-service.env` se configura únicamente en RunPod. `AI_SERVICE_INTERNAL_KEY` debe ser idéntica en backend y AI Service. `N8N_ENCRYPTION_KEY` debe conservarse para no perder credenciales de n8n.

Para la arquitectura distribuida, genera una clave interna adicional si no existe y conserva la misma copia para ambos servidores:

```bash
openssl rand -hex 32
```

## 4. Variables de producción mínimas

Backend: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AI_SERVICE_URL=https://POD_ID-8000.proxy.runpod.net`, `AI_SERVICE_INTERNAL_KEY`, `N8N_WEBHOOK_URL`, `N8N_WEBHOOK_SECRET`, `CORS_ORIGINS`.

AI Service: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AI_SERVICE_INTERNAL_KEY`, `MODEL_ID` y `SUPABASE_BUCKET_MINSA`.

Compose: `N8N_HOST` y `N8N_ENCRYPTION_KEY`.

## 5. Arrancar Contabo

```bash
docker compose --env-file deploy/.env -f docker-compose.contabo.yml config
docker compose --env-file deploy/.env -f docker-compose.contabo.yml build backend
docker compose --env-file deploy/.env -f docker-compose.contabo.yml up -d backend n8n nginx
docker compose --env-file deploy/.env -f docker-compose.contabo.yml ps
```

No ejecutes el Compose principal en Contabo: ese archivo también define un `ai-service` local. El Compose principal queda para desarrollo o despliegue monolítico.

## 5.1 Activar centros para el recomendador

En Supabase, ejecuta primero `database/migrations/005_centros_salud_recomendador.sql` y después `database/seeds/seed_centros_salud_managua.sql`. Confirma que existan `Hospital Infantil Manuel de Jesús Rivera La Mascota` y `Hospital Bertha Calderón Roque`. Ejecuta el seed una sola vez por entorno porque no es idempotente.

## 5.2 Verificar la conexión con RunPod

Desde Contabo, comprueba primero el Pod y después el backend:

```bash
curl -fsS https://POD_ID-8000.proxy.runpod.net/health
curl -fsS http://127.0.0.1/health
curl -fsS http://127.0.0.1/ready
```

Para probar la autenticación del AI Service sin exponer la clave en el historial del shell, usa una variable temporal:

```bash
read -rsp 'AI_SERVICE_INTERNAL_KEY: ' AI_KEY; echo
curl -fsS \
	-H "X-Internal-Key: $AI_KEY" \
	-H 'Content-Type: application/json' \
	-d '{"message":"emergencia pediátrica","latitude":12.12,"longitude":-86.25}' \
	https://POD_ID-8000.proxy.runpod.net/chat
unset AI_KEY
```

La respuesta debe incluir `centro_sugerido`. Con el seed cargado, el caso pediátrico debe poder seleccionar La Mascota y un caso obstétrico debe poder seleccionar Bertha Calderón.

Comprobar los servicios de Contabo:

```bash
curl http://biomark-api.duckdns.org/health
curl http://biomark-api.duckdns.org/ready
docker compose --env-file deploy/.env -f docker-compose.contabo.yml logs --tail=100 backend nginx n8n
```

## 6. HTTPS

La configuración inicial escucha en HTTP para permitir el provisionamiento. Antes de producción, colocar Certbot, un balanceador TLS o un proxy HTTPS delante de nginx y redirigir HTTP a HTTPS. No enviar JWT, tokens FCM ni datos médicos por HTTP público.

## 7. n8n

Entrar por el dominio protegido, crear usuario administrador y configurar el webhook de eventos. El workflow debe validar `X-Webhook-Secret`, enviar FCM y confirmar en `/internal/reminders/:id/sent`. No publicar `/internal` en Internet.

## 8. Actualizar Contabo

```bash
git pull origin main
docker compose --env-file deploy/.env -f docker-compose.contabo.yml up -d --build backend n8n nginx
```

Probar healthchecks después de cada actualización. Fijar versiones de imágenes, especialmente n8n, en vez de usar `latest`.

## 9. RunPod

RunPod ejecuta únicamente `ai-service`. En el Pod sin Docker, activa `/workspace/biomark-venv`, carga `/workspace/ai-service.env` y arranca Uvicorn dentro de una sesión persistente `tmux`. El detalle está en [DEPLOYMENT_CONTABO_RUNPOD.md](DEPLOYMENT_CONTABO_RUNPOD.md).

## 10. Backups y recuperación

Respaldar Supabase según su plan y realizar copia cifrada del volumen `n8n_data`. Los volúmenes `ai_models` y `ai_rag` pueden regenerarse, pero conservarlos evita descargas y reindexaciones largas.

## 11. Lista de aceptación

- [ ] Claves antiguas rotadas.
- [ ] RLS verificado.
- [ ] Enums verificados.
- [ ] HTTPS activo.
- [ ] Puertos internos cerrados.
- [ ] `/ready` devuelve 200.
- [ ] Login y refresh funcionan.
- [ ] Chat, voz y visión funcionan.
- [ ] Mapa y navegación funcionan.
- [ ] Consentimiento médico se respeta.
- [ ] Recordatorio llega por FCM.
- [ ] n8n confirma el recordatorio como enviado.
- [ ] Backups probados.
