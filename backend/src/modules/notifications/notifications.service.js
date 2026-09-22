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
  const [{ data, error, count }, { count: unreadCount, error: unreadError }] = await Promise.all([
    notificationsRepo.listarPorUsuario(usuarioId, { limit, offset, soloNoLeidas }),
    notificationsRepo.contarNoLeidas(usuarioId)
  ]);

  if (error) throw new AppError('Error al obtener notificaciones', 500);

  return {
    notificaciones: (data || []).map((n) => ({
      ...n,
      leida: Boolean(n.fecha_lectura || n.leida)
    })),
    total: count ?? (data || []).length,
    no_leidas: unreadCount ?? 0
  };
};

const markAsRead = async (usuarioId, notificacionId) => {
  const { data, error } = await notificationsRepo.marcarLeida(usuarioId, notificacionId);
  if (error) throw new AppError('Error al actualizar notificación', 500);
  if (!data) throw new AppError('Notificación no encontrada', 404);
  return { ...data, leida: true };
};

const markAllAsRead = async (usuarioId) => {
  const { error } = await notificationsRepo.marcarTodasLeidas(usuarioId);
  if (error) throw new AppError('Error al marcar notificaciones como leídas', 500);
  return { success: true };
};

module.exports = {
  notificar,
  getNotifications,
  markAsRead,
  markAllAsRead,
  TIPOS_NOTIFICACION
};
