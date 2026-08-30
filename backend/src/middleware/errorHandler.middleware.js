// Convierte errores de aplicación en respuestas HTTP seguras.
const AppError = require('../utils/AppError');

/**
 * Manejador de errores centralizado. Debe registrarse en app.js DESPUÉS
 * de montar todas las rutas (Express lo reconoce como error handler por
 * tener 4 parámetros).
 *
 * Regla de seguridad: nunca se expone error.message de un error no
 * controlado (p. ej. un error crudo de Postgres/Supabase) al cliente,
 * porque puede filtrar nombres de columnas, constraints o detalles
 * internos de la base de datos. Solo se exponen mensajes de AppError,
 * que son siempre mensajes de negocio escritos a propósito por nosotros.
 */
const errorHandler = (err, req, res, next) => {
  if (err instanceof AppError) {
    return res.status(err.statusCode).json({
      error: err.message,
      code: err.code
    });
  }

  console.error('[ErrorHandler] Error no controlado:', err);

  return res.status(500).json({
    error: 'Ocurrió un error interno en el servidor',
    code: '500'
  });
};

module.exports = errorHandler;
