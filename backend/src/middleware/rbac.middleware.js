const AppError = require('../utils/AppError');

/**
 * Middleware factory de control de acceso por rol (RBAC).
 * Debe usarse SIEMPRE después de verifyToken, porque depende de
 * req.usuarioRol (establecido ahí a partir de public.usuarios.rol).
 *
 * Uso: router.post('/', verifyToken, requireRole('ADMIN', 'TRABAJADOR_SALUD'), controller)
 */
const requireRole = (...rolesPermitidos) => {
  return (req, res, next) => {
    if (!req.usuarioRol) {
      return next(new AppError('No se pudo determinar el rol del usuario', 401));
    }

    if (!rolesPermitidos.includes(req.usuarioRol)) {
      return next(new AppError('No tienes permisos para realizar esta acción', 403));
    }

    next();
  };
};

module.exports = { requireRole };
