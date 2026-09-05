// Persiste sesiones/mensajes y comunica el backend con el AI Service.
const axios = require('axios');
const supabase = require('../../config/supabase');
const { AI_SERVICE_URL, AI_SERVICE_INTERNAL_KEY, asegurarConfiguracion } = require('../../config/aiServiceClient');

const postChat = (message, latitude, longitude, medicalContext, conversationHistory) => {
  asegurarConfiguracion();

  return axios.post(`${AI_SERVICE_URL}/chat`, {
    message, latitude, longitude, medical_context: medicalContext, conversation_history: conversationHistory
  }, {
    headers: {
      'X-Internal-Key': AI_SERVICE_INTERNAL_KEY,
      'Content-Type': 'application/json'
    },
    timeout: 180000
  });
};

const listarHistorialReciente = (sesionChatId, limite = 10) =>
  supabase
    .from('mensajes_chat')
    .select('emisor, mensaje, fecha_creacion')
    .eq('sesion_chat_id', sesionChatId)
    .order('fecha_creacion', { ascending: false })
    .limit(limite);

// --- sesiones_chat ---

const crearSesion = (usuarioId) =>
  supabase
    .from('sesiones_chat')
    .insert({ usuario_id: usuarioId })
    .select('id')
    .single();

const listarUltimaSesion = (usuarioId) =>
  supabase
    .from('sesiones_chat')
    .select('id, fecha_creacion')
    .eq('usuario_id', usuarioId)
    .order('fecha_creacion', { ascending: false })
    .limit(1)
    .maybeSingle();

const listarMensajesSesion = (usuarioId, sesionId, limite = 50) =>
  supabase
    .from('mensajes_chat')
    .select('id, emisor, mensaje, nivel_riesgo, fecha_creacion, sesiones_chat!inner(usuario_id)')
    .eq('sesion_chat_id', sesionId)
    .eq('sesiones_chat.usuario_id', usuarioId)
    .order('fecha_creacion', { ascending: true })
    .limit(limite);

// Filtra por usuario_id (no solo por id) 

const buscarSesionActiva = (usuarioId, sesionId) =>
  supabase
    .from('sesiones_chat')
    .select('id')
    .eq('id', sesionId)
    .eq('usuario_id', usuarioId)
    .is('fecha_fin', null)
    .maybeSingle();

// --- mensajes_chat ---

const crearMensaje = ({ sesionChatId, emisor, mensaje, nivelRiesgo }) =>
  supabase
    .from('mensajes_chat')
    .insert({
      sesion_chat_id: sesionChatId,
      emisor,
      mensaje,
      nivel_riesgo: nivelRiesgo
    })
    .select()
    .single();

module.exports = {
  postChat,
  listarHistorialReciente,
  crearSesion,
  listarUltimaSesion,
  listarMensajesSesion,
  buscarSesionActiva,
  crearMensaje
};
