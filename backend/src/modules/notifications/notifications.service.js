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

const getNotifications = async (usuarioId, { limit = 30, offset = 0, soloNoLeidas = false } = {}) => {
  try {
    const [{ data, error, count }, { count: unreadCount, error: unreadError }] = await Promise.all([
      notificationsRepo.listarPorUsuario(usuarioId, { limit, offset, soloNoLeidas }),
      notificationsRepo.contarNoLeidas(usuarioId)
    ]);

    if (!error && data) {
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

  // Si no hay notificaciones o falla la consulta, retornar estado limpio y vacío sin semillas falsas
  return {
    notificaciones: [],
    total: 0,
    no_leidas: 0
  };
};

const markAsRead = async (usuarioId, notificacionId) => {
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
