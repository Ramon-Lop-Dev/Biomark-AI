# n8n self-hosted

Compose usa `n8nio/n8n` con SQLite persistente en el volumen `n8n_data`. En VPS define `N8N_HOST`, `N8N_ENCRYPTION_KEY` y `WEBHOOK_URL` en `deploy/.env`; nunca pierdas la encryption key porque inutiliza credenciales guardadas.

Crea un webhook para `recordatorio.creado`, valida `X-Webhook-Secret`, entrega mediante FCM usando credenciales almacenadas en n8n y llama a `PATCH /internal/reminders/:id/sent` con el mismo secreto. Añade reintentos y registra errores sin exponer tokens.

Para producción, fija una versión de imagen en vez de `latest`, respalda `n8n_data`, protege el editor con autenticación fuerte y publícalo únicamente por HTTPS. El endpoint interno del backend no debe ser accesible desde Internet.
