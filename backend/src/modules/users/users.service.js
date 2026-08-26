const usersRepo = require('./users.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const getProfile = async (usuarioId) => {
  const { data, error } = await usersRepo.findUsuarioConPerfil(usuarioId);

  if (error) {
    throw new AppError('No se pudo obtener el perfil', 500);
  }

  return data;
};

const updateProfile = async (usuarioId, cambios) => {
  const { data, error } = await usersRepo.actualizarPerfil(usuarioId, cambios);

  if (error) {
    throw new AppError('No se pudo actualizar el perfil', 500);
  }

  // No debería pasar en condiciones normales (perfiles se crea junto con
  // usuarios en el registro), pero si la fila de perfiles no existe,
  // el UPDATE no afecta ninguna fila y Supabase devuelve data = null.
  if (!data) {
    throw new AppError('No se encontró un perfil asociado a este usuario', 404);
  }

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'perfiles',
    idEntidad: usuarioId,
    accion: 'ACTUALIZACION',
    detalle: { campos_actualizados: Object.keys(cambios) }
  });

  // Se devuelve la misma forma que getProfile (usuario + perfil anidado)
  // para que el cliente no tenga que manejar dos formatos de respuesta
  // distintos entre GET y PUT.
  return getProfile(usuarioId);
};

module.exports = { getProfile, updateProfile };
