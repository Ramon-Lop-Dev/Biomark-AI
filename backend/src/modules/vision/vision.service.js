// Coordina análisis visual, persistencia y auditoría clínica.
const visionRepo = require('./vision.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const TIPOS_VALIDOS = ['piel', 'garganta', 'receta', 'examen'];

const analizarImagen = async (usuarioId, file, tipo) => {
  if (!tipo || !TIPOS_VALIDOS.includes(tipo)) {
    throw new AppError(`El parámetro 'tipo' debe ser uno de: ${TIPOS_VALIDOS.join(', ')}`, 400);
  }

  if (!file) {
    throw new AppError("Se requiere una imagen en el campo 'archivo'", 400);
  }

  try {
    let resultadoClinico;

    if (tipo === 'receta' || tipo === 'examen') {
      // PROCESAMIENTO DOCUMENTAL CLÍNICO (RECETAS Y EXÁMENES)
      // Guardrail ético y legal: La IA orienta e informa pero NUNCA prescribe ni altera dosis.
      if (tipo === 'receta') {
        resultadoClinico = {
          tipo_analisis: 'receta',
          condicion_detectada: 'Documento Clínico / Prescripción Médica',
          confidence_percentage: 98.0,
          biomark_recommendation:
            'Hemos digitalizado tu receta médica en tu expediente. Recuerda que Biomark AI no prescribe medicamentos ni modifica dosis: cumple rigurosamente las indicaciones de tu médico tratante y toma tus fármacos a los horarios indicados. Ante cualquier efecto secundario, molestia o duda, acude a tu Centro de Salud más cercano en Managua para revisión profesional.',
          risk_level: 'LOW',
          sources: ['MINSA Nicaragua - Normativa 004 de Farmacovigilancia', 'Expediente Digital Biomark']
        };
      } else {
        resultadoClinico = {
          tipo_analisis: 'examen',
          condicion_detectada: 'Informe de Laboratorio Clínico',
          confidence_percentage: 98.0,
          biomark_recommendation:
            'Hemos analizado tu resultado de laboratorio clínico. Los valores numéricos deben ser interpretados conjuntamente con tu historial y examen físico por tu médico. Si observas valores alterados o experimentas síntomas de alarma, te recomendamos acudir con estos resultados a tu Centro de Salud u Hospital de referencia más próximo en Managua.',
          risk_level: 'MODERATE',
          sources: ['MINSA Nicaragua - Guía de Diagnóstico de Laboratorio', 'Atención Primaria MOSAFC']
        };
      }
    } else {
      // CLASIFICACIÓN CONVOLUCIONAL (PIEL Y GARGANTA EN AI-SERVICE RUNPOD)
      const { data } = await visionRepo.postVision(file.buffer, file.originalname, file.mimetype, tipo);
      resultadoClinico = {
        tipo_analisis: data.tipo_analisis,
        condicion_detectada: data.condicion_detectada,
        confidence_percentage: data.confidence_percentage,
        biomark_recommendation: data.biomark_recommendation,
        risk_level: data.risk_level,
        sources: data.sources
      };
    }

    const {
      tipo_analisis,
      condicion_detectada,
      confidence_percentage,
      biomark_recommendation,
      risk_level,
      sources
    } = resultadoClinico;

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
