const notificationsRepo = require('./notifications.repository');
const AppError = require('../../utils/AppError');
const supabase = require('../../config/supabase');

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
    const [{ data: directNotifs, error, count }, { count: unreadCount, error: unreadError }] = await Promise.all([
      notificationsRepo.listarPorUsuario(usuarioId, { limit: 50, offset: 0, soloNoLeidas }),
      notificationsRepo.contarNoLeidas(usuarioId)
    ]);

    // Consultar también recordatorios del usuario (completados, activos o archivados)
    let reminderItems = [];
    try {
      const { data: reminders } = await supabase
        .from('recordatorios')
        .select('*')
        .eq('usuario_id', usuarioId)
        .order('fecha_programada', { ascending: false })
        .limit(30);

      if (reminders && reminders.length > 0) {
        reminderItems = reminders.map((r) => {
          const isDone = r.estado === 'COMPLETADO' || r.estado === 'CANCELADO';
          const labelEstado = r.estado === 'COMPLETADO' ? 'Completado' : r.estado === 'CANCELADO' ? 'Cancelado' : 'Pendiente';
          return {
            id: `rem_${r.id}`,
            usuario_id: usuarioId,
            tipo: 'RECORDATORIO',
            titulo: `${r.titulo} (${labelEstado})`,
            mensaje: r.descripcion
              ? `${r.descripcion}. Estado: ${r.estado}`
              : `Recordatorio de ${r.tipo ? r.tipo.toLowerCase() : 'salud'} programado para ${r.fecha_programada}. Estado: ${r.estado}`,
            fecha_creacion: r.fecha_creacion || r.fecha_programada,
            fecha_lectura: isDone ? (r.fecha_creacion || new Date().toISOString()) : null,
            leida: isDone,
            datos_adicionales: { reminder_id: r.id, estado: r.estado, tipo_recordatorio: r.tipo }
          };
        });
      }
    } catch (_) {}

    // Consultar también avisos oficiales del MINSA activos
    let avisosItems = [];
    try {
      const { data: avisos } = await supabase
        .from('avisos_minsa')
        .select('*')
        .eq('activo', true)
        .order('fecha_publicacion', { ascending: false })
        .limit(10);

      if (avisos && avisos.length > 0) {
        avisosItems = avisos.map((a) => ({
          id: `aviso_${a.id}`,
          usuario_id: usuarioId,
          tipo: 'ALERTA_EPIDEMIOLOGICA',
          titulo: a.titulo || 'Aviso Oficial MINSA',
          mensaje: a.contenido || a.resumen || 'Comunicado oficial de salud comunitaria.',
          fecha_creacion: a.fecha_publicacion || a.fecha_creacion,
          fecha_lectura: null,
          leida: false,
          datos_adicionales: { aviso_id: a.id, categoria: a.categoria }
        }));
      }
    } catch (_) {}

    // Mapear notificaciones directas
    const directos = (directNotifs || []).map((n) => ({
      ...n,
      leida: Boolean(n.fecha_lectura || n.leida)
    }));

    // Deduplicar recordatorios que ya tengan notificación directa
    const idsDirectosReminder = new Set(
      directos.map((d) => d.datos_adicionales?.reminder_id).filter(Boolean)
    );
    const remindersFiltrados = reminderItems.filter(
      (r) => !idsDirectosReminder.has(r.datos_adicionales?.reminder_id)
    );

    let todos = [...directos, ...remindersFiltrados, ...avisosItems];

    if (soloNoLeidas) {
      todos = todos.filter((n) => !n.leida);
    }

    todos.sort((a, b) => new Date(b.fecha_creacion || 0).getTime() - new Date(a.fecha_creacion || 0).getTime());

    const total = todos.length;
    const paginados = todos.slice(offset, offset + limit);
    const noLeidas = todos.filter((n) => !n.leida).length;

    return {
      notificaciones: paginados,
      total,
      no_leidas: noLeidas
    };
  } catch (err) {
    console.error('[Notifications] Error al consultar notificaciones en Supabase:', err.message);
  }

  // Fallback seguro sin semillas falsas
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
