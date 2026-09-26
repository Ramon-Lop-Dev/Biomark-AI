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
    .gte('fecha_evento', new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString())
    .order('fecha_evento', { ascending: true });

const listarCentrosEnBbox = async ({ min_lon, min_lat, max_lon, max_lat, nivel_min, zoom }) => {
  // 1. Intentar RPC PostGIS
  try {
    const rpcRes = await supabase.rpc('centros_en_bbox', {
      p_min_lon: min_lon,
      p_min_lat: min_lat,
      p_max_lon: max_lon,
      p_max_lat: max_lat,
      p_nivel_min: nivel_min || 1,
      p_zoom: zoom || 15
    });
    if (!rpcRes.error && rpcRes.data && rpcRes.data.length > 0) {
      return rpcRes;
    }
  } catch (_) {}

  // 2. Consulta directa por latitud/longitud en la tabla centros_salud (funciona aunque geog sea null)
  const { data: directData, error: directErr } = await supabase
    .from('centros_salud')
    .select('*')
    .eq('activo', true)
    .gte('latitud', min_lat)
    .lte('latitud', max_lat)
    .gte('longitud', min_lon)
    .lte('longitud', max_lon)
    .order('nivel_atencion', { ascending: false });

  if (!directErr && directData && directData.length > 0) {
    return { data: directData, error: null };
  }

  // 3. Fallback a centros de Managua para garantizar que siempre se visualicen en el mapa
  return supabase
    .from('centros_salud')
    .select('*')
    .eq('activo', true)
    .order('nivel_atencion', { ascending: false })
    .limit(60);
};

const listarCentrosCercanos = async ({ lat, lon, servicio, edad, nivel_min, radio_m, limite }) => {
  try {
    const rpcRes = await supabase.rpc('centros_cercanos', {
      p_lat: lat,
      p_lon: lon,
      p_servicio: servicio || null,
      p_edad: edad ?? null,
      p_nivel_min: nivel_min || 1,
      p_radio_m: radio_m || 15000,
      p_limite: limite || 20
    });
    if (!rpcRes.error && rpcRes.data && rpcRes.data.length > 0) {
      return rpcRes;
    }
  } catch (_) {}

  // Fallback: consulta directa a la tabla y ordenación por distancia Haversine
  const { data, error } = await supabase
    .from('centros_salud')
    .select('*')
    .eq('activo', true);

  if (error || !data) return { data: [], error };

  const { distanciaKm } = require('../../utils/geo');
  const calculados = data.map((c) => {
    const dKm = distanciaKm(lat, lon, Number(c.latitud), Number(c.longitud));
    return {
      ...c,
      metros: Math.round(dKm * 1000),
      distancia_km: Math.round(dKm * 10) / 10
    };
  });
  calculados.sort((a, b) => (a.metros || 0) - (b.metros || 0));
  return { data: calculados.slice(0, limite || 20), error: null };
};

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
