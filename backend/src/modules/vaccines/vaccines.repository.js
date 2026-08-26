const supabase = require('../../config/supabase');

const listarPorUsuario = (usuarioId) =>
  supabase
    .from('vacunas')
    .select('*')
    .eq('usuario_id', usuarioId)
    .order('fecha_aplicacion', { ascending: false });

const crear = (usuarioId, { nombre_vacuna, fecha_aplicacion, numero_dosis, fecha_proxima_dosis }) =>
  supabase
    .from('vacunas')
    .insert([{
      usuario_id: usuarioId,
      nombre_vacuna,
      fecha_aplicacion,
      numero_dosis: numero_dosis || 1,
      fecha_proxima_dosis
    }])
    .select();

module.exports = { listarPorUsuario, crear };
