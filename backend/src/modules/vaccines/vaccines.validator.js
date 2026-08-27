// Valida aplicaciones y fechas de vacunación.
const { z } = require('zod');

const addVaccineSchema = z.object({
  nombre_vacuna: z.string().trim().min(1, 'El nombre de la vacuna es obligatorio'),
  fecha_aplicacion: z.string().date('fecha_aplicacion debe tener formato YYYY-MM-DD'),
  numero_dosis: z.number().int().positive().default(1).optional(),
  fecha_proxima_dosis: z.string().date('fecha_proxima_dosis debe tener formato YYYY-MM-DD').optional()
});

module.exports = { addVaccineSchema };
