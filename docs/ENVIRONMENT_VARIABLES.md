# Variables de entorno

Esta es la referencia unica para configurar Biomark AI por ambiente. Los archivos `.env` reales contienen secretos y no deben subirse a Git.

## Que archivo usa cada servicio

| Archivo | Servicio | Ubicacion en produccion |
| --- | --- | --- |
| `deploy/backend.env` | Backend Node | Contabo |
| `deploy/.env` | Compose y n8n | Contabo |
| `deploy/ai-service.env` | AI Service | RunPod |
| `frontend/flutter/.env` | Firebase Web de Flutter | Maquina que compila Flutter |

El archivo `backend/.env` y `ai-service/.env` sirven solo para desarrollo local. En el despliegue distribuido no se copian al VPS como fuente de configuracion.

## Firebase y notificaciones push

El flujo de notificaciones es:

1. Flutter solicita permiso y obtiene un token FCM.
2. Flutter envia el token autenticado a `POST /api/users/push-token`.
3. El backend guarda el token en `dispositivos_push` en Supabase.
4. Al crear un recordatorio, el backend publica `recordatorio.creado` en n8n.
5. n8n consulta los tokens activos y envia FCM HTTP v1.
6. n8n confirma el envio con `PATCH /internal/reminders/:id/sent`.

### Flutter Web: valores publicos

Copiar la plantilla:

```bash
cd frontend/flutter
cp .env.example .env
```

Completar estos valores desde Firebase Console, en el mismo proyecto usado por backend y n8n:

```env
FIREBASE_PROJECT_ID=biomark-ai-prod
FIREBASE_MESSAGING_SENDER_ID=...
FIREBASE_WEB_API_KEY=...
FIREBASE_WEB_APP_ID=...
FIREBASE_AUTH_DOMAIN=biomark-ai-prod.firebaseapp.com
FIREBASE_STORAGE_BUCKET=biomark-ai-prod.firebasestorage.app
FIREBASE_VAPID_KEY=...
```

`FIREBASE_VAPID_KEY` es la clave publica Web Push de **Project settings > Cloud Messaging > Web configuration**. Estos valores son configuracion publica del cliente y se incluyen en el build Web, pero no deben confundirse con credenciales de servidor.

La URL del backend y el Client ID de Google se compilan con `--dart-define`:

```bash
flutter build web \
  --dart-define=BIOMARK_API_URL=https://biomark-api.duckdns.org \
  --dart-define=GOOGLE_WEB_CLIENT_ID=TU_CLIENT_ID_WEB
```

Cambiar `.env` no cambia esos dos valores si no se vuelve a compilar.

Para Android e iOS, Firebase usa la configuracion nativa de cada plataforma. No se debe poner una clave de service account en Flutter.

### Backend: Firebase Admin privado

En `deploy/backend.env` configurar solo el SDK Admin:

```env
FIREBASE_PROJECT_ID=biomark-ai-prod
FIREBASE_CLIENT_EMAIL=service-account@biomark-ai-prod.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

`FIREBASE_PRIVATE_KEY` debe conservar los `\n` escapados en una sola linea. El backend los convierte a saltos de linea al inicializar Firebase Admin. Nunca poner esta clave en Flutter, n8n workflow, README, logs o un archivo `.env.example` con valor real.

### n8n: envio FCM HTTP v1

En `deploy/.env` configurar:

```env
FCM_PROJECT_ID=biomark-ai-prod
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_SERVICE_ROLE_KEY=TU_SERVICE_ROLE_KEY
N8N_WEBHOOK_SECRET=EL_MISMO_SECRETO_QUE_EN_BACKEND
BACKEND_INTERNAL_URL=http://backend:3000
```

En la interfaz de n8n crear una credencial **Google API** con una cuenta de servicio de Firebase autorizada para `https://www.googleapis.com/auth/firebase.messaging` y seleccionarla en el nodo `Enviar notificacion FCM`. No guardar el JSON de la cuenta de servicio en este repositorio ni en el workflow exportado.

## Contabo

En el VPS:

```bash
ssh biomark@IP_DE_CONTABO
cd /opt/biomark-ai
cp deploy/backend.env deploy/backend.env.bak 2>/dev/null || true
cp deploy/.env deploy/.env.bak 2>/dev/null || true
nano deploy/backend.env
nano deploy/.env
```

Validar y recrear los servicios para que Docker cargue las variables nuevas:

```bash
docker compose --env-file deploy/.env -f docker-compose.contabo.yml config
docker compose --env-file deploy/.env -f docker-compose.contabo.yml up -d --force-recreate backend n8n nginx
docker compose --env-file deploy/.env -f docker-compose.contabo.yml ps
curl -fsS https://biomark-api.duckdns.org/health
curl -fsS https://biomark-api.duckdns.org/ready
```

Si se cambia `N8N_ENCRYPTION_KEY`, n8n puede perder sus credenciales guardadas. Esa variable debe conservarse permanentemente.

## RunPod

En el Pod, configurar `/workspace/ai-service.env` con `AI_SERVICE_INTERNAL_KEY`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `PORT`, `MODEL_ID`, `SUPABASE_BUCKET_MINSA` y los modelos opcionales de voz/vision. `AI_SERVICE_INTERNAL_KEY` debe ser exactamente igual a la de Contabo.

## Frontend Web en Contabo

El frontend compilado no lee el `.env` que exista en Contabo despues de construirlo. El `.env` debe existir en la maquina de compilacion:

```bash
cd frontend/flutter
cp .env.example .env
nano .env
flutter build web \
  --dart-define=BIOMARK_API_URL=https://biomark-api.duckdns.org \
  --dart-define=GOOGLE_WEB_CLIENT_ID=TU_CLIENT_ID_WEB
rsync -avz --delete build/web/ biomark@IP_DE_CONTABO:/opt/biomark-ai/frontend-web/
```

Despues de modificar Firebase Web, siempre hay que volver a ejecutar `flutter build web` y subir nuevamente `build/web`. No se actualiza un build existente editando archivos de entorno en el VPS.

## Seguridad

- No publicar `SUPABASE_SERVICE_ROLE_KEY`, `AI_SERVICE_INTERNAL_KEY`, `N8N_WEBHOOK_SECRET`, `FIREBASE_PRIVATE_KEY`, `JWT_SECRET`, `HF_TOKEN`, `STT_API_KEY` ni `TTS_API_KEY`.
- Rotar cualquier secreto que haya sido pegado en un repositorio, chat, log o archivo compartido.
- No usar `*` en `CORS_ORIGINS`.
- Mantener HTTPS para Flutter, nginx y el proxy HTTPS de RunPod.
- No exponer los puertos 3000, 5678 ni 8000 directamente a Internet.
