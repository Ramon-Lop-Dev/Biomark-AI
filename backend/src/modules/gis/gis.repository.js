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

const listarCentrosEnBbox = ({ min_lon, min_lat, max_lon, max_lat, nivel_min, zoom }) =>
  supabase.rpc('centros_en_bbox', {
    p_min_lon: min_lon,
    p_min_lat: min_lat,
    p_max_lon: max_lon,
    p_max_lat: max_lat,
    p_nivel_min: nivel_min,
    p_zoom: zoom
  });

const listarCentrosCercanos = ({ lat, lon, servicio, edad, nivel_min, radio_m, limite }) =>
  supabase.rpc('centros_cercanos', {
    p_lat: lat,
    p_lon: lon,
    p_servicio: servicio || null,
    p_edad: edad ?? null,
    p_nivel_min: nivel_min,
    p_radio_m: radio_m,
    p_limite: limite
  });

const obtenerCentro = (id) =>
  supabase
    .from('centros_salud')
    .select('*, centro_servicios(codigo, edad_min, edad_max, catalogo_servicios(codigo, etiqueta, sinonimos)), centro_horarios(id, dia_semana, hora_apertura, hora_cierre, cerrado)')
    .eq('id', id)
    .eq('activo', true)
    .maybeSingle();

module.exports = {
  listarCentrosSalud,
  listarEventosComunitariosConCoordenadas,
  listarCentrosEnBbox,
  listarCentrosCercanos,
  obtenerCentro
};
