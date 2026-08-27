# Backend

## VPS

Se ejecuta con `Dockerfile.backend` y escucha internamente en el puerto 3000. Usa `deploy/backend.env` con `SUPABASE_SERVICE_ROLE_KEY`, `AI_SERVICE_INTERNAL_KEY`, `N8N_WEBHOOK_SECRET`, `AI_SERVICE_URL=http://ai-service:8000` y `CORS_ORIGINS` limitado al dominio Flutter/Web.

Nunca publiques el service role key, no ejecutes Node como root y no abras el puerto 3000. El endpoint `/internal/reminders/:id/sent` solo acepta `X-Webhook-Secret` y debe permanecer detrás de la red privada.

Rutas relevantes: `/api/chat`, `/api/voice`, `/api/gis/smart-map`, `/api/navigation/recommend`, `/api/vaccines/recommendations`, `/api/users/consent` y `/api/users/push-token`.

Validación local: `npm ci`, `node --check src/app.js`. El proyecto todavía necesita una suite de pruebas de integración contra un proyecto Supabase de staging.
