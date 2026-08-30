// Coordina dispositivos push y su trazabilidad de auditoría.
const repository = require('./push.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const registrar = async (usuarioId, payload) => {
  const { data, error } = await repository.registrar(usuarioId, payload);
  if (error) throw new AppError('No se pudo registrar el dispositivo', 500);
  await auditService.registrar({ usuarioId, tipoEntidad: 'dispositivos_push', idEntidad: data.id, accion: 'REGISTRO_TOKEN', detalle: { plataforma: data.plataforma } });
  return data;
};

const eliminar = async (usuarioId, token) => {
  const { error } = await repository.eliminar(usuarioId, token);
  if (error) throw new AppError('No se pudo eliminar el dispositivo', 500);
};

module.exports = { registrar, eliminar };