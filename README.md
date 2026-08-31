# Biomark AI

## Documentación técnica

La documentación completa está en [docs/TECHNICAL_DOCUMENTATION.md](docs/TECHNICAL_DOCUMENTATION.md). Para instalar en un VPS, sigue [docs/INSTALLATION_VPS.md](docs/INSTALLATION_VPS.md). La especificación de API está en [docs/openapi.yaml](docs/openapi.yaml) y la colección Postman en [docs/postman/Biomark-AI.postman_collection.json](docs/postman/Biomark-AI.postman_collection.json).

Resumen rápido: Flutter consume nginx por HTTPS; nginx enruta al backend; backend y AI Service permanecen privados en Docker; Supabase aloja los datos; n8n self-hosted automatiza notificaciones FCM.

## Despliegue VPS

Arquitectura: `nginx` publica HTTP/HTTPS; `backend`, `ai-service` y `n8n` viven en una red Docker privada. Supabase es externo y es la única fuente de verdad de datos.

1. Instala Docker Engine y Compose v2 en Ubuntu 22.04/24.04.
2. Rota cualquier secreto que haya estado en `backend/.env` antes de desplegar.
3. Copia `deploy/backend.env.example` a `deploy/backend.env`, `deploy/ai-service.env.example` a `deploy/ai-service.env` y `deploy/.env.example` a `deploy/.env`.
4. Genera secretos: `openssl rand -hex 32`.
5. Configura DNS, firewall (80/443), Supabase y el bucket RAG.
6. Ejecuta `docker compose --env-file deploy/.env up -d --build`.
7. Comprueba `curl http://DOMINIO/health` y `curl http://DOMINIO/ready`.

El Compose no levanta PostgreSQL local: evita divergir del esquema y RLS ya aplicados en Supabase. Para producción, coloca TLS delante de nginx con Certbot o un proxy gestionado y no expongas puertos 3000, 8000, 5678 ni el endpoint `/internal`.

### Flujo de prueba del chat

1. Obtén un `token` con `POST https://DOMINIO/api/auth/login`.
2. Usa ese token en `Authorization: Bearer ...` para `POST https://DOMINIO/api/chat`.
3. Conserva el `session_id` devuelto por el backend para los mensajes siguientes.
4. Configura Flutter con `BIOMARK_API_URL=https://DOMINIO` y el token de acceso. Flutter nunca necesita `AI_SERVICE_INTERNAL_KEY`.

## Operación

`docker compose logs -f backend ai-service n8n`; actualiza con `docker compose pull && docker compose up -d --build`; respalda el volumen `n8n_data` y configura backups de Supabase. El modelo AI puede requerir mucha RAM/CPU y el primer arranque descarga modelos.
