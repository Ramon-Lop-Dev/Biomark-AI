const { z } = require('zod');

const sendMessageSchema = z.object({
  message: z.string().trim().min(1, "El campo 'message' es obligatorio"),
  session_id: z.string().trim().optional()
});

module.exports = { sendMessageSchema };
