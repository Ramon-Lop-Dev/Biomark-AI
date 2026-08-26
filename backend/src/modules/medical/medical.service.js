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

// --- alergias ---

const getAllergies = async (usuarioId) => {
  const { data, error } = await medicalRepo.listarAlergiasPorUsuario(usuarioId);
  if (error) throw new AppError('Error al obtener las alergias', 500);
  return data;
};

const createAllergy = async (usuarioId, payload) => {
  const { data, error } = await medicalRepo.crearAlergia(usuarioId, payload);
  if (error) throw new AppError('Error al registrar la alergia', 500);

  const registro = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'alergias',
    idEntidad: registro.id,
    accion: 'CREACION',
    detalle: { alergeno: registro.alergeno, severidad: registro.severidad }
  });

  return registro;
};

// --- medicamentos ---

const getMedications = async (usuarioId) => {
  const { data, error } = await medicalRepo.listarMedicamentosPorUsuario(usuarioId);
  if (error) throw new AppError('Error al obtener los medicamentos', 500);
  return data;
};

const createMedication = async (usuarioId, payload) => {
  const { data, error } = await medicalRepo.crearMedicamento(usuarioId, payload);
  if (error) throw new AppError('Error al registrar el medicamento', 500);

  const registro = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'medicamentos',
    idEntidad: registro.id,
    accion: 'CREACION',
    detalle: { nombre_medicamento: registro.nombre_medicamento }
  });

  return registro;
};

// --- antecedentes_familiares ---

const getFamilyHistory = async (usuarioId) => {
  const { data, error } = await medicalRepo.listarAntecedentesPorUsuario(usuarioId);
  if (error) throw new AppError('Error al obtener los antecedentes familiares', 500);
  return data;
};

const createFamilyHistory = async (usuarioId, payload) => {
  const { data, error } = await medicalRepo.crearAntecedente(usuarioId, payload);
  if (error) throw new AppError('Error al registrar el antecedente familiar', 500);

  const registro = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'antecedentes_familiares',
    idEntidad: registro.id,
    accion: 'CREACION',
    detalle: { parentesco: registro.parentesco, nombre_condicion: registro.nombre_condicion }
  });

  return registro;
};

module.exports = {
  getMedicalHistory,
  createMedicalRecord,
  getAllergies,
  createAllergy,
  getMedications,
  createMedication,
  getFamilyHistory,
  createFamilyHistory
};
