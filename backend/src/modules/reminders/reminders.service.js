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

  // TODO (Fase 3 — integración n8n): hacer el POST al webhook de n8n aquí
  // (N8N_WEBHOOK_URL) para que efectivamente se programe el envío. Sigue
  // fuera del alcance de esta Fase 1 (arquitectura/seguridad).

  return registro;
};

module.exports = { getReminders, addReminder };
