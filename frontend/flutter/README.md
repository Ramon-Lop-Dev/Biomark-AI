# Flutter

## Despliegue y conexión al VPS

Configura la URL base de producción con el dominio HTTPS publicado por nginx. No uses `localhost`, ngrok ni URLs de los contenedores. Mantén las claves de Supabase y Firebase en configuración segura por ambiente; nunca incluyas `SUPABASE_SERVICE_ROLE_KEY` en Flutter. La configuración se lee desde `BIOMARK_API_URL` y por defecto usa `https://biomark-api.duckdns.org`.

Flujos que deben probarse contra el VPS: autenticación, encuesta (edad/sexo y contexto clínico), perfil, consentimiento médico, historial de chat, chat, voz, visión, vacunas, objetivos/hitos, recordatorios, mapa inteligente, navegación y recepción de notificaciones FCM.

El token push se registra en `POST /api/users/push-token` después de solicitar consentimiento. Al enviar un mensaje del chat, la app solicita ubicación en uso; si el servicio está desactivado o el permiso fue bloqueado, muestra un aviso y abre los ajustes cuando corresponde. Si se autoriza, envía `latitude` y `longitude` juntas. Para síntomas, el backend devuelve `ubicacion_requerida: true` si no llegaron coordenadas. Cuando devuelve `centro_sugerido`, la burbuja muestra nombre, especialidad coincidente, distancia aproximada, dirección y acceso al mapa.

## Audio y multimedia

- Texto: respuesta escrita, sin síntesis automática.
- Imagen: `image_picker` envía piel o garganta a `POST /api/vision`; la respuesta se muestra como texto preventivo.
- Voz: `record` crea el archivo del usuario y `POST /api/voice` devuelve transcripción, respuesta escrita y `audio_base64` WAV. Flutter guarda el archivo temporal y lo reproduce como respuesta de voz.
- El endpoint separado `/api/voice/synthesize` existe para integraciones autorizadas, pero no se usa automáticamente para respuestas de texto.

En Android se declaran cámara, micrófono y ubicación en `android/app/src/main/AndroidManifest.xml`; en iOS se declaran mensajes de uso en `Info.plist`. En web el navegador exige HTTPS y permisos equivalentes.
