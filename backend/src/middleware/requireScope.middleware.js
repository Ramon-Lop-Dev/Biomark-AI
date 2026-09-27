// Restringe el acceso operativo de salud al centro de salud del usuario autenticado.
const AppError = require('../utils/AppError');

/**
 * Middleware de control de ámbito territorial (scoping por centro de salud).
 * Debe usarse SIEMPRE después de verifyToken.
 *
 * Reglas:
 * - ADMIN: acceso irrestricto (req.scopeCentroSaludId = null).
 * - TRABAJADOR_SALUD / PROMOTOR / LIDER_COMUNITARIO: exige que el usuario tenga
 *   un centro_salud_id asignado en su cuenta y lo inyecta en req.scopeCentroSaludId.
 */
const requireScope = (req, res, next) => {
  if (!req.usuarioRol) {
    return next(new AppError('No se pudo determinar el rol del usuario', 401));
  }

  if (req.usuarioRol === 'ADMIN') {
    req.scopeCentroSaludId = null;
    return next();
  }

  const centroId = req.centroSaludId || req.usuario?.centro_salud_id;

  if (!centroId) {
    return next(new AppError('Tu cuenta de promotor o personal de salud no tiene un centro de salud asignado.', 403));
  }

  req.scopeCentroSaludId = centroId;
  next();
};

module.exports = { requireScope };
