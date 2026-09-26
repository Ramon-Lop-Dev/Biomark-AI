// Persiste y consulta notificaciones del usuario desde Supabase.
const supabase = require('../../config/supabase');

const crear = async ({ usuarioId, tipo, mensaje, titulo, datosAdicionales }) => {
  const payloadCompleto = {
    usuario_id: usuarioId,
    tipo,
    mensaje,
    titulo: titulo || null,
    datos_adicionales: datosAdicionales || {}
  };

  try {
    const res = await supabase.from('notificaciones').insert(payloadCompleto).select().single();
    if (!res.error) return res;
  } catch (_) {}

  // Fallback si la tabla aún tiene el esquema base sin columnas nuevas
  return supabase
    .from('notificaciones')
    .insert({
      usuario_id: usuarioId,
      tipo,
      mensaje
    })
    .select()
    .single();
};

const listarPorUsuario = async (usuarioId, { limit = 30, offset = 0, soloNoLeidas = false } = {}) => {
  let query = supabase
    .from('notificaciones')
    .select('*', { count: 'exact' })
    .eq('usuario_id', usuarioId);

  if (soloNoLeidas) {
    query = query.is('fecha_lectura', null);
  }

  return query
    .order('fecha_creacion', { ascending: false })
    .range(offset, offset + limit - 1);
};

const marcarLeida = async (usuarioId, notificacionId) => {
  const ahora = new Date().toISOString();
  try {
    const res = await supabase
      .from('notificaciones')
      .update({ fecha_lectura: ahora, leida: true })
      .eq('id', notificacionId)
      .eq('usuario_id', usuarioId)
      .select()
      .single();
    if (!res.error) return res;
  } catch (_) {}

  // Fallback si la columna leida no existe en la BD
  return supabase
    .from('notificaciones')
    .update({ fecha_lectura: ahora })
    .eq('id', notificacionId)
    .eq('usuario_id', usuarioId)
    .select()
    .single();
};

const marcarTodasLeidas = async (usuarioId) => {
  const ahora = new Date().toISOString();
  try {
    const res = await supabase
      .from('notificaciones')
      .update({ fecha_lectura: ahora, leida: true })
      .eq('usuario_id', usuarioId)
      .is('fecha_lectura', null);
    if (!res.error) return res;
  } catch (_) {}

  return supabase
    .from('notificaciones')
    .update({ fecha_lectura: ahora })
    .eq('usuario_id', usuarioId)
    .is('fecha_lectura', null);
};

const contarNoLeidas = (usuarioId) =>
  supabase
    .from('notificaciones')
    .select('id', { count: 'exact', head: true })
    .eq('usuario_id', usuarioId)
    .is('fecha_lectura', null);

module.exports = {
  crear,
  listarPorUsuario,
  marcarLeida,
  marcarTodasLeidas,
  contarNoLeidas
};
