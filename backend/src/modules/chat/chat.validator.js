const { z } = require('zod');

const sendMessageSchema = z.object({
  message: z.string().trim().min(1, "El campo 'message' es obligatorio"),
  // A partir de esta fase, session_id siempre es un UUID real de
  // sesiones_chat emitido por este backend (ya no el placeholder
  // 'sesion-activa'). Si el cliente manda algo que no sea un UUID
  // válido, es mejor rechazarlo aquí con un 400 claro que dejar que
  // Supabase falle más abajo con un error de sintaxis de tipo uuid.
  session_id: z.string().uuid('session_id debe ser un UUID válido').optional()
});

module.exports = { sendMessageSchema };
