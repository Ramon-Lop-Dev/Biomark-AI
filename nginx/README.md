# Biomark AI — Proxy Inverso Nginx

Servicio de proxy inverso y terminación TLS/SSL que actúa como única puerta de entrada pública hacia la infraestructura del backend y las automatizaciones en el servidor VPS.

---

## 1. Responsabilidades del Proxy

* **Terminación SSL/HTTPS:** Cifrado de todas las comunicaciones cliente-servidor mediante certificados TLS válidos (Let's Encrypt).
* **Enrutamiento de Solicitudes:**
  * Rutas `/api/*`: Redirigidas al contenedor del backend de Node.js (puerto `3000`).
  * Rutas `/n8n/*`: Redirigidas al panel de automatización de n8n (puerto `5678`).
* **Protección y Filtrado de Seguridad:**
  * Bloqueo estricto del acceso externo a rutas internas y webhooks privados (`/internal/*`).
  * Aplicación de límites de velocidad de peticiones (*rate limiting*) para mitigar ataques de denegación de servicio (DoS) y fuerza bruta.
  * Encabezados de seguridad HTTP estandarizados (HSTS, X-Frame-Options, X-Content-Type-Options).

---

## 2. Configuración para Producción

En el entorno de producción, la configuración se enlaza con el dominio público del servidor:

```text
nginx/
├── conf.d/
│   └── default.conf        # Reglas de proxy reverso, límites de tráfico y SSL
└── certs/                  # Directorio para certificados Let's Encrypt (no versionado)
```

### Comprobación de Sintaxis

Antes de reiniciar el contenedor tras realizar modificaciones en la configuración:

```bash
docker compose exec nginx nginx -t
```

### Recarga de la Configuración sin Interrupción

```bash
docker compose exec nginx nginx -s reload
```

---

## 3. Recomendaciones de Seguridad

* No almacene certificados privados en el repositorio de Git.
* Mantenga activada la redirección obligatoria de tráfico HTTP hacia HTTPS.
* Limite el acceso al panel administrativo de n8n mediante autenticación de usuario o red privada.
