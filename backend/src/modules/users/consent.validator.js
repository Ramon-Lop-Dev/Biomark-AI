// Valida los tipos y estados de consentimiento permitidos.
const { z } = require('zod');

const consentSchema = z.object({
  tipo_consentimiento: z.enum(['CONTEXTO_MEDICO_IA', 'UBICACION', 'NOTIFICACIONES_PUSH']),
  otorgado: z.boolean()
});

module.exports = { consentSchema };