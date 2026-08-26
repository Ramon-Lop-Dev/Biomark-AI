const { z } = require('zod');

// Valores del enum tipo_recordatorio en Postgres.
const TIPOS_RECORDATORIO = ['MEDICAMENTO', 'CITA', 'VACUNA', 'CONTROL'];

const addReminderSchema = z.object({
  titulo: z.string().trim().min(1, 'El título es obligatorio'),
  descripcion: z.string().trim().max(2000).optional(),
  fecha_programada: z.string().datetime({ offset: true, message: 'fecha_programada debe ser una fecha/hora ISO 8601 válida' }),
  tipo: z.enum(TIPOS_RECORDATORIO, {
    errorMap: () => ({ message: `tipo debe ser uno de: ${TIPOS_RECORDATORIO.join(', ')}` })
  })
});

module.exports = { addReminderSchema, TIPOS_RECORDATORIO };
