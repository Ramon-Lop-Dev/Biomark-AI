// Coordina consentimiento idempotente y auditoría de privacidad.
const repository = require('./consent.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const listar = async (usuarioId) => {
  const { data, error } = await repository.listar(usuarioId);
  if (error) throw new AppError('No se pudieron obtener los consentimientos', 500);
  return data || [];
};

const guardar = async (usuarioId, tipo, otorgado) => {
  const existente = await repository.buscar(usuarioId, tipo);
  if (existente.error) throw new AppError('No se pudo consultar el consentimiento', 500);
  const resultado = existente.data
    ? await repository.actualizar(existente.data.id, otorgado)
    : await repository.crear(usuarioId, tipo, otorgado);
  if (resultado.error) throw new AppError('No se pudo guardar el consentimiento', 500);
  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'consentimientos',
    idEntidad: resultado.data.id,
    accion: otorgado ? 'CONSENTIMIENTO_OTORGADO' : 'CONSENTIMIENTO_REVOCADO',
    detalle: { tipo_consentimiento: tipo }
  });
  return resultado.data;
};

module.exports = { listar, guardar };