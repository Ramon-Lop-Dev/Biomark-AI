// Protege endpoints internos invocados por n8n mediante secreto compartido.
const AppError = require('../utils/AppError');

const verifyInternalWebhook = (req, res, next) => {
  const secret = process.env.N8N_WEBHOOK_SECRET;
  if (!secret || req.headers['x-webhook-secret'] !== secret) {
    return next(new AppError('Acceso interno no autorizado', 401));
  }
  return next();
};

module.exports = { verifyInternalWebhook };