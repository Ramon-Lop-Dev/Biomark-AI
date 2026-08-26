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

module.exports = { listarPorUsuario, crearRegistro };
