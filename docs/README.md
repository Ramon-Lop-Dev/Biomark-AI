# Documentación del proyecto

Esta carpeta centraliza la documentación operativa, técnica y de integración del sistema Biomark AI.

## Índice

- [Documentación técnica completa](TECHNICAL_DOCUMENTATION.md): arquitectura, módulos, base de datos, seguridad, automatizaciones y operación.
- [Manual de instalación en VPS](INSTALLATION_VPS.md): preparación del servidor, variables de entorno, Docker Compose, HTTPS, backups y checklist de producción.
- [Especificación OpenAPI](openapi.yaml): contrato de la API pública y sus rutas protegidas.
- [Colección Postman](postman/Biomark-AI.postman_collection.json): pruebas de auth, salud, chat, GIS, epidemiología, recordatorios y notificaciones.
- [Datos GIS](../database/README.md): migración y seed de centros usados por la recomendación clínica.
- [README general del repositorio](../README.md): visión general, estructura y arranque rápido.

## Cómo usar esta documentación

1. Empezar por [../README.md](../README.md) para conocer objetivos y estructura.
2. Revisar [TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md) antes de tocar la arquitectura o despliegue.
3. Consultar [INSTALLATION_VPS.md](INSTALLATION_VPS.md) para producción y operación en servidor.
4. Importar [openapi.yaml](openapi.yaml) en Swagger Editor o Swagger UI para validar contratos.
5. Probar endpoints con la colección de Postman, priorizando login, health y chat.

## Alcance de la API

Los endpoints públicos del backend se consumen con JWT desde Flutter o clientes autorizados. Los endpoints AI (`/chat`, `/voice`, `/vision`) y los rutas `/internal` no forman parte de la API pública y solo deben exponerse dentro del entorno privado de Docker.

## Recomendaciones de seguridad

- Mantener `SUPABASE_SERVICE_ROLE_KEY` solo en backend y AI Service.
- No compartir `AI_SERVICE_INTERNAL_KEY` ni tokens de cliente en repositorios públicos.
- Usar HTTPS y certificados válidos delante de nginx en producción.
- Proteger n8n con `X-Webhook-Secret` y no abrir `/internal` al exterior.
- Mantener RLS activo en Supabase y auditar accesos sensibles.

## Estado esperado del proyecto

La documentación refleja la arquitectura implementada y la línea de despliegue propuesta. El estado operativo real dependerá de la configuración final de Supabase, los secretos, el entorno de GPU/CPU para el modelo y la vinculación de n8n con FCM.
