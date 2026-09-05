const supabase = require('../../config/supabase');

const listarPorUsuario = (usuarioId) =>
  supabase
    .from('objetivos_mejoria')
    .select('*, hitos_mejoria(*)')
    .eq('usuario_id', usuarioId)
    .order('fecha_creacion', { ascending: false });

const crearObjetivo = (usuarioId, payload) =>
  supabase
    .from('objetivos_mejoria')
    .insert([{ usuario_id: usuarioId, ...payload }])
    .select()
    .single();

const crearHitos = (hitos) =>
  supabase.from('hitos_mejoria').insert(hitos).select();

const obtenerObjetivo = (usuarioId, objetivoId) =>
  supabase.from('objetivos_mejoria').select('id').eq('id', objetivoId).eq('usuario_id', usuarioId).maybeSingle();

const actualizarHito = (objetivoId, hitoId, completado) =>
  supabase
    .from('hitos_mejoria')
    .update({ completado, fecha_completado: completado ? new Date().toISOString() : null })
    .eq('id', hitoId)
    .eq('objetivo_id', objetivoId)
    .select()
    .maybeSingle();

module.exports = { listarPorUsuario, crearObjetivo, crearHitos, obtenerObjetivo, actualizarHito };