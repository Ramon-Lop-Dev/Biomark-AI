// Consulta y actualiza recordatorios propiedad del usuario.
const supabase = require('../../config/supabase');

const normalizarRegistro = (reg) => {
  if (!reg) return reg;
  let freq = reg.frecuencia;
  let desc = reg.descripcion || '';

  if (desc.includes('[FREQ:HORARIA]')) {
    freq = 'HORARIA';
    desc = desc.replace('[FREQ:HORARIA]', '').trim();
  } else if (desc.includes('[FREQ:QUINCENAL]')) {
    freq = 'QUINCENAL';
    desc = desc.replace('[FREQ:QUINCENAL]', '').trim();
  }

  return {
    ...reg,
    frecuencia: freq,
    descripcion: desc
  };
};

const listarPorUsuario = async (usuarioId) => {
  const { data, error } = await supabase
    .from('recordatorios')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha_programada', { ascending: true });

  return {
    data: data ? data.map(normalizarRegistro) : null,
    error
  };
};

const crear = async (usuarioId, { titulo, descripcion, fecha_programada, tipo, frecuencia, aviso_previo, fecha_notificacion }) => {
  const reqFrecuencia = frecuencia || 'UNA_VEZ';
  const reqAviso = aviso_previo || 'AL_MOMENTO';
  const reqFechaNotif = fecha_notificacion || fecha_programada;

  // 1. Intentar inserción directa normal
  let { data, error } = await supabase
    .from('recordatorios')
    .insert([{
      usuario_id: usuarioId,
      titulo,
      descripcion,
      fecha_programada,
      tipo,
      frecuencia: reqFrecuencia,
      aviso_previo: reqAviso,
      fecha_notificacion: reqFechaNotif
    }])
    .select();

  // 2. Si Postgres rechaza el enum por no soportar HORARIA o QUINCENAL aún:
  if (error && (error.message?.includes('frecuencia_recordatorio') || error.details?.includes('frecuencia_recordatorio'))) {
    console.warn(`[RemindersRepo] Postgres enum frecuencia_recordatorio no soporta '${reqFrecuencia}' en BD. Aplicando fallback compatible.`);
    const fallbackEnum = reqFrecuencia === 'HORARIA' ? 'DIARIA' : reqFrecuencia === 'QUINCENAL' ? 'SEMANAL' : 'UNA_VEZ';
    const tag = `[FREQ:${reqFrecuencia}]`;
    const safeDesc = descripcion ? `${tag} ${descripcion}` : tag;

    const fallbackResult = await supabase
      .from('recordatorios')
      .insert([{
        usuario_id: usuarioId,
        titulo,
        descripcion: safeDesc,
        fecha_programada,
        tipo,
        frecuencia: fallbackEnum,
        aviso_previo: reqAviso,
        fecha_notificacion: reqFechaNotif
      }])
      .select();

    if (!fallbackResult.error && fallbackResult.data) {
      data = fallbackResult.data.map(normalizarRegistro);
      error = null;
    } else {
      error = fallbackResult.error;
    }
  }

  if (data) {
    data = data.map(normalizarRegistro);
  }

  return { data, error };
};

// Se filtra por usuario_id además de por id para prevenir modificaciones cruzadas.
const actualizarEstado = async (usuarioId, recordatorioId, estado) => {
  const { data, error } = await supabase
    .from('recordatorios')
    .update({ estado })
    .eq('id', recordatorioId)
    .eq('usuario_id', usuarioId)
    .select()
    .maybeSingle();

  return { data: data ? normalizarRegistro(data) : null, error };
};

const marcarEnviado = async (recordatorioId) => {
  // Consultar el recordatorio para ver su frecuencia y estado
  const { data: recordatorio, error: errFetch } = await supabase
    .from('recordatorios')
    .select('*')
    .eq('id', recordatorioId)
    .maybeSingle();

  if (errFetch || !recordatorio) return { data: null, error: errFetch };

  const norm = normalizarRegistro(recordatorio);

  // Si es recurrente (HORARIA, DIARIA, SEMANAL, QUINCENAL, MENSUAL),
  // NO se marca como 'ENVIADO' porque debe continuar en estado 'PENDIENTE'
  // para los siguientes ciclos!
  if (norm.frecuencia && norm.frecuencia !== 'UNA_VEZ') {
    return { data: norm, error: null };
  }

  // Si es 'UNA_VEZ' y todavía está en fase de pre-aviso, mantenerlo en PENDIENTE
  // para que suene a la hora exacta
  if (norm.fecha_notificacion && norm.fecha_programada && new Date(norm.fecha_notificacion) < new Date(norm.fecha_programada)) {
    return { data: norm, error: null };
  }

  // Si es 'UNA_VEZ' a la hora exacta, marcar como ENVIADO
  const { data, error } = await supabase
    .from('recordatorios')
    .update({ estado: 'ENVIADO' })
    .eq('id', recordatorioId)
    .eq('estado', 'PENDIENTE')
    .select()
    .maybeSingle();

  return { data: data ? normalizarRegistro(data) : null, error };
};

const listarVencidosPendientes = async (ahora = new Date().toISOString()) => {
  const { data, error } = await supabase
    .from('recordatorios')
    .select('*')
    .eq('estado', 'PENDIENTE')
    .or(`fecha_notificacion.lte.${ahora},and(fecha_notificacion.is.null,fecha_programada.lte.${ahora})`)
    .order('fecha_programada', { ascending: true });

  return {
    data: data ? data.map(normalizarRegistro) : null,
    error
  };
};

const reprogramarSiguienteCiclo = async (id, nuevaFecha, nuevaNotificacion) => {
  const payload = { fecha_programada: nuevaFecha };
  if (nuevaNotificacion) {
    payload.fecha_notificacion = nuevaNotificacion;
  }
  const { data, error } = await supabase
    .from('recordatorios')
    .update(payload)
    .eq('id', id)
    .select()
    .maybeSingle();

  return { data: data ? normalizarRegistro(data) : null, error };
};

module.exports = {
  listarPorUsuario,
  crear,
  actualizarEstado,
  marcarEnviado,
  listarVencidosPendientes,
  reprogramarSiguienteCiclo,
  normalizarRegistro
};

