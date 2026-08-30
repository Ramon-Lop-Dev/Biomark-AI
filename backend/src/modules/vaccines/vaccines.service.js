// Coordina vacunas, recomendaciones y recordatorios de próximas dosis.
const vaccinesRepo = require('./vaccines.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');
const remindersService = require('../reminders/reminders.service');

const getVaccines = async (usuarioId) => {
  const { data, error } = await vaccinesRepo.listarPorUsuario(usuarioId);
  if (error) throw new AppError('Error al obtener vacunas', 500);
  return data;
};

const addVaccine = async (usuarioId, payload) => {
  const { data, error } = await vaccinesRepo.crear(usuarioId, payload);
  if (error) throw new AppError('Error al registrar vacuna', 500);

  const registro = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'vacunas',
    idEntidad: registro.id,
    accion: 'CREACION',
    detalle: { nombre_vacuna: registro.nombre_vacuna }
  });

  // Si viene fecha_proxima_dosis, se genera automáticamente un
  // recordatorio (tipo VACUNA) reutilizando reminders.service para no
  // duplicar aquí su lógica de auditoría. "fecha_proxima_dosis" en
  // "vacunas" es solo DATE (YYYY-MM-DD), pero "recordatorios.fecha_programada"
  // es timestamp with time zone, así que se fija una hora por defecto
  // (9:00 AM UTC) al convertirla.
  //
  // Es una mejora de UX, no una operación crítica de negocio: si falla,
  // NUNCA debe tumbar el registro de la vacuna (que ya se guardó con
  // éxito), por eso el error solo se loguea y no se relanza.
  if (registro.fecha_proxima_dosis) {
    try {
      await remindersService.addReminder(usuarioId, {
        titulo: `Próxima dosis: ${registro.nombre_vacuna}`,
        descripcion: `Recordatorio generado automáticamente al registrar la dosis #${registro.numero_dosis} de ${registro.nombre_vacuna}.`,
        fecha_programada: `${registro.fecha_proxima_dosis}T09:00:00.000Z`,
        tipo: 'VACUNA'
      });
    } catch (reminderError) {
      console.error('[Vaccines] No se pudo generar el recordatorio automático:', reminderError.message);
    }
  }

  return registro;
};

const getRecommendations = async (usuarioId) => {
  const { data, error } = await vaccinesRepo.listarPorUsuario(usuarioId);
  if (error) throw new AppError('Error al obtener recomendaciones de vacunas', 500);
  return (data || []).map((vacuna) => ({
    nombre_vacuna: vacuna.nombre_vacuna,
    numero_dosis_actual: vacuna.numero_dosis,
    fecha_proxima_dosis: vacuna.fecha_proxima_dosis || null,
    estado: vacuna.fecha_proxima_dosis && vacuna.fecha_proxima_dosis < new Date().toISOString().slice(0, 10)
      ? 'VENCIDA'
      : vacuna.fecha_proxima_dosis ? 'PROGRAMADA' : 'SIN_FECHA_PROGRAMADA'
  }));
};

module.exports = { getVaccines, addVaccine, getRecommendations };
