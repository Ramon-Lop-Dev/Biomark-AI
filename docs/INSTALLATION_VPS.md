# Manual de instalación y despliegue en VPS

## Requisitos

- Ubuntu 22.04/24.04.
- Docker Engine y Docker Compose v2.
- DNS apuntando al VPS.
- Firewall con 80/443 abiertos y puertos 3000/8000/5678 cerrados.
- Supabase configurado con schema, RLS, Storage y proveedores Auth.
- VPS con memoria suficiente para los modelos AI; 8 GB es un mínimo práctico para comenzar y debe validarse con carga real.

## 1. Preparar el servidor

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

## 2. Descargar el proyecto

```bash
git clone URL_DEL_REPOSITORIO biomark-ai
cd biomark-ai
```

No copiar `backend/.env` al VPS. Si alguna clave estuvo expuesta, rotarla antes.

## 3. Crear secretos

```bash
mkdir -p deploy
cp deploy/backend.env.example deploy/backend.env
cp deploy/ai-service.env.example deploy/ai-service.env
cp deploy/.env.example deploy/.env
openssl rand -hex 32
```

Editar los tres archivos. `AI_SERVICE_INTERNAL_KEY` debe ser idéntica en backend y AI Service. `N8N_ENCRYPTION_KEY` debe conservarse para no perder credenciales de n8n.

## 4. Variables de producción mínimas

Backend: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AI_SERVICE_URL=http://ai-service:8000`, `AI_SERVICE_INTERNAL_KEY`, `N8N_WEBHOOK_URL`, `N8N_WEBHOOK_SECRET`, `CORS_ORIGINS`.

AI Service: `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `AI_SERVICE_INTERNAL_KEY`, `MODEL_ID` y `SUPABASE_BUCKET_MINSA`.

Compose: `N8N_HOST` y `N8N_ENCRYPTION_KEY`.

## 5. Arrancar

```bash
docker compose --env-file deploy/.env config
docker compose --env-file deploy/.env up -d --build
docker compose --env-file deploy/.env ps
```

## 5.1 Activar centros para el recomendador

En Supabase, ejecuta primero `database/migrations/005_centros_salud_recomendador.sql` y después `database/seeds/seed_centros_salud_managua.sql`. Confirma que existan `Hospital Infantil Manuel de Jesús Rivera La Mascota` y `Hospital Bertha Calderón Roque`. Ejecuta el seed una sola vez por entorno porque no es idempotente.

El primer arranque puede tardar por descarga de modelos. Comprobar:

```bash
curl http://DOMINIO/health
curl http://DOMINIO/ready
docker compose logs -f backend ai-service n8n
```

## 6. HTTPS

La configuración inicial escucha en HTTP para permitir el provisionamiento. Antes de producción, colocar Certbot, un balanceador TLS o un proxy HTTPS delante de nginx y redirigir HTTP a HTTPS. No enviar JWT, tokens FCM ni datos médicos por HTTP público.

## 7. n8n

Entrar por el dominio protegido, crear usuario administrador y configurar el webhook de eventos. El workflow debe validar `X-Webhook-Secret`, enviar FCM y confirmar en `/internal/reminders/:id/sent`. No publicar `/internal` en Internet.

## 8. Actualizar

```bash
git pull
docker compose --env-file deploy/.env up -d --build
docker image prune
```

Probar healthchecks después de cada actualización. Fijar versiones de imágenes, especialmente n8n, en vez de usar `latest`.

## 9. Backups y recuperación

Respaldar Supabase según su plan y realizar copia cifrada del volumen `n8n_data`. Los volúmenes `ai_models` y `ai_rag` pueden regenerarse, pero conservarlos evita descargas y reindexaciones largas.

## 10. Lista de aceptación

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
