// Centraliza la configuración y validación del acceso al AI Service.
const AppError = require('../utils/AppError');

const AI_SERVICE_URL = process.env.AI_SERVICE_URL;
const AI_SERVICE_INTERNAL_KEY = process.env.AI_SERVICE_INTERNAL_KEY;

/**
 * Debe llamarse al inicio de cada función de repository que hable con el
 * AI Service (chat, voice, vision), para fallar rápido con un mensaje
 * claro si falta configuración en el .env, en vez de que axios truene
 * con una baseURL vacía o indefinida.
 */
const asegurarConfiguracion = () => {
  if (!AI_SERVICE_URL || !AI_SERVICE_INTERNAL_KEY) {
    throw new AppError('Configuración del servicio de IA incompleta en el servidor', 500);
  }
};

module.exports = { AI_SERVICE_URL, AI_SERVICE_INTERNAL_KEY, asegurarConfiguracion };
