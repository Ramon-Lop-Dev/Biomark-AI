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

// Se filtra por usuario_id además de por id: sin esto, cualquier usuario
// autenticado podría cambiar el estado del recordatorio de otra persona
// con solo adivinar/enumerar el UUID (no hay RLS en Postgres que lo
// impida — ver auditoría Fase 1, punto 5.2 — así que este filtro es la
// única barrera real).
const actualizarEstado = (usuarioId, recordatorioId, estado) =>
  supabase
    .from('recordatorios')
    .update({ estado })
    .eq('id', recordatorioId)
    .eq('usuario_id', usuarioId)
    .select()
    .maybeSingle();

module.exports = { listarPorUsuario, crear, actualizarEstado };
