const visionRepo = require('./vision.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const TIPOS_VALIDOS = ['piel', 'garganta'];

const analizarImagen = async (usuarioId, file, tipo) => {
  if (!tipo || !TIPOS_VALIDOS.includes(tipo)) {
    throw new AppError(`El parámetro 'tipo' debe ser uno de: ${TIPOS_VALIDOS.join(', ')}`, 400);
  }

  if (!file) {
    throw new AppError("Se requiere una imagen en el campo 'archivo'", 400);
  }

  try {
    const { data } = await visionRepo.postVision(file.buffer, file.originalname, file.mimetype, tipo);
    const {
      tipo_analisis,
      condicion_detectada,
      confidence_percentage,
      biomark_recommendation,
      risk_level,
      sources
    } = data;

    // NOTA (fuera de alcance de esta Fase 1): este resultado debería
    // persistirse en eventos_medicos + imagenes_medicas para trazabilidad
    // clínica real, no solo quedar auditado.
    await auditService.registrar({
      usuarioId,
      tipoEntidad: 'imagenes_medicas',
      idEntidad: usuarioId,
      accion: 'ANALISIS_IMAGEN',
      detalle: { tipo_analisis, condicion_detectada, risk_level }
    });

    return {
      tipo_analisis,
      condicion_detectada,
      confidence_percentage,
      reply: biomark_recommendation,
      risk_level,
      sources
    };
  } catch (error) {
    if (error instanceof AppError) throw error;
    console.error('Error al comunicarse con el AI Service (vision):', error.message);
    const status = error.response ? error.response.status : 503;
    throw new AppError('El servicio de análisis de imágenes no está disponible temporalmente', status);
  }
};

module.exports = { analizarImagen };
