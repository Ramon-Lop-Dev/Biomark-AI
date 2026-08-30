// Crea notificaciones de forma resiliente sin bloquear la operación origen.
const notificationsRepo = require('./notifications.repository');


const TIPOS_NOTIFICACION = ['RECORDATORIO', 'ALERTA_EPIDEMIOLOGICA', 'SISTEMA'];

/**
 * Crea una notificación. Se usa como hook transversal (igual que
 * audit.service.registrar) desde cualquier módulo que detecte que un
 * usuario debe ser alertado — hoy: chat.service cuando nivel_riesgo es
 * ALTO/CRITICO. Nunca lanza: un fallo al notificar no debe tumbar la
 * operación de negocio que lo originó (p. ej. la respuesta del chat ya
 * se le mostró al usuario en pantalla, perder la fila de notificaciones
 * no debe convertirse en un error 500 para él).
 */
const notificar = async ({ usuarioId, tipo, mensaje }) => {
  if (!TIPOS_NOTIFICACION.includes(tipo)) {
    console.error(`[Notifications] tipo no reconocido: "${tipo}". No se creó la notificación.`);
    return;
  }

  try {
    const { error } = await notificationsRepo.crear({ usuarioId, tipo, mensaje });
    if (error) {
      console.error('[Notifications] No se pudo crear la notificación:', error.message);
    }
  } catch (err) {
    console.error('[Notifications] Error inesperado al notificar:', err.message);
  }
};

module.exports = { notificar, TIPOS_NOTIFICACION };
