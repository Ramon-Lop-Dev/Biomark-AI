// Valida estados de evolución aportados por el usuario.
const { z } = require('zod');

const createProgressSchema = z.object({
  sintoma: z.string().trim().min(1).max(160),
  estado: z.enum(['MEJORO', 'IGUAL', 'EMPEORO', 'NO_SEGURO']),
  intensidad: z.coerce.number().int().min(0).max(10).optional(),
  notas: z.string().trim().max(2000).optional()
});

module.exports = { createProgressSchema };
