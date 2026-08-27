// Consulta centros y eventos geolocalizados desde Supabase.
const supabase = require('../../config/supabase');

const listarCentrosSalud = () =>
  supabase
    .from('centros_salud')
    .select('*')
    .order('nombre', { ascending: true });

// Solo eventos con coordenadas cargadas (latitud/longitud pueden ser null
// — ver migración 001, columnas nullable por compatibilidad) y que todavía
// no ocurrieron: un evento pasado no sirve para un aviso de "jornada
// cercana". Si en el futuro se quiere mostrar también el historial de
// eventos pasados en el mapa, este filtro de fecha es lo único que hay
// que quitar.
const listarEventosComunitariosConCoordenadas = () =>
  supabase
    .from('eventos_comunitarios')
    .select('*')
    .not('latitud', 'is', null)
    .not('longitud', 'is', null)
    .gte('fecha_evento', new Date().toISOString())
    .order('fecha_evento', { ascending: true });

module.exports = { listarCentrosSalud, listarEventosComunitariosConCoordenadas };
