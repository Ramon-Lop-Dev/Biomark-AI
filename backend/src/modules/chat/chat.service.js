// Coordina sesión, contexto médico, IA, persistencia y alertas del chat.
const chatRepo = require('./chat.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');
const notificationsService = require('../notifications/notifications.service');
const { mapearNivelRiesgo } = require('../../utils/nivelRiesgo');
const { obtenerContextoClinico } = require('../medical/medicalContext.service');

// nivel_riesgo que deben disparar una notificación al usuario, además de
// quedar solo registrados en el mensaje de chat.
const NIVELES_QUE_NOTIFICAN = ['ALTO', 'CRITICO'];

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

const enviarMensaje = async (usuarioId, message, sessionId, latitude, longitude) => {
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
    const [contextoClinico, { data: historial, error: errorHistorial }] = await Promise.all([
      obtenerContextoClinico(usuarioId),
      chatRepo.listarHistorialReciente(sesionId)
    ]);
    if (errorHistorial) console.error('[Chat] No se pudo cargar el historial reciente:', errorHistorial.message);
    const conversationHistory = (historial || []).reverse();
    const ultimoTurno = conversationHistory[conversationHistory.length - 1];
    if (ultimoTurno && ultimoTurno.emisor === 'USUARIO' && ultimoTurno.mensaje === message) {
      conversationHistory.pop();
    }
    const { data } = await chatRepo.postChat(
      message,
      latitude,
      longitude,
      contextoClinico,
      conversationHistory
    );
    const { reply, risk_level, sources, suggested_action, centro_sugerido } = data;

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
      detalle: {
        risk_level,
        nivel_riesgo: nivelRiesgo,
        centro_recomendado: centro_sugerido
          ? {
              id: centro_sugerido.id,
              especialidad_coincidente: centro_sugerido.especialidad_coincidente || null,
              distancia_km: centro_sugerido.distancia_km
            }
          : null,
        contexto_medico_compartido: Boolean(contextoClinico),
        campos_contexto: contextoClinico ? Object.keys(contextoClinico) : [],
        mensajes_historial_compartidos: conversationHistory.length
      }
    });

    // Si el nivel de riesgo es ALTO/CRITICO, se dispara una notificación
    // (tipo SISTEMA) además de quedar registrado en el mensaje del chat.
    // No bloquea la respuesta al usuario: notificationsService.notificar
    // nunca lanza (ver notifications.service.js).
    if (NIVELES_QUE_NOTIFICAN.includes(nivelRiesgo)) {
      await notificationsService.notificar({
        usuarioId,
        tipo: 'SISTEMA',
        mensaje: 'Detectamos un nivel de riesgo elevado en tu conversación con Biomark AI. Te recomendamos buscar atención médica lo antes posible.'
      });
    }

    return {
      session_id: sesionId,
      reply,
      risk_level,
      sources,
      suggested_action: suggested_action || null,
      centro_sugerido: centro_sugerido || null
    };
  } catch (error) {
    if (error instanceof AppError) throw error;
    console.error('Error al comunicarse con el AI Service (chat):', error.message);
    const status = error.response ? error.response.status : 503;
    throw new AppError('El servicio de Inteligencia Artificial no está disponible temporalmente', status);
  }
};

const obtenerHistorial = async (usuarioId, sessionId) => {
  let sesion = sessionId;
  if (sesion) {
    const { data, error } = await chatRepo.buscarSesionActiva(usuarioId, sesion);
    if (error || !data) throw new AppError('La sesión de chat no existe', 404);
  } else {
    const { data, error } = await chatRepo.listarUltimaSesion(usuarioId);
    if (error) throw new AppError('No se pudo cargar el historial del chat', 500);
    sesion = data?.id;
  }

  if (!sesion) return { session_id: null, messages: [] };
  const { data, error } = await chatRepo.listarMensajesSesion(usuarioId, sesion);
  if (error) throw new AppError('No se pudo cargar el historial del chat', 500);
  return {
    session_id: sesion,
    messages: (data || []).map(({ emisor, mensaje, nivel_riesgo }) => ({
      emisor,
      mensaje,
      nivel_riesgo
    }))
  };
};

// resolverSesion se exporta para que voice.service.js la reutilice (Voice
// comparte sesiones_chat/mensajes_chat con Chat — no es un dominio propio,
// ver corrección aplicada en voice.service.js).
module.exports = { enviarMensaje, resolverSesion, obtenerHistorial };
