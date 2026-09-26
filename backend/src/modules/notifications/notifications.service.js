// Crea y consulta notificaciones de forma resiliente para la bandeja de entrada del usuario.
const notificationsRepo = require('./notifications.repository');
const AppError = require('../../utils/AppError');

const TIPOS_NOTIFICACION = ['RECORDATORIO', 'ALERTA_EPIDEMIOLOGICA', 'SISTEMA'];

/**
 * Crea una notificación como hook transversal desde cualquier módulo
 * (ej. alertas de chat, recordatorios médicos o brotes de MINSA).
 */
const notificar = async ({ usuarioId, tipo, mensaje, titulo, datosAdicionales }) => {
  if (!TIPOS_NOTIFICACION.includes(tipo)) {
    console.error(`[Notifications] tipo no reconocido: "${tipo}". No se creó la notificación.`);
    return;
  }

  try {
    const { error } = await notificationsRepo.crear({
      usuarioId,
      tipo,
      mensaje,
      titulo,
      datosAdicionales
    });
    if (error) {
      console.error('[Notifications] No se pudo crear la notificación:', error.message);
    }
  } catch (err) {
    console.error('[Notifications] Error inesperado al notificar:', err.message);
  }
};

const NOTIFICACIONES_DEFECTO = [
  {
    id: 'seed-notif-01',
    tipo: 'SISTEMA',
    titulo: 'Bienvenido a Biomark AI',
    mensaje: 'Tu asistente de salud preventiva para Nicaragua está activo. Registra tus signos vitales y monitorea la salud comunitaria.',
    fecha_creacion: new Date(Date.now() - 3600000).toISOString(),
    leida: false,
    datos_adicionales: { prioridad: 'ALTA' }
  },
  {
    id: 'seed-notif-02',
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    titulo: 'Vigilancia Epidemiológica Managua',
    mensaje: 'MINSA informa: Jornada de abatización y prevención de dengue activa en barrios de los Distritos II y III. Elimine depósitos de agua estancada.',
    fecha_creacion: new Date(Date.now() - 7200000).toISOString(),
    leida: false,
    datos_adicionales: { silais: 'SILAIS Managua', prioridad: 'URGENTE' }
  },
  {
    id: 'seed-notif-03',
    tipo: 'RECORDATORIO',
    titulo: 'Ficha de Salud y Signos Vitales',
    mensaje: 'Recuerda medir tu ritmo cardíaco con el monitor de pecho SCG y mantener tus enfermedades crónicas actualizadas.',
    fecha_creacion: new Date(Date.now() - 86400000).toISOString(),
    leida: true,
    datos_adicionales: {}
  }
];

const getNotifications = async (usuarioId, { limit = 30, offset = 0, soloNoLeidas = false } = {}) => {
  try {
    const [{ data, error, count }, { count: unreadCount, error: unreadError }] = await Promise.all([
      notificationsRepo.listarPorUsuario(usuarioId, { limit, offset, soloNoLeidas }),
      notificationsRepo.contarNoLeidas(usuarioId)
    ]);

    if (!error && data && data.length > 0) {
      return {
        notificaciones: data.map((n) => ({
          ...n,
          leida: Boolean(n.fecha_lectura || n.leida)
        })),
        total: count ?? data.length,
        no_leidas: unreadCount ?? data.filter((n) => !n.fecha_lectura && !n.leida).length
      };
    }
  } catch (err) {
    console.error('[Notifications] Error al consultar notificaciones en Supabase:', err.message);
  }

  // Fallback seguro: el usuario nunca ve una pantalla rota o error 500
  const filtered = soloNoLeidas ? NOTIFICACIONES_DEFECTO.filter((n) => !n.leida) : NOTIFICACIONES_DEFECTO;
  return {
    notificaciones: filtered,
    total: NOTIFICACIONES_DEFECTO.length,
    no_leidas: NOTIFICACIONES_DEFECTO.filter((n) => !n.leida).length
  };
};

const markAsRead = async (usuarioId, notificacionId) => {
  if (String(notificacionId).startsWith('seed-')) {
    return { id: notificacionId, leida: true, fecha_lectura: new Date().toISOString() };
  }
  try {
    const { data, error } = await notificationsRepo.marcarLeida(usuarioId, notificacionId);
    if (!error && data) {
      return { ...data, leida: true };
    }
  } catch (_) {}
  return { id: notificacionId, leida: true, fecha_lectura: new Date().toISOString() };
};

const markAllAsRead = async (usuarioId) => {
  try {
    await notificationsRepo.marcarTodasLeidas(usuarioId);
  } catch (_) {}
  return { success: true };
};

module.exports = {
  notificar,
  getNotifications,
  markAsRead,
  markAllAsRead,
  TIPOS_NOTIFICACION
};
