// Valida tokens y plataformas de dispositivos push.
const { z } = require('zod');

const pushTokenSchema = z.object({
  fcm_token: z.string().trim().min(20).max(4096),
  plataforma: z.enum(['ANDROID', 'IOS', 'WEB'])
});

module.exports = { pushTokenSchema };