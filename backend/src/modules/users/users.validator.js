const { z } = require('zod');

// Valores del enum sexo_biologico en Postgres.
const SEXOS_BIOLOGICOS = ['MASCULINO', 'FEMENINO', 'OTRO', 'NO_ESPECIFICA'];

// Actualización parcial de "perfiles": todos los campos son opcionales
// (PATCH-like), pero el body no puede llegar vacío — si no, no hay nada
// que actualizar y es mejor rechazarlo explícitamente que hacer un
// UPDATE sin cambios contra Supabase.
const updateProfileSchema = z
  .object({
    nombre_completo: z.string().trim().min(1, 'nombre_completo no puede estar vacío').optional(),
    fecha_nacimiento: z.string().date('fecha_nacimiento debe tener formato YYYY-MM-DD').optional(),
    sexo: z.enum(SEXOS_BIOLOGICOS, {
      errorMap: () => ({ message: `sexo debe ser uno de: ${SEXOS_BIOLOGICOS.join(', ')}` })
    }).optional(),
    telefono: z.string().trim().max(30).optional(),
    direccion: z.string().trim().max(500).optional(),
    municipio: z.string().trim().max(200).optional()
  })
  .refine((body) => Object.keys(body).length > 0, {
    message: 'Debes enviar al menos un campo para actualizar'
  });

module.exports = { updateProfileSchema, SEXOS_BIOLOGICOS };
