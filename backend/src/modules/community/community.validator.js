const { z } = require('zod');

const createEventSchema = z.object({
  titulo: z.string().trim().min(1, 'El título es obligatorio'),
  descripcion: z.string().trim().max(2000).optional(),
  fecha_evento: z.string().datetime({ offset: true, message: 'fecha_evento debe ser una fecha/hora ISO 8601 válida' }),
  ubicacion: z.string().trim().max(500).optional()
});

const createReportSchema = z.object({
  case_count: z.number().int().positive().default(1).optional(),
  description: z.string().trim().max(2000).optional(),
  latitude: z.number().min(-90).max(90),
  longitude: z.number().min(-180).max(180),
  zona_riesgo_id: z.string().uuid('zona_riesgo_id debe ser un UUID válido').optional()
});

module.exports = { createEventSchema, createReportSchema };
