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
| `migrations/010_eliminar_cuenta_usuario.sql` | Procedimiento almacenado `dar_de_baja_usuario(user_id)` para borrado seguro en cascada y revocación de accesos. |
| `migrations/011_recordatorios_frecuencia.sql` | Parámetros de frecuencia horaria y diaria para tomas farmacológicas. |
| `migrations/012_recordatorios_aviso_previo.sql` | Ventanas de aviso preventivo previo a la hora de medicación. |
| `migrations/013_recomendaciones_salud.sql` | Esquema de pautas MINSA (`recomendaciones_salud`), validaciones de categorías sanitarias, enlaces normativos y semillas oficiales de prevención. |

---

## 2. Semillas de Datos (Seeds)

Una vez ejecutadas las migraciones base, se deben cargar los catálogos sanitarios:

1. **Catálogo de Unidades de Salud:**
   * Ejecutar `seeds/seed_centros_salud_managua.sql` o `seeds/013_centros_salud_enriquecidos.sql` para poblar la red de hospitales, centros de salud y puestos médicos del departamento de Managua con coordenadas georreferenciadas.
2. **Pautas Sanitarias Oficiales:**
   * La migración `013_recomendaciones_salud.sql` incluye automáticamente las semillas oficiales del MINSA para Dengue (Normativa 004), Olas de Calor, Salud Cardiovascular, Adherencia al Tratamiento, Diabetes (Normativa 078) y Salud Respiratoria (Normativa 028).

---

## 3. Políticas de Seguridad (RLS) y Roles

* **Row Level Security (RLS):** Cada tabla posee políticas estrictas. Los pacientes únicamente pueden leer o modificar sus propios registros médicos, chats y signos vitales mediante su `auth.uid()`.
* **Control de Acceso por Roles (RBAC):**
  * `USUARIO`: Acceso a su perfil, chat clínico, registro de pulso y consulta de recomendaciones.
  * `PROMOTOR` / `TRABAJADOR_SALUD`: Permiso adicional para registrar y gestionar pautas comunitarias validadas y eventos de salud en su sector.
  * `ADMIN`: Acceso administrativo completo, aprobación de roles y supervisión de auditoría.
* **Procedimiento de Baja Segura:** La función RPC `dar_de_baja_usuario` asegura que al solicitar la eliminación de cuenta, se borren los datos personales, signos vitales, mensajes e historial de forma definitiva, desvinculando la sesión en `auth.users`.

---

## 4. Almacenamiento de Archivos (Supabase Storage)

* **Bucket `avatars`:** Destinado a las fotos de perfil de los usuarios. Las políticas públicas permiten lectura mediante URLs firmadas o públicas, limitando la subida y sustitución únicamente al usuario autenticado propietario del archivo.
