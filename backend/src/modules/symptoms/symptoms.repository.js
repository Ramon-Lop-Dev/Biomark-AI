// Consulta y persiste síntomas y sus observaciones.
const supabase = require('../../config/supabase');

const listarConRegistros = (usuarioId) =>
  supabase
    .from('sintomas')
    .select('id, nombre_sintoma, fecha_creacion, registros_sintomas(*)')
    .eq('usuario_id', usuarioId)
    .order('fecha_creacion', { ascending: false });

const buscarPorNombre = (usuarioId, nombreSintoma) =>
  supabase
    .from('sintomas')
    .select('id')
    .eq('usuario_id', usuarioId)
    .eq('nombre_sintoma', nombreSintoma)
    .maybeSingle();

const crearSintoma = (usuarioId, nombreSintoma) =>
  supabase
    .from('sintomas')
    .insert({ usuario_id: usuarioId, nombre_sintoma: nombreSintoma })
    .select('id')
    .single();

const crearRegistroSintoma = (sintomaId, { temperature, blood_pressure, notes, photo_url, date }) =>
  supabase
    .from('registros_sintomas')
    .insert([{
      sintoma_id: sintomaId,
      temperatura: temperature,
      presion_arterial: blood_pressure,
      notas: notes,
      url_foto: photo_url,
      fecha_registro: date || new Date().toISOString()
    }])
    .select();

module.exports = { listarConRegistros, buscarPorNombre, crearSintoma, crearRegistroSintoma };
