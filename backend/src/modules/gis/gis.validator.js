const { z } = require('zod');

// Los query params de Express siempre llegan como string, por eso se
// usa z.coerce para convertirlos a number antes de validar el rango.
const nearbySchema = z.object({
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  radius_km: z.coerce.number().positive().max(200).default(15).optional()
});

module.exports = { nearbySchema };