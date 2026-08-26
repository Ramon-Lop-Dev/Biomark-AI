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

    // CORRECCIÓN: antes este resultado solo quedaba en registros_auditoria
    // (no consultable como parte del expediente clínico). Ahora se
    // persiste en eventos_medicos + imagenes_medicas, que es para lo que
    // existen esas tablas. Si algo de esta cadena falla (subida a
    // Storage, o cualquiera de los dos inserts), se loguea y se sigue: el
    // usuario ya recibió su resultado clínico del AI Service y eso nunca
    // debe perderse por un problema de persistencia secundaria.
    let eventoMedicoId = null;
    try {
      const { data: evento, error: errorEvento } = await visionRepo.crearEventoMedico(
        usuarioId,
        `Análisis de imagen (${tipo}): ${condicion_detectada || 'sin condición detectada'}`
      );

      if (errorEvento || !evento) {
        throw new Error(errorEvento ? errorEvento.message : 'No se pudo crear el evento médico');
      }
      eventoMedicoId = evento.id;

      const { url, error: errorSubida } = await visionRepo.subirImagen(
        usuarioId,
        file.buffer,
        file.originalname,
        file.mimetype
      );

      if (errorSubida || !url) {
        throw new Error(errorSubida ? errorSubida.message : 'No se pudo subir la imagen a Storage');
      }

      const { error: errorImagen } = await visionRepo.crearImagenMedica(eventoMedicoId, {
        url_imagen: url,
        clasificacion: condicion_detectada || null,
        confianza: typeof confidence_percentage === 'number' ? confidence_percentage : null
      });

      if (errorImagen) {
        throw new Error(errorImagen.message);
      }
    } catch (errorPersistencia) {
      console.error('[Vision] No se pudo persistir el resultado clínico:', errorPersistencia.message);
    }

    await auditService.registrar({
      usuarioId,
      tipoEntidad: 'imagenes_medicas',
      idEntidad: eventoMedicoId || usuarioId,
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
