# Frontend Flutter

El frontend debe apuntar al dominio HTTPS del nginx, no a `localhost`, ngrok ni a los puertos internos Docker. Configura la URL por ambiente (desarrollo, staging, producción) y no incluyas claves service role.

Registra el token FCM en `POST /api/users/push-token` después de obtener consentimiento de notificaciones. Envía `session_id` UUID para conservar memoria de chat y solicita ubicación solo con consentimiento explícito.

Prueba en dispositivo real contra el VPS: login, chat, voz, mapa inteligente, navegación, vacunas, recordatorios y recepción de push.
