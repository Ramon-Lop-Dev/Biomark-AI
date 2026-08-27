// Consulta y persiste historial, alergias, medicamentos y antecedentes.
const supabase = require('../../config/supabase');

const listarPorUsuario = (usuarioId) =>
  supabase
    .from('historial_medico')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha_creacion', { ascending: false });

const crearRegistro = (usuarioId, { nombre_condicion, fecha_diagnostico, notas }) =>
  supabase
    .from('historial_medico')
    .insert([{ usuario_id: usuarioId, nombre_condicion, fecha_diagnostico, notas }])
    .select();

// --- alergias ---

const listarAlergiasPorUsuario = (usuarioId) =>
  supabase
    .from('alergias')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha_creacion', { ascending: false });

const crearAlergia = (usuarioId, { alergeno, severidad, notas }) =>
  supabase
    .from('alergias')
    .insert([{ usuario_id: usuarioId, alergeno, severidad, notas }])
    .select();

// --- medicamentos ---

const listarMedicamentosPorUsuario = (usuarioId) =>
  supabase
    .from('medicamentos')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha_creacion', { ascending: false });

const crearMedicamento = (usuarioId, { nombre_medicamento, dosis, frecuencia, fecha_inicio, fecha_fin }) =>
  supabase
    .from('medicamentos')
    .insert([{ usuario_id: usuarioId, nombre_medicamento, dosis, frecuencia, fecha_inicio, fecha_fin }])
    .select();

// --- antecedentes_familiares ---

const listarAntecedentesPorUsuario = (usuarioId) =>
  supabase
    .from('antecedentes_familiares')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha_creacion', { ascending: false });

const crearAntecedente = (usuarioId, { parentesco, nombre_condicion, notas }) =>
  supabase
    .from('antecedentes_familiares')
    .insert([{ usuario_id: usuarioId, parentesco, nombre_condicion, notas }])
    .select();

module.exports = {
  listarPorUsuario,
  crearRegistro,
  listarAlergiasPorUsuario,
  crearAlergia,
  listarMedicamentosPorUsuario,
  crearMedicamento,
  listarAntecedentesPorUsuario,
  crearAntecedente
};
