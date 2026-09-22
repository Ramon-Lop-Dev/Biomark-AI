// Persiste y consulta notificaciones del usuario desde Supabase.
const supabase = require('../../config/supabase');

const crear = ({ usuarioId, tipo, mensaje, titulo, datosAdicionales }) =>
  supabase
    .from('notificaciones')
    .insert({
      usuario_id: usuarioId,
      tipo,
      mensaje,
      titulo: titulo || null,
      datos_adicionales: datosAdicionales || {}
    })
    .select()
    .single();

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

const marcarLeida = (usuarioId, notificacionId) =>
  supabase
    .from('notificaciones')
    .update({ fecha_lectura: new Date().toISOString(), leida: true })
    .eq('id', notificacionId)
    .eq('usuario_id', usuarioId)
    .select()
    .single();

const marcarTodasLeidas = (usuarioId) =>
  supabase
    .from('notificaciones')
    .update({ fecha_lectura: new Date().toISOString(), leida: true })
    .eq('usuario_id', usuarioId)
    .is('fecha_lectura', null);

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
