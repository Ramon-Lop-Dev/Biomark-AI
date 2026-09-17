// Publica eventos autenticados hacia n8n self-hosted.
const AppError = require('../utils/AppError');
const axios = require('axios');

// Cliente de integración con n8n.
// Utilizado por reminders.service.js para publicar eventos cuando un
// recordatorio vence (evento 'recordatorio.disparado').
const N8N_WEBHOOK_URL = process.env.N8N_WEBHOOK_URL;
const N8N_WEBHOOK_SECRET = process.env.N8N_WEBHOOK_SECRET;

/**
 * Debe llamarse al inicio de reminders.repository.postWebhook() (Fase 7),
 * para fallar rápido con un mensaje claro si falta configuración en el
 * .env, en vez de que axios truene con una baseURL vacía o indefinida.
 */
const asegurarConfiguracion = () => {
  if (!N8N_WEBHOOK_URL) {
    throw new AppError('Configuración del webhook de n8n incompleta en el servidor', 500);
  }
};

const publicarEvento = async (evento, payload) => {
  asegurarConfiguracion();
  return axios.post(N8N_WEBHOOK_URL, { evento, ...payload }, {
    headers: {
      'Content-Type': 'application/json',
      ...(N8N_WEBHOOK_SECRET ? { 'X-Webhook-Secret': N8N_WEBHOOK_SECRET } : {})
    },
    timeout: 10000
  });
};

module.exports = { N8N_WEBHOOK_URL, N8N_WEBHOOK_SECRET, asegurarConfiguracion, publicarEvento };
