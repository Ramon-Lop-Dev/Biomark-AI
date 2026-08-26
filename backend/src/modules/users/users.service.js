const usersRepo = require('./users.repository');
const AppError = require('../../utils/AppError');

const getProfile = async (usuarioId) => {
  const { data, error } = await usersRepo.findUsuarioConPerfil(usuarioId);

  if (error) {
    throw new AppError('No se pudo obtener el perfil', 500);
  }

  return data;
};

module.exports = { getProfile };
