# nginx

Nginx es la única entrada pública del Compose. Reenvía `/api` al backend y `/n8n` al servicio n8n; bloquea `/internal` y aplica límite de solicitudes.

El archivo incluido arranca HTTP para permitir el primer provisionamiento. Antes de producción, configura un dominio real y TLS con Certbot, redirige HTTP a HTTPS, añade HSTS y limita el acceso al panel n8n. No montes certificados privados en git.

Comprueba `nginx -t` dentro del contenedor y revisa logs de acceso/error durante la primera puesta en servicio.
