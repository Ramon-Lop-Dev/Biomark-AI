const AppError = require('../utils/AppError');

/**
 * Middleware factory de validación de body con schemas de Zod.
 * Reemplaza los `if (!campo) return res.status(400)...` manuales y
 * dispersos que había en cada controller.
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

module.exports = { validate };
