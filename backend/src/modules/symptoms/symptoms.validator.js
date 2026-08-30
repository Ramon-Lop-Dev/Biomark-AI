// Valida nombres y registros de síntomas.
const { z } = require('zod');

const addSymptomSchema = z.object({
  symptom: z.string().trim().min(1, 'El nombre del síntoma es obligatorio'),
  temperature: z.number().min(30).max(45).optional(),
  blood_pressure: z.string().trim().max(20).optional(),
  notes: z.string().trim().max(2000).optional(),
  photo_url: z.string().url('photo_url debe ser una URL válida').optional(),
  date: z.string().datetime({ offset: true }).optional()
});

module.exports = { addSymptomSchema };
