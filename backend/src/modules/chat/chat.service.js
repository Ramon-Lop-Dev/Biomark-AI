const chatRepo = require('./chat.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const enviarMensaje = async (usuarioId, message, sessionId) => {
  try {
    const { data } = await chatRepo.postChat(message);
    const { reply, risk_level, sources } = data;

    // NOTA (Fase 3, fuera de alcance de esta Fase 1): esta interacción
    // debería persistirse en sesiones_chat/mensajes_chat, y si risk_level
    // es ALTO/CRITICO debería disparar una notificación. Por ahora solo
    // dejamos constancia en registros_auditoria de que ocurrió.
    await auditService.registrar({
      usuarioId,
      tipoEntidad: 'mensajes_chat',
      idEntidad: usuarioId,
      accion: 'MENSAJE_CHAT',
      detalle: { risk_level }
    });

    return {
      session_id: sessionId || 'sesion-activa',
      reply,
      risk_level,
      sources
    };
  } catch (error) {
    if (error instanceof AppError) throw error;
    console.error('Error al comunicarse con el AI Service (chat):', error.message);
    const status = error.response ? error.response.status : 503;
    throw new AppError('El servicio de Inteligencia Artificial no está disponible temporalmente', status);
  }
};

module.exports = { enviarMensaje };
