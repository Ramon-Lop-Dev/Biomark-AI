const medicalRepo = require('./medical.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const getMedicalHistory = async (usuarioId) => {
  const { data, error } = await medicalRepo.listarPorUsuario(usuarioId);
  if (error) throw new AppError('Error al obtener el historial médico', 500);
  return data;
};

const createMedicalRecord = async (usuarioId, payload) => {
  const { data, error } = await medicalRepo.crearRegistro(usuarioId, payload);
  if (error) throw new AppError('Error al guardar el registro médico', 500);

  const registro = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'historial_medico',
    idEntidad: registro.id,
    accion: 'CREACION',
    detalle: { nombre_condicion: registro.nombre_condicion }
  });

  return registro;
};

module.exports = { getMedicalHistory, createMedicalRecord };
