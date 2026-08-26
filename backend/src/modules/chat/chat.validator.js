const { z } = require('zod');

const sendMessageSchema = z.object({
  message: z.string().trim().min(1, "El campo 'message' es obligatorio"),
  // A partir de esta fase, session_id siempre es un UUID real de
  // sesiones_chat emitido por este backend (ya no el placeholder
  // 'sesion-activa'). Si el cliente manda algo que no sea un UUID
  // válido, es mejor rechazarlo aquí con un 400 claro que dejar que
  // Supabase falle más abajo con un error de sintaxis de tipo uuid.
  session_id: z.string().uuid('session_id debe ser un UUID válido').optional(),
  // Opcionales: si el cliente los manda, el AI Service busca el centro de
  // salud real más cercano y lo agrega a la respuesta (ver ai-service/main.py,
  // endpoint /chat). Antes de esta corrección, chat.repository.postChat()
  // nunca los reenviaba, así que esta función de GIS-en-chat era inalcanzable.
  latitude: z.number().min(-90).max(90).optional(),
  longitude: z.number().min(-180).max(180).optional()
});

module.exports = { sendMessageSchema };
