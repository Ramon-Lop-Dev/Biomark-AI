// Persiste el seguimiento de evolución confirmado por el usuario.
const supabase = require('../../config/supabase');

const listarPorUsuario = (usuarioId) =>
  supabase
    .from('seguimiento_salud')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha_registro', { ascending: false });

const crear = (usuarioId, payload) =>
  supabase
    .from('seguimiento_salud')
    .insert([{ usuario_id: usuarioId, ...payload }])
    .select()
    .single();

module.exports = { listarPorUsuario, crear };
