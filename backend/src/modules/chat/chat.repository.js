const axios = require('axios');
const supabase = require('../../config/supabase');
const { AI_SERVICE_URL, AI_SERVICE_INTERNAL_KEY, asegurarConfiguracion } = require('../../config/aiServiceClient');

const postChat = (message) => {
  asegurarConfiguracion();

  return axios.post(`${AI_SERVICE_URL}/chat`, { message }, {
    headers: {
      'X-Internal-Key': AI_SERVICE_INTERNAL_KEY,
      'Content-Type': 'application/json'
    },
    timeout: 180000
  });
};

// --- sesiones_chat ---

const crearSesion = (usuarioId) =>
  supabase
    .from('sesiones_chat')
    .insert({ usuario_id: usuarioId })
    .select('id')
    .single();

// Filtra por usuario_id (no solo por id) por la misma razón que en
// reminders.repository.actualizarEstado: sin RLS, es la única barrera
// real contra que un usuario reutilice/enumere el session_id de otro.
// También exige fecha_fin IS NULL: una sesión ya cerrada no se reabre.
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

module.exports = { postChat, crearSesion, buscarSesionActiva, crearMensaje };
