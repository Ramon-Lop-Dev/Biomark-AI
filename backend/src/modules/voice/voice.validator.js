// Valida solicitudes de síntesis de voz.
const { z } = require('zod');

const synthesizeSchema = z.object({
  text: z.string().trim().min(1, "El campo 'text' es obligatorio")
});

module.exports = { synthesizeSchema };
