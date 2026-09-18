// Servicio de recomendaciones de salud con auditoría clínica y operativa.
const recommendationsRepo = require('./recommendations.repository');
const auditService = require('../audit/audit.service');
const AppError = require('../../utils/AppError');

const getRecommendations = async (filtros) => {
  const { data, error } = await recommendationsRepo.listarRecomendaciones(filtros);
  if (error) {
    throw new AppError('Error al obtener recomendaciones de salud', 500);
  }
  return data;
};

const getRecommendationById = async (id) => {
  const { data, error } = await recommendationsRepo.obtenerRecomendacionPorId(id);
  if (error || !data) {
    throw new AppError('Recomendación no encontrada', 404);
  }
  return data;
};

const createRecommendation = async (usuarioId, payload) => {
  const { data, error } = await recommendationsRepo.crearRecomendacion(usuarioId, payload);
  if (error || !data) {
    throw new AppError('Error al crear la recomendación de salud', 500);
  }

  // Auditoría operativa para validar trazabilidad médica
  try {
    await auditService.registrar({
      usuarioId,
      tipoEntidad: 'recomendaciones_salud',
      idEntidad: data.id,
      accion: 'CREACION',
      detalle: {
        titulo: data.titulo,
        categoria: data.categoria,
        normativa_minsa: data.normativa_minsa
      }
    });
  } catch (err) {
    console.warn('[Recomendaciones] No se pudo auditar la creación:', err.message);
  }

  return data;
};

const updateRecommendation = async (usuarioId, id, payload) => {
  const { data, error } = await recommendationsRepo.actualizarRecomendacion(id, payload);
  if (error || !data) {
    throw new AppError('Error al actualizar la recomendación o no encontrada', 404);
  }

  try {
    await auditService.registrar({
      usuarioId,
      tipoEntidad: 'recomendaciones_salud',
      idEntidad: data.id,
      accion: 'ACTUALIZACION',
      detalle: {
        titulo: data.titulo,
        categoria: data.categoria
      }
    });
  } catch (err) {
    console.warn('[Recomendaciones] No se pudo auditar la actualización:', err.message);
  }

  return data;
};

const deleteRecommendation = async (usuarioId, id) => {
  await recommendationsRepo.eliminarRecomendacion(id);

  try {
    await auditService.registrar({
      usuarioId,
      tipoEntidad: 'recomendaciones_salud',
      idEntidad: id,
      accion: 'ELIMINACION',
      detalle: { id }
    });
  } catch (err) {
    console.warn('[Recomendaciones] No se pudo auditar la eliminación:', err.message);
  }

  return { message: 'Recomendación eliminada correctamente' };
};

module.exports = {
  getRecommendations,
  getRecommendationById,
  createRecommendation,
  updateRecommendation,
  deleteRecommendation
};
