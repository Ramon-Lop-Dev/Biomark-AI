# Biomark AI — Base de Datos (Supabase / PostgreSQL)

Capa de persistencia relacional, seguridad a nivel de filas (**Row Level Security - RLS**), procedimientos almacenados y almacenamiento de objetos (**Supabase Storage**) para Biomark AI.

---

## 1. Orden de Ejecución de Migraciones

Para configurar o actualizar la base de datos en Supabase, ejecute las migraciones en el editor SQL respetando el orden secuencial:

| Archivo | Propósito Principal |
| :--- | :--- |
| `migrations/002_auditoria_operativa.sql` | Registro centralizado de auditoría médica y trazabilidad de acciones operativas. |
| `migrations/003_dispositivos_push.sql` | Almacenamiento de tokens FCM para notificaciones y alertas epidemiológicas. |
| `migrations/004_seguimiento_evolucion.sql` | Registro estructurado de la evolución clínica (`MEJORO`, `IGUAL`, `EMPEORO`, `NO_SEGURO`). |
| `migrations/005_centros_salud_recomendador.sql` | Estructura para recomendación inteligente de unidades de salud por especialidad. |
| `migrations/006_objetivos_mejoria.sql` | Metas de salud del paciente y seguimiento de recuperación. |
| `migrations/007_solicitudes_roles.sql` | Gestión del ciclo de vida para solicitudes de ascenso a rol `PROMOTOR`. |
| `migrations/008_flujo_promotor.sql` | Vínculos de pacientes asignados a promotores de salud comunitaria. |
| `migrations/009_fotos_perfil.sql` | Metadatos y políticas para el bucket de avatares en Supabase Storage. |
| `migrations/010_eliminar_cuenta_usuario.sql` | Procedimiento almacenado `eliminar_cuenta_usuario(usuario_uuid)` para borrado seguro en cascada y revocación de accesos. |
| `migrations/011_recordatorios_frecuencia.sql` | Parámetros de frecuencia horaria y diaria para tomas farmacológicas. |
| `migrations/012_recordatorios_aviso_previo.sql` | Ventanas de aviso preventivo previo a la hora de medicación. |
| `migrations/013_recomendaciones_salud.sql` | Esquema de pautas MINSA (`recomendaciones_salud`), validaciones de categorías sanitarias, enlaces normativos y semillas oficiales de prevención. |
| `migrations/014_consolidacion_esquema_salud.sql` | Consolidación del esquema clínico, perfiles de salud y tipos de datos normalizados. |
| `migrations/015_consolidacion_definitiva_tablas.sql` | Consolidación integral de tablas comunitarias, auditoría y vínculos de usuarios. |
| `migrations/016_onboarding_entrevista_contenido.sql` | Estructura para cuestionario de salud inicial, fecha de nacimiento (`fecha_nacimiento`) y cálculo de edad. |
| `migrations/017_avisos_minsa_segmentacion.sql` | Segmentación territorial de avisos oficiales por municipio y distrito. |
| `migrations/018_reportes_comunitarios_robustos.sql` | Campos enriquecidos para vigilancia comunitaria y georreferenciación. |
| `migrations/021_roles_cascada_minsa_ccm.sql` | Roles de confianza institucional (`ADMIN` -> `TRABAJADOR_SALUD` -> `PROMOTOR`), tabla `invitaciones`, scoping territorial (`centro_salud_id`, `distrito`, `municipio`), triaje clínico CCM (`triaje_sugerido`, `signos_alarma`, `requiere_traslado_urgente`, `estado_resolucion`) y llaves foráneas. |

---

## 2. Semillas de Datos (Seeds) y Filosofía Zero-Seed

1. **Catálogo de Unidades de Salud de Managua:**
   * Ejecutar `seeds/seed_centros_salud_managua.sql` para poblar la red de hospitales, centros de salud y puestos médicos del departamento de Managua con coordenadas georreferenciadas y especialidades validadas.
2. **Pautas Sanitarias Oficiales:**
   * La migración `013_recomendaciones_salud.sql` incluye automáticamente las semillas oficiales del MINSA para Dengue (Normativa 004), Olas de Calor, Salud Cardiovascular, Adherencia al Tratamiento, Diabetes (Normativa 078) y Salud Respiratoria (Normativa 028).
3. **Filosofía Zero-Seed para Datos Operativos:**
   * Se eliminaron las semillas simuladas o datos precargados ficticios en jornadas de salud, avisos comunitarios y reportes epidemiológicos. Todas las operaciones comunitarias y notificaciones en tiempo real provienen de registros reales cargados por los promotores y trabajadores de salud autorizados.

---

## 3. Políticas de Seguridad (RLS), Tabla de Invitaciones y Roles

* **Row Level Security (RLS):** Cada tabla posee políticas estrictas. Los pacientes únicamente pueden leer o modificar sus propios registros médicos, chats y signos vitales mediante su `auth.uid()`.
* **Tabla `invitaciones`:**
  * Almacena tokens únicos de 8 caracteres alfanuméricos con expiración de 7 días.
  * Tipos de invitación: `INVITACION_TRABAJADOR_SALUD` (creada por `ADMIN` vinculada a `centro_salud_id`) e `INVITACION_PROMOTOR` (creada por `TRABAJADOR_SALUD` o `ADMIN` asignada a su centro/jurisdicción).
  * Estados: `PENDIENTE`, `USADA`, `REVOCADA`, `EXPIRADA`.
* **Gobernanza Sanitaria en Cascada (RBAC):**
  * `USUARIO`: Ciudadano general. Consulta recomendaciones, registra pulso, utiliza el chat clínico y emite reportes comunitarios triados.
  * `PROMOTOR`: Promotor comunitario de la Red Comunitaria. Acreditado por un trabajador de salud de su jurisdicción territorial. Puede registrar eventos comunitarios y monitorear reportes de su sector.
  * `TRABAJADOR_SALUD`: Personal médico o enfermería adscrito a un centro de salud. Acredita y supervisa a promotores, valida reportes comunitarios y recibe alertas de triaje crítico (`ROJO`).
  * `ADMIN`: Autoridad institucional (SILAIS / Dirección). Emite códigos de acreditación médica, supervisa la red y gestiona la auditoría global.
  * *(Para más información, consulte [docs/ROLES_CONFANZA_Y_TRIAJE_CCM.md](../docs/ROLES_CONFANZA_Y_TRIAJE_CCM.md))*.
* **Procedimiento de Baja Segura:** La función RPC `eliminar_cuenta_usuario` asegura que al solicitar la eliminación de cuenta, se borren los datos personales, signos vitales, mensajes e historial de forma definitiva, desvinculando la sesión en `auth.users`.

---

## 4. Almacenamiento de Archivos (Supabase Storage)

* **Bucket `avatars`:** Destinado a las fotos de perfil de los usuarios. Las políticas públicas permiten lectura mediante URLs firmadas o públicas, limitando la subida y sustitución únicamente al usuario autenticado propietario del archivo.
