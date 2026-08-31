# Backend

## VPS

Se ejecuta con `Dockerfile.backend` y escucha internamente en el puerto 3000. Usa `deploy/backend.env` con `SUPABASE_SERVICE_ROLE_KEY`, `AI_SERVICE_INTERNAL_KEY`, `N8N_WEBHOOK_SECRET`, `AI_SERVICE_URL=http://ai-service:8000` y `CORS_ORIGINS` limitado al dominio Flutter/Web.

Nunca publiques el service role key, no ejecutes Node como root y no abras el puerto 3000. El endpoint `/internal/reminders/:id/sent` solo acepta `X-Webhook-Secret` y debe permanecer detrás de la red privada.

Rutas relevantes: `/api/chat`, `/api/voice`, `/api/gis/smart-map`, `/api/navigation/recommend`, `/api/vaccines/recommendations`, `/api/users/consent` y `/api/users/push-token`.

## Chat desde Flutter

Flutter llama exclusivamente a `POST /api/chat` mediante HTTPS y envía:

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

```json
{
	"message": "Tengo fiebre desde ayer",
	"session_id": "uuid-opcional",
	"latitude": 12.1,
	"longitude": -86.2
}
```

El primer mensaje puede omitir `session_id`; el backend crea la sesión y devuelve el UUID. Los mensajes siguientes deben reutilizarlo. La respuesta pública contiene `session_id`, `reply`, `risk_level` y `sources`.

El backend reenvía la consulta al `AI_SERVICE_URL` privado usando `X-Internal-Key`. Nunca envíes `AI_SERVICE_INTERNAL_KEY` al frontend ni publiques el puerto 8000.

Para probarlo en el VPS:

```bash
curl -X POST https://api.tu-dominio.ni/api/chat \
	-H "Authorization: Bearer $ACCESS_TOKEN" \
	-H "Content-Type: application/json" \
	-d '{"message":"Tengo fiebre desde ayer"}'
```

Validación local: `npm ci`, `node --check src/app.js`. El proyecto todavía necesita una suite de pruebas de integración contra un proyecto Supabase de staging.
