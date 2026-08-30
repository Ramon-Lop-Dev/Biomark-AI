# Documentación del proyecto

- [Documentación técnica completa](TECHNICAL_DOCUMENTATION.md): arquitectura, módulos, dependencias, seguridad, base de datos, operación y pruebas.
- [Manual de instalación en VPS](INSTALLATION_VPS.md): instalación, secretos, Docker Compose, HTTPS, n8n, backups y checklist.
- [Especificación OpenAPI](openapi.yaml): importar en Swagger UI, Swagger Editor o Postman.
- [Colección Postman](postman/Biomark-AI.postman_collection.json): pruebas de health, auth, privacidad, clínica, mapa y n8n.

## Cómo usar OpenAPI

1. Abre Swagger Editor o Swagger UI.
2. Importa `docs/openapi.yaml`.
3. Selecciona `Authorize`.
4. Introduce `Bearer <access_token>`.
5. Ejecuta primero `/health`, `/ready` y login.
6. Copia el `access_token` a la colección Postman para probar los endpoints protegidos.

Los endpoints AI (`/chat`, `/voice`, `/vision`) y `/internal` no son API pública. Solo se consumen desde backend o n8n dentro de la red privada Docker.
