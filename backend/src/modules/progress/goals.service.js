const repository = require('./goals.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const PERIOD_DAYS = {
  SEMANAL: 7,
  QUINCENAL: 14,
  TRIMESTRAL: 90,
  SEMESTRAL: 182,
  ANUAL: 365
};

const throwDatabaseError = (error, fallback) => {
  if (error?.code === '42P01') {
    throw new AppError('La base de datos aún no tiene las tablas de objetivos. Ejecuta la migración 006_objetivos_mejoria.sql.', 500);
  }
  throw new AppError(fallback, 500);
};

const addPeriod = (date, periodicidad) => {
  if (periodicidad === 'MENSUAL') {
    const next = new Date(date);
    next.setUTCMonth(next.getUTCMonth() + 1);
    return next;
  }
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + PERIOD_DAYS[periodicidad]);
  return next;
};

const formatDate = (date) => date.toISOString().slice(0, 10);

const buildMilestones = (goal) => {
  const start = new Date(`${goal.fecha_inicio}T00:00:00.000Z`);
  const end = new Date(`${goal.fecha_fin}T00:00:00.000Z`);
  const milestones = [];
  let current = start;
  let index = 1;

  while (current <= end) {
    milestones.push({
      objetivo_id: goal.id,
      titulo: `Hito ${index}`,
      fecha_objetivo: formatDate(current)
    });
    const next = addPeriod(current, goal.periodicidad);
    if (next <= current) break;
    current = next;
    index += 1;
  }

  return milestones;
};

const getGoals = async (usuarioId) => {
  const { data, error } = await repository.listarPorUsuario(usuarioId);
  if (error) throwDatabaseError(error, 'Error al obtener los objetivos de mejoría');
  return data;
};

const createGoal = async (usuarioId, payload) => {
  if (payload.fecha_fin < payload.fecha_inicio) {
    throw new AppError('La fecha final debe ser posterior a la fecha inicial', 400);
  }

  const { data: goal, error } = await repository.crearObjetivo(usuarioId, payload);
  if (error) throwDatabaseError(error, 'Error al crear el objetivo de mejoría');

  const { error: milestonesError } = await repository.crearHitos(buildMilestones(goal));
  if (milestonesError) throwDatabaseError(milestonesError, 'Error al generar los hitos del objetivo');

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'objetivos_mejoria',
    idEntidad: goal.id,
    accion: 'CREACION',
    detalle: { titulo: goal.titulo, periodicidad: goal.periodicidad }
  });

  return (await getGoals(usuarioId)).find((item) => item.id === goal.id);
};

const updateMilestone = async (usuarioId, objetivoId, hitoId, completado) => {
  const { data: goal, error: goalError } = await repository.obtenerObjetivo(usuarioId, objetivoId);
  if (goalError) throwDatabaseError(goalError, 'Error al validar el objetivo');
  if (!goal) throw new AppError('Objetivo no encontrado', 404);

  const { data, error } = await repository.actualizarHito(objetivoId, hitoId, completado);
  if (error) throwDatabaseError(error, 'Error al actualizar el hito');
  if (!data) throw new AppError('Hito no encontrado', 404);
  return data;
};

module.exports = { getGoals, createGoal, updateMilestone };