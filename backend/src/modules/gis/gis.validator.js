// Valida coordenadas y radios solicitados al módulo GIS.
const { z } = require('zod');

// Los query params de Express siempre llegan como string, por eso se
// usa z.coerce para convertirlos a number antes de validar el rango.
const nearbySchema = z.object({
  latitude: z.coerce.number().min(-90).max(90),
  longitude: z.coerce.number().min(-180).max(180),
  radius_km: z.coerce.number().positive().max(200).default(15).optional()
});

const bboxSchema = z.object({
  min_lon: z.coerce.number().min(-180).max(180),
  min_lat: z.coerce.number().min(-90).max(90),
  max_lon: z.coerce.number().min(-180).max(180),
  max_lat: z.coerce.number().min(-90).max(90),
  nivel_min: z.coerce.number().int().min(1).max(3).default(1),
  zoom: z.coerce.number().min(0).max(24).default(15)
}).superRefine((value, context) => {
  if (value.min_lon >= value.max_lon) {
    context.addIssue({ code: 'custom', path: ['min_lon'], message: 'min_lon debe ser menor que max_lon' });
  }
  if (value.min_lat >= value.max_lat) {
    context.addIssue({ code: 'custom', path: ['min_lat'], message: 'min_lat debe ser menor que max_lat' });
  }
});

const centersNearbySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lon: z.coerce.number().min(-180).max(180),
  servicio: z.string().trim().min(1).max(80).optional(),
  edad: z.coerce.number().int().min(0).max(120).optional(),
  nivel_min: z.coerce.number().int().min(1).max(3).default(1),
  radio_m: z.coerce.number().int().positive().max(200000).default(5000),
  limite: z.coerce.number().int().positive().max(100).default(10)
});

const centerIdSchema = z.object({
  id: z.string().uuid('id debe ser un UUID válido')
});

module.exports = { nearbySchema, bboxSchema, centersNearbySchema, centerIdSchema };