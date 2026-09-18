# Biomark AI — Centro de Documentación

Índice central de la documentación técnica, manuales de instalación, especificaciones de arquitectura y guías operativas de Biomark AI.

---

## 1. Índice de Documentos

| Documento | Descripción y Alcance |
| :--- | :--- |
| [Documentación Técnica](TECHNICAL_DOCUMENTATION.md) | Arquitectura integral, descripción de módulos, diagramas de flujo, base de datos y modelo de seguridad. |
| [Manual de Despliegue en VPS](INSTALLATION_VPS.md) | Guía paso a paso para la preparación de servidores Linux, Docker Compose, configuración de firewall y certificados SSL. |
| [Despliegue Distribuido (Contabo + RunPod)](DEPLOYMENT_CONTABO_RUNPOD.md) | Procedimiento para operar el backend y automatizaciones en VPS y el microservicio de IA en GPU Cloud. |
| [Configuración de Dominio con DuckDNS](DUCKDNS_CONTABO.md) | Configuración de DNS dinámico, certificados HTTPS de Let's Encrypt y enrutamiento en Nginx. |
| [Variables de Entorno](ENVIRONMENT_VARIABLES.md) | Catálogo completo de variables de entorno requeridas para backend, AI Service, Nginx y n8n. |
| [Especificación OpenAPI](openapi.yaml) | Definición contractual estandarizada de todos los endpoints de la API pública y privada. |
| [Colección Postman](postman/Biomark-AI.postman_collection.json) | Colección lista para importar con pruebas de autenticación, chat, signos vitales, recomendaciones MINSA y geolocalización. |

---

## 2. Recomendaciones de Consulta

1. **Visión general y arquitectura:** Comience con el [README principal](../README.md) y la [Documentación Técnica](TECHNICAL_DOCUMENTATION.md) para entender el flujo de datos entre el cliente Flutter, el backend Node.js y el servicio de inferencia en RunPod.
2. **Puesta en producción:** Consulte la guía de [Despliegue Distribuido](DEPLOYMENT_CONTABO_RUNPOD.md) y aplique las pautas de seguridad del [Manual de Despliegue](INSTALLATION_VPS.md).
3. **Validación de la API:** Importe la especificación [OpenAPI](openapi.yaml) o la colección de Postman para probar los endpoints en entornos locales o de prueba.

---

## 3. Políticas de Seguridad de la Información

* **Gestión de Secretos:** Nunca confirme claves privadas de Firebase, tokens de servicio (`SUPABASE_SERVICE_ROLE_KEY`) ni claves internas (`AI_SERVICE_INTERNAL_KEY`) en el control de versiones.
* **Aislamiento de Red:** El microservicio de inferencia de IA y las rutas internas de automatización (`/internal/*`) solo deben ser accesibles desde la red interna o mediante claves secretas precompartidas.
* **Cifrado en Tránsito:** Toda comunicación entre los clientes móviles/web y el servidor debe efectuarse obligatoriamente bajo HTTPS con certificados TLS válidos.
