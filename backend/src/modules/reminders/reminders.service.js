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

const addReminder = async (usuarioId, payload) => {
  const { data, error } = await remindersRepo.crear(usuarioId, payload);
  if (error) throw new AppError('Error al crear recordatorio', 500);

  const registro = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'recordatorios',
    idEntidad: registro.id,
    accion: 'CREACION',
    detalle: { tipo: registro.tipo, titulo: registro.titulo }
  });

  try {
    const eventoRecordatorio = {
      id: registro.id,
      usuario_id: usuarioId,
      titulo: registro.titulo,
      descripcion: registro.descripcion || '',
      tipo: registro.tipo,
      fecha_programada: registro.fecha_programada,
    };
    await publicarEvento('recordatorio.creado', {
      recordatorio: registro,
      usuario_id: usuarioId,
      recordatorio_id: eventoRecordatorio.id,
      titulo: eventoRecordatorio.titulo,
      descripcion: eventoRecordatorio.descripcion,
      tipo: eventoRecordatorio.tipo,
      fecha_programada: eventoRecordatorio.fecha_programada,
    });
  } catch (error) {
    console.error('[Reminders] No se pudo publicar el evento en n8n:', error.message);
  }

  return registro;
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

  return data;
};

const markReminderSent = async (recordatorioId) => {
  const { data, error } = await remindersRepo.marcarEnviado(recordatorioId);
  if (error) throw new AppError('Error al marcar el recordatorio como enviado', 500);
  if (!data) throw new AppError('Recordatorio no encontrado o ya procesado', 404);
  return data;
};

module.exports = { getReminders, addReminder, updateReminderStatus, markReminderSent };
