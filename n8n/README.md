# n8n self-hosted

El proyecto ya tiene n8n orquestado por Docker dentro de la red privada `biomark`, con volumen persistente `n8n_data` y acceso a través de nginx. Para dejarlo listo para local y luego para la VPN, la configuración debe centrarse en dos cosas: un dominio o host interno para n8n y un secreto compartido con el backend.

## 1. Variables mínimas

Crea o edita `deploy/.env` a partir del ejemplo:

```bash
cp deploy/.env.example deploy/.env
```

Valores recomendados para arranque local:

```env
N8N_HOST=localhost
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678/
N8N_EDITOR_BASE_URL=http://localhost:5678/
N8N_SECURE_COOKIE=false
N8N_ENCRYPTION_KEY=GENERATE_WITH_OPENSSL
```

Cuando lo subas a la VPN o a un dominio privado:

```env
N8N_HOST=vpn.internal.local
N8N_PROTOCOL=https
WEBHOOK_URL=https://vpn.internal.local/n8n/
N8N_EDITOR_BASE_URL=https://vpn.internal.local/n8n/
N8N_SECURE_COOKIE=true
N8N_ENCRYPTION_KEY=tu_clave_larga_y_persistente
```

Importante: nunca cambies la `N8N_ENCRYPTION_KEY` una vez creado el usuario y los credenciales, porque se perderán las conexiones guardadas.

## 2. Arrancar n8n en local

```bash
docker compose --env-file deploy/.env up -d n8n
```

Y luego:

- UI: http://localhost:5678
- Si usas nginx: http://localhost/n8n/

La app queda dentro de la red Docker y no debe exponerse en Internet. La entrada pública es nginx, no el puerto 5678.

## 3. Flujo recomendado: recordatorio creado

El backend ya publica el evento `recordatorio.creado` hacia `N8N_WEBHOOK_URL` usando el secreto `N8N_WEBHOOK_SECRET` y el endpoint interno `/internal/reminders/:id/sent` ya está protegido con `X-Webhook-Secret`.

El flujo de n8n que debes importar debe seguir este patrón:

1. Webhook trigger (`POST /webhook/biomark-events`)
2. Validar cabecera `X-Webhook-Secret`
3. Comprobar que `body.evento === 'recordatorio.creado'`
4. Extraer `recordatorio.id` y `usuario_id`
5. Enviar notificación por FCM o Firebase Messaging
6. Llamar a `PATCH /internal/reminders/:id/sent` con el mismo secreto
7. Registrar respuesta y errores con reintentos

No expongas `/internal` ni los tokens FCM fuera de la red privada.

## 4. Importar el flujo de ejemplo

Hay un ejemplo listo en `n8n/workflows/biomark-reminder-flow.json` para importar desde la UI de n8n:

- Abrir n8n
- Crear el primer usuario administrador
- Importar workflow
- Ajustar credenciales de Firebase y URL del backend
- Crear variables de entorno dentro de n8n:
  - `BIOMARK_WEBHOOK_SECRET` = mismo valor que `N8N_WEBHOOK_SECRET` en backend
  - `BACKEND_BASE_URL` = http://backend:3000 o http://localhost:3000 si lo pruebas localmente
  - `FCM_PROJECT_ID`, `FCM_SERVICE_ACCOUNT` o la credencial que uses con Firebase

## 5. Configuración para VPN

Cuando pases la app a la VPN o al servidor privado:

- mantén `n8n` dentro de la red Docker
- usa nginx para servir `/n8n`
- usa `N8N_EDITOR_BASE_URL=https://<vpn-host>/n8n/`
- usa `WEBHOOK_URL=https://<vpn-host>/n8n/`
- activa `N8N_SECURE_COOKIE=true`
- deja `N8N_WEBHOOK_SECRET` igual en backend y n8n
- no publiques `/internal` ni el puerto 5678 directamente

## 6. Recomendaciones de producción

- fija una versión del image en vez de `latest`
- respalda el volumen `n8n_data` con copia cifrada
- usa autenticación fuerte para el editor
- conserva la clave de encriptación
- usa HTTPS y proxy reverse por nginx

## 7. Comandos útiles

```bash
docker compose --env-file deploy/.env logs -f n8n

docker volume inspect biomark-ai_n8n_data

docker compose --env-file deploy/.env up -d --force-recreate n8n
```

Si haces cambios en la configuración o en el workflow, reinicia solo el servicio `n8n` para probar sin afectar al resto.
