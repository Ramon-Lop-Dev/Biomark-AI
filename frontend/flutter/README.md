# Flutter

## Despliegue y conexión al VPS

Configura la URL base de producción con el dominio HTTPS publicado por nginx. No uses `localhost`, ngrok ni URLs de los contenedores. Mantén las claves de Supabase y Firebase en configuración segura por ambiente; nunca incluyas `SUPABASE_SERVICE_ROLE_KEY` en Flutter.

Flujos que deben probarse contra el VPS: autenticación, perfil, consentimiento médico, chat, voz, visión, vacunas, recordatorios, mapa inteligente, navegación y recepción de notificaciones FCM.

El token push se registra en `POST /api/users/push-token` después de solicitar consentimiento. La ubicación se envía solo cuando el usuario la autoriza.
