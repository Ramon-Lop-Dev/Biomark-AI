// Coordina transcripción, contexto médico, respuesta y auditoría de voz.
const voiceRepo = require('./voice.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');
const notificationsService = require('../notifications/notifications.service');
const chatService = require('../chat/chat.service');
const chatRepo = require('../chat/chat.repository');
const { mapearNivelRiesgo } = require('../../utils/nivelRiesgo');
const { obtenerContextoClinico } = require('../medical/medicalContext.service');

// Mismo criterio que chat.service.js: estos niveles disparan notificación.
const NIVELES_QUE_NOTIFICAN = ['ALTO', 'CRITICO'];

/**
 * CORRECCIÓN: antes, un mensaje por voz nunca quedaba en sesiones_chat/
 * mensajes_chat (solo en registros_auditoria), así que el expediente
 * conversacional del usuario quedaba incompleto para interacciones por
 * voz. Voice comparte el mismo dominio de sesión que Chat — no tiene
 * tablas propias para esto en el schema — así que reutiliza
 * chatService.resolverSesion / chatRepo.crearMensaje en vez de duplicar
 * esa lógica.
 */
const transcribirYResponder = async (usuarioId, file, sessionId) => {
  if (!file) {
    throw new AppError("Se requiere un archivo de audio en el campo 'archivo'", 400);
  }

  const sesionId = await chatService.resolverSesion(usuarioId, sessionId);

  try {
    const [medicalContext, { data: historial, error: errorHistorial }] = await Promise.all([
      obtenerContextoClinico(usuarioId),
      chatRepo.listarHistorialReciente(sesionId)
    ]);
    if (errorHistorial) console.error('[Voice] No se pudo cargar el historial reciente:', errorHistorial.message);
    const { data } = await voiceRepo.postVoice(
      file.buffer,
      file.originalname,
      file.mimetype,
      medicalContext,
      (historial || []).reverse()
    );
    const { transcription, reply, risk_level, sources } = data;

    const nivelRiesgo = mapearNivelRiesgo(risk_level);

    // El mensaje del "usuario" en este canal es la transcripción del
    // audio (no hay texto crudo que guardar antes de llamar al AI
    // Service, a diferencia de chat.service.js, porque la transcripción
    // solo existe después de la respuesta del AI Service).
    const { error: errorMsgUsuario } = await chatRepo.crearMensaje({
      sesionChatId: sesionId,
      emisor: 'USUARIO',
      mensaje: transcription,
      nivelRiesgo: null
    });

    if (errorMsgUsuario) {
      console.error('[Voice] No se pudo persistir la transcripción del usuario:', errorMsgUsuario.message);
    }

    const { data: mensajeAsistente, error: errorMsgAsistente } = await chatRepo.crearMensaje({
      sesionChatId: sesionId,
      emisor: 'ASISTENTE',
      mensaje: reply,
      nivelRiesgo
    });

    if (errorMsgAsistente) {
      console.error('[Voice] No se pudo persistir la respuesta del asistente:', errorMsgAsistente.message);
    }

    await auditService.registrar({
      usuarioId,
      tipoEntidad: 'mensajes_chat',
      idEntidad: mensajeAsistente ? mensajeAsistente.id : sesionId,
      accion: 'MENSAJE_VOZ',
      detalle: { risk_level, nivel_riesgo: nivelRiesgo }
    });

    if (NIVELES_QUE_NOTIFICAN.includes(nivelRiesgo)) {
      await notificationsService.notificar({
        usuarioId,
        tipo: 'SISTEMA',
        mensaje: 'Detectamos un nivel de riesgo elevado en tu conversación por voz con Biomark AI. Te recomendamos buscar atención médica lo antes posible.'
      });
    }

    return {
      session_id: sesionId,
      transcription,
      reply,
      risk_level,
      sources
    };
  } catch (error) {
    if (error instanceof AppError) throw error;
    console.error('Error al comunicarse con el AI Service (voice):', error.message);
    const status = error.response ? error.response.status : 503;
    throw new AppError('El servicio de voz no está disponible temporalmente', status);
  }
};

const sintetizarVoz = async (text) => {
  try {
    const { data } = await voiceRepo.postSynthesize(text);
    return data; // audio binario (arraybuffer, se envía tal cual al cliente)
  } catch (error) {
    if (error instanceof AppError) throw error;
    console.error('Error al comunicarse con el AI Service (synthesize):', error.message);
    const status = error.response ? error.response.status : 503;
    throw new AppError('El servicio de síntesis de voz no está disponible temporalmente', status);
  }
};

module.exports = { transcribirYResponder, sintetizarVoz };
