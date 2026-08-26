const supabase = require('../../config/supabase');

const listarPorUsuario = (usuarioId) =>
  supabase
    .from('recordatorios')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha_programada', { ascending: true });

const crear = (usuarioId, { titulo, descripcion, fecha_programada, tipo }) =>
  supabase
    .from('recordatorios')
    .insert([{ usuario_id: usuarioId, titulo, descripcion, fecha_programada, tipo }])
    .select();

module.exports = { listarPorUsuario, crear };
