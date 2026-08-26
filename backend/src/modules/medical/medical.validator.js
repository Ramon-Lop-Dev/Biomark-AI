const { z } = require('zod');

const createMedicalRecordSchema = z.object({
  nombre_condicion: z.string().trim().min(1, "El campo 'nombre_condicion' es obligatorio"),
  fecha_diagnostico: z.string().date('fecha_diagnostico debe tener formato YYYY-MM-DD').optional(),
  notas: z.string().trim().max(2000).optional()
});

module.exports = { createMedicalRecordSchema };
