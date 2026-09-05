const { z } = require('zod');

const DATE_PATTERN = /^\d{4}-\d{2}-\d{2}$/;
const PERIODICIDADES = ['SEMANAL', 'QUINCENAL', 'MENSUAL', 'TRIMESTRAL', 'SEMESTRAL', 'ANUAL'];

const createGoalSchema = z.object({
  titulo: z.string().trim().min(1).max(160),
  descripcion: z.string().trim().max(2000).optional(),
  periodicidad: z.enum(PERIODICIDADES),
  fecha_inicio: z.string().regex(DATE_PATTERN, 'fecha_inicio debe tener formato YYYY-MM-DD'),
  fecha_fin: z.string().regex(DATE_PATTERN, 'fecha_fin debe tener formato YYYY-MM-DD')
});

const updateMilestoneSchema = z.object({
  completado: z.boolean()
});

module.exports = { createGoalSchema, updateMilestoneSchema, PERIODICIDADES };