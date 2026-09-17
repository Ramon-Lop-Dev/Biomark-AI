// Valida fechas, tipos y estados de recordatorios.
const { z } = require('zod');

// Valores del enum tipo_recordatorio en Postgres.
const TIPOS_RECORDATORIO = ['MEDICAMENTO', 'CITA', 'VACUNA', 'CONTROL'];

// Valores del enum estado_recordatorio en Postgres.
const ESTADOS_RECORDATORIO = ['PENDIENTE', 'ENVIADO', 'COMPLETADO', 'CANCELADO'];

// Valores del enum frecuencia_recordatorio en Postgres.
const FRECUENCIAS_RECORDATORIO = ['UNA_VEZ', 'HORARIA', 'DIARIA', 'SEMANAL', 'QUINCENAL', 'MENSUAL'];

// Opciones de aviso previo (anticipación de notificación).
const AVISOS_PREVIOS = ['AL_MOMENTO', '1_HORA_ANTES', '1_DIA_ANTES', '2_DIAS_ANTES'];

const addReminderSchema = z.object({
  titulo: z.string().trim().min(1, 'El título es obligatorio'),
  descripcion: z.string().trim().max(2000).optional(),
  fecha_programada: z.string().datetime({ offset: true, message: 'fecha_programada debe ser una fecha/hora ISO 8601 válida' }),
  tipo: z.enum(TIPOS_RECORDATORIO, {
    error: `tipo debe ser uno de: ${TIPOS_RECORDATORIO.join(', ')}`
  }),
  frecuencia: z.enum(FRECUENCIAS_RECORDATORIO, {
    error: `frecuencia debe ser una de: ${FRECUENCIAS_RECORDATORIO.join(', ')}`
  }).default('UNA_VEZ'),
  aviso_previo: z.enum(AVISOS_PREVIOS, {
    error: `aviso_previo debe ser uno de: ${AVISOS_PREVIOS.join(', ')}`
  }).default('AL_MOMENTO')
});

const updateReminderStatusSchema = z.object({
  estado: z.enum(ESTADOS_RECORDATORIO, {
    error: `estado debe ser uno de: ${ESTADOS_RECORDATORIO.join(', ')}`
  })
});

module.exports = {
  addReminderSchema,
  updateReminderStatusSchema,
  TIPOS_RECORDATORIO,
  ESTADOS_RECORDATORIO,
  FRECUENCIAS_RECORDATORIO,
  AVISOS_PREVIOS
};
