/**
 * Error operacional (esperado) de la aplicación.
 * Los servicios deben lanzar AppError en vez de Error genérico cuando el
 * fallo es de negocio (validación, credenciales, permisos, etc.), para que
 * el errorHandler centralizado sepa que es seguro exponer el mensaje al
 * cliente. Cualquier otro Error se trata como no controlado y NO se expone.
 */
class AppError extends Error {
  constructor(message, statusCode = 500, code = null) {
    super(message);
    this.statusCode = statusCode;
    this.code = code || String(statusCode);
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

module.exports = AppError;
