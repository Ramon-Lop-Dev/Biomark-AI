const chatRepo = require('./chat.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');
const { mapearNivelRiesgo } = require('../../utils/nivelRiesgo');

// Resuelve a qué sesión pertenece este mensaje. Si el cliente manda un
// session_id, se busca ESA sesión y que sea del usuario autenticado y
// que siga abierta (ver chat.repository.buscarSesionActiva); si no
// existe, es de otro usuario, o ya se cerró, se abre una nueva
// silenciosamente en vez de romper la conversación — igual criterio de
// resiliencia que el resto del proyecto (nunca tumbar la experiencia del
// usuario por un dato de sesión obsoleto en el cliente).
const resolverSesion = async (usuarioId, sessionId) => {
  if (sessionId) {
    const { data, error } = await chatRepo.buscarSesionActiva(usuarioId, sessionId);
    if (!error && data) {
      return data.id;
    }
  }

  const { data: nuevaSesion, error: errorCrear } = await chatRepo.crearSesion(usuarioId);
  if (errorCrear || !nuevaSesion) {
    throw new AppError('No se pudo iniciar la sesión de chat', 500);
  }
  return nuevaSesion.id;
};

const enviarMensaje = async (usuarioId, message, sessionId) => {
  const sesionId = await resolverSesion(usuarioId, sessionId);

  // Se guarda el mensaje del usuario ANTES de llamar al AI Service: si
  // el AI Service falla o tarda, el mensaje ya quedó a salvo.
  const { error: errorMsgUsuario } = await chatRepo.crearMensaje({
    sesionChatId: sesionId,
    emisor: 'USUARIO',
    mensaje: message,
    nivelRiesgo: null // el riesgo lo evalúa el AI Service sobre la respuesta, no sobre lo que escribe el usuario
  });

  if (errorMsgUsuario) {
    // No relanza: perder la copia persistida del mensaje no debe
    // impedir que el usuario reciba su respuesta clínica.
    console.error('[Chat] No se pudo persistir el mensaje del usuario:', errorMsgUsuario.message);
  }

  try {
    const { data } = await chatRepo.postChat(message);
    const { reply, risk_level, sources } = data;

    const nivelRiesgo = mapearNivelRiesgo(risk_level);

    const { data: mensajeAsistente, error: errorMsgAsistente } = await chatRepo.crearMensaje({
      sesionChatId: sesionId,
      emisor: 'ASISTENTE',
      mensaje: reply,
      nivelRiesgo
    });

    if (errorMsgAsistente) {
      console.error('[Chat] No se pudo persistir la respuesta del asistente:', errorMsgAsistente.message);
    }

    await auditService.registrar({
      usuarioId,
      tipoEntidad: 'mensajes_chat',
      idEntidad: mensajeAsistente ? mensajeAsistente.id : sesionId,
      accion: 'MENSAJE_CHAT',
      detalle: { risk_level, nivel_riesgo: nivelRiesgo }
    });

    // NOTA (Fase 6, fuera de alcance de esta Fase 3): si nivelRiesgo es
    // ALTO/CRITICO, aquí debería dispararse una fila en "notificaciones".

    return {
      session_id: sesionId,
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
