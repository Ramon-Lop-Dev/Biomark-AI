# Biomark AI — Automatización de Tareas (n8n)

Motor de automatización y orquestación de flujos de trabajo de salud preventiva autohospedado mediante Docker dentro de la red privada del sistema.

---

## 1. Función dentro del Ecosistema

n8n se encarga de la ejecución asíncrona de eventos preventivos, orquestación de alertas programadas y despacho de notificaciones críticas comunitarias hacia **Firebase Cloud Messaging (FCM)**:

### Catálogo de Eventos Procesados

| Evento | Origen en Backend | Destinatarios / Acción | Criticidad |
| :--- | :--- | :--- | :--- |
| `recordatorio.creado` | `reminders.service.js` | Dispositivo del paciente (dosis farmacológica o cita) | Media |
| `reporte_comunitario.urgente_rojo` | `community.service.js` | Personal médico del centro de salud territorial (`TRABAJADOR_SALUD`) | **Crítica Inmediata** |
| `evento_comunitario.creado` | `community.service.js` | Usuarios y promotores del sector geográfico (jornadas de salud) | Normal |
| `reporte_comunitario.validado` | `community.service.js` | Población de la zona (alerta comunitaria confirmada) | Alta |
| `alerta_epidemiologica.creada` | `epidemiology.service.js` | Población del municipio/distrito (brote oficial MINSA) | Alta |

### Flujo de Notificación Crítica (Triaje CCM Rojo)

```mermaid
sequenceDiagram
  autonumber
  participant C as Paciente / Promotor
  participant B as Backend Node.js
  participant N as n8n Automatizaciones
  participant F as Firebase (FCM)
  participant M as Personal Médico (Centro de Salud)

  C->>B: POST /api/community/reports (Signos de Alarma CCM)
  B->>B: Motor de Triaje clasifica "ROJO" (Urgente / Traslado)
  B->>N: Webhook reporte_comunitario.urgente_rojo (X-Webhook-Secret)
  N->>F: Enviar push de alta prioridad con sonido de alerta
  F->>M: Alerta en pantalla de guardia del Centro de Salud territorial
```

### Flujo de Recordatorios y Confirmación

```mermaid
sequenceDiagram
  autonumber
  participant B as Backend Node.js
  participant N as n8n Automatizaciones
  participant F as Firebase (FCM)
  participant C as Dispositivo Paciente

  B->>N: Webhook recordatorio.creado (X-Webhook-Secret)
  N->>F: Solicitud de envío de notificación push
  F->>C: Alerta de dosis o jornada en pantalla
  N->>B: Confirmación de envío (PATCH /internal/reminders/:id/sent)
```

*(Consulte la arquitectura completa de triaje y roles en [docs/ROLES_CONFANZA_Y_TRIAJE_CCM.md](../docs/ROLES_CONFANZA_Y_TRIAJE_CCM.md))*.

---

## 2. Configuración y Variables de Entorno

Las variables de conexión de n8n se definen en el archivo `deploy/.env`:

```env
N8N_HOST=localhost
N8N_PROTOCOL=http
WEBHOOK_URL=http://localhost:5678/
N8N_EDITOR_BASE_URL=http://localhost:5678/
N8N_SECURE_COOKIE=false
N8N_ENCRYPTION_KEY=tu_clave_de_encriptacion_permanente
```

> **Aviso de persistencia:** La variable `N8N_ENCRYPTION_KEY` nunca debe modificarse después de haber configurado credenciales en el panel de n8n, ya que de ella depende el descifrado de las conexiones y cuentas almacenadas.

---

## 3. Puesta en Marcha

Para iniciar el contenedor de n8n en el servidor:

```bash
docker compose --env-file deploy/.env up -d n8n
```

* **Acceso local:** `http://localhost:5678`
* **Acceso en producción:** A través de la ruta protegida configurada en Nginx (ej. `https://tu-dominio.com/n8n/`).

---

## 4. Importación del Flujo de Notificaciones

El repositorio incluye un flujo base listo para importar en `n8n/workflows/biomark-reminder-flow.json`:

1. Iniciar sesión en el panel web de n8n.
2. Seleccionar la opción **Import from File** y cargar el archivo `biomark-reminder-flow.json`.
3. Configurar la credencial de cuenta de servicio de Firebase (permiso `https://www.googleapis.com/auth/firebase.messaging`).
4. Asignar la variable de entorno interna `BIOMARK_WEBHOOK_SECRET` con el mismo valor configurado en el backend como `N8N_WEBHOOK_SECRET`.
5. Activar el flujo (*Active*).

---

## 5. Mantenimiento y Registros

Comandos habituales para la administración del contenedor:

```bash
# Ver registros en tiempo real
docker compose --env-file deploy/.env logs -f n8n

# Reiniciar el servicio tras cambios de configuración
docker compose --env-file deploy/.env restart n8n
```
