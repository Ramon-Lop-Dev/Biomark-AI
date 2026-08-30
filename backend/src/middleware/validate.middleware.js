// Valida y normaliza cuerpos y parámetros antes de llegar al controlador.
const AppError = require('../utils/AppError');

/**
 * Middleware factory de validación de body con schemas de Zod.

 *
 * Uso: router.post('/', validate(miSchema), controller)
 *
 * Si la validación pasa, req.body se reemplaza por los datos ya
 * parseados/saneados por Zod (con tipos correctos, defaults aplicados, etc.).
 */
const validate = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.body);

  if (!result.success) {
    const mensaje = result.error.issues
      .map((issue) => `${issue.path.join('.') || 'body'}: ${issue.message}`)
      .join('; ');
    return next(new AppError(`Datos inválidos: ${mensaje}`, 400));
  }

  req.body = result.data;
  next();
};

/**
 * Igual que validate(), pero para query params (?latitude=..&longitude=..).
 * Necesaria aparte porque los query params de Express siempre llegan como
 * string — el schema debe usar z.coerce para los campos numéricos.
 */
const validateQuery = (schema) => (req, res, next) => {
  const result = schema.safeParse(req.query);

  if (!result.success) {
    const mensaje = result.error.issues
      .map((issue) => `${issue.path.join('.') || 'query'}: ${issue.message}`)
      .join('; ');
    return next(new AppError(`Parámetros inválidos: ${mensaje}`, 400));
  }

  req.query = result.data;
  next();
};

module.exports = { validate, validateQuery };
