// Coordina creación y consulta de síntomas del usuario.
const symptomsRepo = require('./symptoms.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const getSymptoms = async (usuarioId) => {
  const { data, error } = await symptomsRepo.listarConRegistros(usuarioId);
  if (error) throw new AppError('Error al obtener los síntomas', 500);
  return data;
};

// El esquema real separa "sintomas" (nombre_sintoma, por usuario) de
// "registros_sintomas" (temperatura, presion_arterial, notas, url_foto).
// Este flujo: 1) busca si el usuario ya tiene un sintoma con ese nombre,
// 2) si no existe lo crea, 3) inserta el registro/observación asociado.
const addSymptom = async (usuarioId, { symptom, temperature, blood_pressure, notes, photo_url, date }) => {
  const { data: existente, error: buscarError } = await symptomsRepo.buscarPorNombre(usuarioId, symptom);
  if (buscarError) throw new AppError('Error al buscar el síntoma', 500);

  let sintomaId = existente?.id;
  let esNuevoSintoma = false;

  if (!sintomaId) {
    const { data: nuevo, error: crearError } = await symptomsRepo.crearSintoma(usuarioId, symptom);
    if (crearError) throw new AppError('Error al registrar el síntoma', 500);
    sintomaId = nuevo.id;
    esNuevoSintoma = true;
  }

  const { data, error } = await symptomsRepo.crearRegistroSintoma(sintomaId, {
    temperature, blood_pressure, notes, photo_url, date
  });
  if (error) throw new AppError('Error al registrar la observación del síntoma', 500);

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'sintomas',
    idEntidad: sintomaId,
    accion: esNuevoSintoma ? 'CREACION_SINTOMA' : 'NUEVA_OBSERVACION',
    detalle: { nombre_sintoma: symptom }
  });

  return { sintoma_id: sintomaId, ...data[0] };
};

// Alias de integración para guardar síntomas directamente en el historial clínico.
const guardarSintomasEnHistorial = async (usuarioId, payload) => addSymptom(usuarioId, payload);

module.exports = { getSymptoms, addSymptom, guardarSintomasEnHistorial };
