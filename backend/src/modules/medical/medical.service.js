// Coordina validación, persistencia y auditoría del expediente médico.
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

const replaceSurvey = async (usuarioId, payload) => {
  const removals = await Promise.all([
    medicalRepo.eliminarHistorial(usuarioId),
    medicalRepo.eliminarAlergias(usuarioId),
    medicalRepo.eliminarMedicamentos(usuarioId),
    medicalRepo.eliminarAntecedentes(usuarioId)
  ]);
  if (removals.some(({ error }) => error)) throw new AppError('No se pudo limpiar la encuesta clínica anterior', 500);

  const date = new Date().toISOString().split('T')[0];
  for (const condition of payload.enfermedades_cronicas) await createMedicalRecord(usuarioId, { nombre_condicion: condition, fecha_diagnostico: date, notas: 'Registrado desde la encuesta clínica.' });
  for (const condition of payload.antecedentes_hereditarios) await createFamilyHistory(usuarioId, { parentesco: 'Familiar', nombre_condicion: condition, notas: 'Registrado desde la encuesta clínica.' });
  for (const allergy of payload.alergias) await createAllergy(usuarioId, { alergeno: allergy, severidad: 'LEVE', notas: 'Registrado desde la encuesta clínica.' });
  if (payload.medicamentos.trim()) await createMedication(usuarioId, { nombre_medicamento: payload.medicamentos.trim(), dosis: 'No especificada', frecuencia: 'Según indicación', fecha_inicio: date });
  return { updated: true };
};

const normalizarHorarios = (entrada) => {
  if (Array.isArray(entrada)) {
    return entrada
      .map((item) => (typeof item === 'string' ? item.trim() : ''))
      .filter((item) => /^\d{1,2}:\d{2}$/.test(item))
      .map((item) => (item.length === 4 ? `0${item}` : item));
  }
  if (typeof entrada === 'string') {
    return entrada
      .split(',')
      .map((item) => item.trim())
      .filter((item) => /^\d{1,2}:\d{2}$/.test(item))
      .map((item) => (item.length === 4 ? `0${item}` : item));
  }
  return [];
};

const generarPlanRecordatoriosMedicamento = ({
  nombreMedicamento,
  frecuencia,
  horarios,
  fechaInicio,
  fechaFin,
  confirmadoPorUsuario
}) => {
  if (!confirmadoPorUsuario) return [];

  const horas = normalizarHorarios(horarios);
  if (horas.length === 0) return [];

  const plan = [];
  const fechaActual = new Date(`${fechaInicio}T00:00:00.000Z`);
  const limite = fechaFin ? new Date(`${fechaFin}T00:00:00.000Z`) : new Date(fechaActual);

  while (fechaActual <= limite) {
    const yyyyMmDd = fechaActual.toISOString().split('T')[0];
    for (const hora of horas) {
      plan.push({
        titulo: `Tomar ${nombreMedicamento}`,
        descripcion: `Dosis programada: ${frecuencia}`,
        fecha_programada: `${yyyyMmDd}T${hora}:00.000Z`,
        tipo: 'MEDICAMENTO'
      });
    }
    fechaActual.setUTCDate(fechaActual.getUTCDate() + 1);
  }

  return plan;
};

const saveMedicalInterview = async (usuarioId, payload) => {
  const usersRepo = require('../users/users.repository');
  let birthDate = payload.fecha_nacimiento;
  if (!birthDate && payload.edad != null) {
    const birthYear = new Date().getFullYear() - payload.edad;
    birthDate = `${birthYear}-01-01`;
  }

  await usersRepo.actualizarPerfil(usuarioId, {
    ...(birthDate ? { fecha_nacimiento: birthDate } : {}),
    sexo: payload.sexo,
    peso: payload.peso || null,
    altura: payload.altura || null,
    fuma: payload.fuma || 'NO',
    alcohol: payload.alcohol || 'NO',
    actividad_fisica: payload.actividad_fisica || 'MODERADA',
    entrevista_completada: true
  });

  await Promise.all([
    medicalRepo.eliminarHistorial(usuarioId),
    medicalRepo.eliminarAlergias(usuarioId),
    medicalRepo.eliminarMedicamentos(usuarioId),
    medicalRepo.eliminarAntecedentes(usuarioId),
    medicalRepo.eliminarVacunas(usuarioId)
  ]);

  const date = new Date().toISOString().split('T')[0];
  if (Array.isArray(payload.enfermedades_cronicas)) {
    for (const condition of payload.enfermedades_cronicas) {
      if (condition && condition.trim()) {
        await createMedicalRecord(usuarioId, { nombre_condicion: condition.trim(), fecha_diagnostico: date, notas: 'Entrevista médica inicial' });
      }
    }
  }

  if (Array.isArray(payload.antecedentes_hereditarios)) {
    for (const condition of payload.antecedentes_hereditarios) {
      if (condition && condition.trim()) {
        await createFamilyHistory(usuarioId, { parentesco: 'Familiar', nombre_condicion: condition.trim(), notas: 'Entrevista médica inicial' });
      }
    }
  }

  if (Array.isArray(payload.alergias)) {
    for (const allergy of payload.alergias) {
      if (allergy && allergy.trim()) {
        await createAllergy(usuarioId, { alergeno: allergy.trim(), severidad: 'LEVE', notas: 'Entrevista médica inicial' });
      }
    }
  }

  if (payload.medicamentos && payload.medicamentos.trim()) {
    await createMedication(usuarioId, { nombre_medicamento: payload.medicamentos.trim(), dosis: 'No especificada', frecuencia: 'Según indicación', fecha_inicio: date });
  }

  if (Array.isArray(payload.vacunas)) {
    for (const vac of payload.vacunas) {
      if (vac && vac.trim()) {
        await medicalRepo.crearVacuna(usuarioId, { nombre_vacuna: vac.trim(), fecha_aplicacion: date, numero_dosis: 1 });
      }
    }
  }

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'perfiles',
    idEntidad: usuarioId,
    accion: 'ENTREVISTA_MEDICA_COMPLETADA',
    detalle: { completada: true, fecha: date }
  });

  return { success: true, entrevista_completada: true };
};

module.exports = {
  getMedicalHistory,
  createMedicalRecord,
  getAllergies,
  createAllergy,
  getMedications,
  createMedication,
  getFamilyHistory,
  createFamilyHistory,
  replaceSurvey,
  saveMedicalInterview,
  normalizarHorarios,
  generarPlanRecordatoriosMedicamento
};
