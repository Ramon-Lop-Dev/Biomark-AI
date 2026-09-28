// Coordina recordatorios, auditoría y eventos publicados a n8n.
const remindersRepo = require('./reminders.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');
const { publicarEvento } = require('../../config/n8nClient');

const getReminders = async (usuarioId) => {
  const { data, error } = await remindersRepo.listarPorUsuario(usuarioId);
  if (error) throw new AppError('Error al obtener recordatorios', 500);
  return data;
};

const calcularFechaNotificacion = (fechaProgramadaIso, avisoPrevio) => {
  const d = new Date(fechaProgramadaIso);
  if (isNaN(d.getTime())) return fechaProgramadaIso;

  switch (avisoPrevio) {
    case '1_HORA_ANTES':
      d.setHours(d.getHours() - 1);
      return d.toISOString();
    case '1_DIA_ANTES':
      d.setDate(d.getDate() - 1);
      return d.toISOString();
    case '2_DIAS_ANTES':
      d.setDate(d.getDate() - 2);
      return d.toISOString();
    case 'AL_MOMENTO':
    default:
      return d.toISOString();
  }
};

const addReminder = async (usuarioId, payload) => {
  const avisoPrevio = payload.aviso_previo || 'AL_MOMENTO';
  const fechaNotificacion = calcularFechaNotificacion(payload.fecha_programada, avisoPrevio);

  const { data, error } = await remindersRepo.crear(usuarioId, {
    ...payload,
    aviso_previo: avisoPrevio,
    fecha_notificacion: fechaNotificacion
  });
  if (error) {
    console.error('[Reminders] Error al crear recordatorio:', error.message || error);
    throw new AppError(error.message || 'Error al crear recordatorio', 500);
  }

  const registro = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'recordatorios',
    idEntidad: registro.id,
    accion: 'CREACION',
    detalle: {
      tipo: registro.tipo,
      titulo: registro.titulo,
      frecuencia: registro.frecuencia,
      aviso_previo: registro.aviso_previo,
      fecha_notificacion: registro.fecha_notificacion
    }
  });

  try {
    const notificationsService = require('../notifications/notifications.service');
    await notificationsService.notificar({
      usuarioId,
      tipo: 'RECORDATORIO',
      titulo: `Recordatorio programado: ${registro.titulo}`,
      mensaje: `${registro.descripcion || 'Dosis o cita de salud'}. Fecha: ${registro.fecha_programada}`,
      datosAdicionales: { reminder_id: registro.id, estado: registro.estado, tipo: registro.tipo }
    });
  } catch (_) {}

  return registro;
};

const calcularSiguienteFecha = (fechaIso, frecuencia) => {
  const d = new Date(fechaIso);
  if (isNaN(d.getTime())) return null;

  switch (frecuencia) {
    case 'HORARIA':
      d.setHours(d.getHours() + 1);
      return d.toISOString();
    case 'DIARIA':
      d.setDate(d.getDate() + 1);
      return d.toISOString();
    case 'SEMANAL':
      d.setDate(d.getDate() + 7);
      return d.toISOString();
    case 'QUINCENAL':
      d.setDate(d.getDate() + 15);
      return d.toISOString();
    case 'MENSUAL':
      d.setMonth(d.getMonth() + 1);
      return d.toISOString();
    case 'UNA_VEZ':
    default:
      return null;
  }
};

