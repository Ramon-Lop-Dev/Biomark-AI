// Coordina el seguimiento de evolución y su auditoría.
const repository = require('./progress.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const getProgress = async (usuarioId) => {
  const { data, error } = await repository.listarPorUsuario(usuarioId);
  if (error) throw new AppError('Error al obtener el seguimiento de salud', 500);
  return data;
};

const createProgress = async (usuarioId, payload) => {
  const { data, error } = await repository.crear(usuarioId, payload);
  if (error) throw new AppError('Error al registrar la evolución', 500);

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'seguimiento_salud',
    idEntidad: data.id,
    accion: 'CREACION',
    detalle: { sintoma: data.sintoma, estado: data.estado }
  });

  return data;
};

module.exports = { getProgress, createProgress };
