// Consulta y actualiza recordatorios propiedad del usuario.
const supabase = require('../../config/supabase');

const listarPorUsuario = (usuarioId) =>
  supabase
    .from('recordatorios')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha_programada', { ascending: true });

const crear = (usuarioId, { titulo, descripcion, fecha_programada, tipo, frecuencia, aviso_previo, fecha_notificacion }) =>
  supabase
    .from('recordatorios')
    .insert([{
      usuario_id: usuarioId,
      titulo,
      descripcion,
      fecha_programada,
      tipo,
      frecuencia: frecuencia || 'UNA_VEZ',
      aviso_previo: aviso_previo || 'AL_MOMENTO',
      fecha_notificacion: fecha_notificacion || fecha_programada
    }])
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

const marcarEnviado = (recordatorioId) =>
  supabase
    .from('recordatorios')
    .update({ estado: 'ENVIADO' })
    .eq('id', recordatorioId)
    .eq('estado', 'PENDIENTE')
    .select()
    .maybeSingle();

const listarVencidosPendientes = (ahora = new Date().toISOString()) =>
  supabase
    .from('recordatorios')
    .select('*')
    .eq('estado', 'PENDIENTE')
    .or(`fecha_notificacion.lte.${ahora},and(fecha_notificacion.is.null,fecha_programada.lte.${ahora})`)
    .order('fecha_programada', { ascending: true });

const reprogramarSiguienteCiclo = (id, nuevaFecha, nuevaNotificacion) => {
  const payload = { fecha_programada: nuevaFecha };
  if (nuevaNotificacion) {
    payload.fecha_notificacion = nuevaNotificacion;
  }
  return supabase
    .from('recordatorios')
    .update(payload)
    .eq('id', id)
    .select()
    .maybeSingle();
};

module.exports = {
  listarPorUsuario,
  crear,
  actualizarEstado,
  marcarEnviado,
  listarVencidosPendientes,
  reprogramarSiguienteCiclo
};
