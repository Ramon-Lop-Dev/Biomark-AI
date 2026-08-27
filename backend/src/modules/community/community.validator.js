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

// Valores del enum estado_reporte_comunitario en Postgres, salvo
// PENDIENTE_VALIDACION: ese es el estado inicial (default de la tabla,
// ver community.repository.crearReporte) y nunca es un valor válido de
// destino aquí — este endpoint existe justamente para SALIR de él.
const ESTADOS_VALIDACION_REPORTE = ['VALIDADO', 'DESCARTADO'];

const updateReportStatusSchema = z.object({
  estado: z.enum(ESTADOS_VALIDACION_REPORTE, {
    error: `estado debe ser uno de: ${ESTADOS_VALIDACION_REPORTE.join(', ')}`
  })
});

module.exports = {
  createEventSchema,
  createReportSchema,
  updateReportStatusSchema,
  ESTADOS_VALIDACION_REPORTE
};
