# Base de datos

Supabase es la base de producción. Ejecuta las migraciones en orden desde el SQL Editor o un pipeline controlado: `migrations/002_auditoria_operativa.sql` y `migrations/003_dispositivos_push.sql`.

Verifica antes los enums USER-DEFINED y las políticas RLS en el proyecto correcto. No uses `schema.sql` como migración automática: es documentación del esquema y no incluye necesariamente el orden válido de creación.

Antes de cambios destructivos: backup, staging y comprobación de duplicados. El backend espera las tablas `consentimientos`, `dispositivos_push`, coordenadas de `eventos_comunitarios` y `fecha_expiracion` de alertas.
