const remindersRepo = require('./reminders.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

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

  // TODO (Fase 7 — integración n8n): hacer el POST al webhook de n8n aquí
  // para que efectivamente se programe el envío. La configuración
  // (N8N_WEBHOOK_URL, N8N_WEBHOOK_SECRET) ya está lista en
  // config/n8nClient.js — falta solo el repository.postWebhook() +
  // la llamada aquí, siguiendo el mismo patrón que chat/voice/vision
  // usan para hablar con el AI Service. Sigue fuera del alcance de la
  // Fase 2 (que solo cierra el ciclo de estado interno).

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

module.exports = { getReminders, addReminder, updateReminderStatus };
