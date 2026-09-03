# Base de datos

Supabase es la base de producción. Ejecuta las migraciones en orden desde el SQL Editor o un pipeline controlado: `migrations/002_auditoria_operativa.sql` y `migrations/003_dispositivos_push.sql`.

Verifica antes los enums USER-DEFINED y las políticas RLS en el proyecto correcto. No uses `schema.sql` como migración automática: es documentación del esquema y no incluye necesariamente el orden válido de creación.

Para activar las recomendaciones clínicas del chat, ejecuta `migrations/005_centros_salud_recomendador.sql` y después `seeds/seed_centros_salud_managua.sql` en un entorno controlado. El seed contiene 66 centros de Managua y usa los valores del enum `tipo_centro_salud`: `HOSPITAL`, `CENTRO_SALUD`, `PUESTO_MEDICO`, `CLINICA` y `JORNADA_SALUD`. Las coordenadas marcadas como aproximadas no deben presentarse como navegación exacta.

Antes de cambios destructivos: backup, staging y comprobación de duplicados. El backend espera las tablas `consentimientos`, `dispositivos_push`, coordenadas de `eventos_comunitarios` y `fecha_expiracion` de alertas.
