const vaccinesRepo = require('./vaccines.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

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

  // NOTA: aquí es donde, en la Fase 2 (módulo Reminders + n8n), debería
  // generarse automáticamente un recordatorio si fecha_proxima_dosis
  // viene informada. No se implementa todavía — queda fuera del alcance
  // de esta Fase 1.

  return registro;
};

module.exports = { getVaccines, addVaccine };