const processDueReminders = async () => {
  const { data, error } = await remindersRepo.listarVencidosPendientes();
  if (error) {
    console.error('[Reminders] Error al listar recordatorios vencidos:', error.message);
    return [];
  }

  if (!data || data.length === 0) return [];

  const ahora = new Date();
  const procesados = [];

  for (const registro of data) {
    try {
      const fechaProg = new Date(registro.fecha_programada);
      const fechaNotif = registro.fecha_notificacion ? new Date(registro.fecha_notificacion) : fechaProg;
      const esPreAviso = fechaNotif < fechaProg && ahora < fechaProg;

      let tituloEnvio = registro.titulo;
      let descEnvio = registro.descripcion || '';

      if (esPreAviso) {
        const avisoLabel = registro.aviso_previo === '1_HORA_ANTES' ? 'en 1 hora'
          : registro.aviso_previo === '1_DIA_ANTES' ? 'mañana'
          : 'en 2 días';
        tituloEnvio = `⏰ Aviso previo: ${registro.titulo}`;
        descEnvio = `Aviso programado (${avisoLabel}): ${descEnvio || 'Dosis o cita de salud'}`.trim();
      } else {
        tituloEnvio = `⏰ Recordatorio: ${registro.titulo}`;
      }

      const nombreEvento = process.env.N8N_REMINDER_EVENT || 'recordatorio.creado';
      await publicarEvento(nombreEvento, {
        recordatorio: {
          ...registro,
          titulo: tituloEnvio,
          descripcion: descEnvio
        },
        usuario_id: registro.usuario_id,
        recordatorio_id: registro.id,
        titulo: tituloEnvio,
        descripcion: descEnvio,
        tipo: registro.tipo,
        frecuencia: registro.frecuencia || 'UNA_VEZ',
        aviso_previo: registro.aviso_previo || 'AL_MOMENTO',
        fecha_programada: registro.fecha_programada,
        fecha_notificacion: registro.fecha_notificacion,
        es_pre_aviso: esPreAviso
      });

      if (esPreAviso) {
        // Al disparar el pre-aviso, programamos la fecha_notificacion a la hora exacta del evento
        await remindersRepo.reprogramarSiguienteCiclo(
          registro.id,
          registro.fecha_programada,
          registro.fecha_programada
        );
      } else if (registro.frecuencia && registro.frecuencia !== 'UNA_VEZ') {
        // Al disparar la hora exacta de un recordatorio recurrente, calcular siguiente ciclo futuro
        let siguienteFecha = calcularSiguienteFecha(registro.fecha_programada, registro.frecuencia);
        let guard = 0;
        while (siguienteFecha && new Date(siguienteFecha) <= ahora && guard < 500) {
          siguienteFecha = calcularSiguienteFecha(siguienteFecha, registro.frecuencia);
          guard++;
        }

        if (siguienteFecha) {
          const siguienteNotificacion = calcularFechaNotificacion(
            siguienteFecha,
            registro.aviso_previo || 'AL_MOMENTO'
          );
          await remindersRepo.reprogramarSiguienteCiclo(
            registro.id,
            siguienteFecha,
            siguienteNotificacion
          );
          await auditService.registrar({
            usuarioId: registro.usuario_id,
            tipoEntidad: 'recordatorios',
            idEntidad: registro.id,
            accion: 'REPROGRAMACION_CICLO',
            detalle: {
              nueva_fecha: siguienteFecha,
              nueva_notificacion: siguienteNotificacion,
              frecuencia: registro.frecuencia,
              aviso_previo: registro.aviso_previo
            }
          });
        }
      }
      // Si es UNA_VEZ a la hora exacta, se queda en PENDIENTE hasta que n8n confirme recepción vía PATCH /internal/reminders/:id/sent (markReminderSent)
      procesados.push(registro.id);
    } catch (err) {
      const detalleError = err.response?.data ? JSON.stringify(err.response.data) : err.message;
      console.error(`[Reminders] Error procesando recordatorio ${registro.id}:`, detalleError);
    }
  }

  return procesados;
};

const updateReminderStatus = async (usuarioId, recordatorioId, estado) => {
  const { data, error } = await remindersRepo.actualizarEstado(usuarioId, recordatorioId, estado);
  if (error) throw new AppError('Error al actualizar el estado del recordatorio', 500);

  if (!data) {
    throw new AppError('Recordatorio no encontrado', 404);
  }

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'recordatorios',
    idEntidad: data.id,
    accion: 'ACTUALIZACION_ESTADO',
    detalle: { estado_nuevo: estado }
  });

  try {
    const notificationsService = require('../notifications/notifications.service');
    const label = estado === 'COMPLETADO' ? 'completado' : estado === 'CANCELADO' ? 'cancelado/archivado' : estado.toLowerCase();
    await notificationsService.notificar({
      usuarioId,
      tipo: 'RECORDATORIO',
      titulo: `Recordatorio ${label}: ${data.titulo}`,
      mensaje: `${data.descripcion || 'Dosis o cita médica'}. Estado: ${estado}`,
      datosAdicionales: { reminder_id: data.id, estado, tipo: data.tipo }
    });
  } catch (_) {}

  return data;
};

const markReminderSent = async (recordatorioId) => {
  const { data, error } = await remindersRepo.marcarEnviado(recordatorioId);
  if (error) throw new AppError('Error al marcar el recordatorio como enviado', 500);
  if (!data) throw new AppError('Recordatorio no encontrado o ya procesado', 404);
  return data;
};

module.exports = {
  getReminders,
  addReminder,
  updateReminderStatus,
  markReminderSent,
  processDueReminders,
  calcularSiguienteFecha,
  calcularFechaNotificacion
};
