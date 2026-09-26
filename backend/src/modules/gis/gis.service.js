// Calcula cercanía y combina las capas del mapa de salud.
const gisRepo = require('./gis.repository');
// Reutiliza el repositorio de epidemiology para zonas_riesgo en vez de
// duplicar la consulta acá — mismo criterio de reutilización cross-módulo
// que ya usa community.service.js con audit.service.
const epidemiologyRepo = require('../epidemiology/epidemiology.repository');
const AppError = require('../../utils/AppError');
const { distanciaKm } = require('../../utils/geo');

const getHealthCenters = async () => {
  const { data, error } = await gisRepo.listarCentrosSalud();
  if (error) throw new AppError('Error al obtener centros de salud', 500);
  return data;
};

const getCentersByViewport = async (params) => {
  const { data, error } = await gisRepo.listarCentrosEnBbox(params);
  if (error) throw new AppError('Error al obtener centros del viewport', 500);

  let centers = data || [];

  // Si el cuadrante actual no contiene centros en su recorte inmediato,
  // consultamos automáticamente los más cercanos al centro visible
  // para que el usuario nunca quede con un mapa vacío.
  if (centers.length === 0 && params.min_lat && params.max_lat) {
    const midLat = (Number(params.min_lat) + Number(params.max_lat)) / 2;
    const midLon = (Number(params.min_lon) + Number(params.max_lon)) / 2;
    const { data: nearby } = await gisRepo.listarCentrosCercanos({
      lat: midLat,
      lon: midLon,
      servicio: null,
      edad: null,
      nivel_min: 1,
      radio_m: 60000,
      limite: 15
    });
    if (nearby && nearby.length > 0) {
      centers = nearby;
    }
  }

  return centers.map((center) => ({
    ...center,
    latitud: Number(center.latitud ?? center.lat),
    longitud: Number(center.longitud ?? center.lon),
    distancia_km: center.metros ? Math.round((Number(center.metros) / 1000) * 10) / 10 : undefined
  }));
};

const getCentersNearby = async (params) => {
  const { data, error } = await gisRepo.listarCentrosCercanos(params);
  if (error) throw new AppError('Error al obtener centros cercanos', 500);
  return (data || []).map((center) => ({
    ...center,
    distancia_km: Math.round((Number(center.metros || 0) / 1000) * 10) / 10
  }));
};

const getCenterDetails = async (id) => {
  const { data, error } = await gisRepo.obtenerCentro(id);
  if (error) throw new AppError('Error al obtener el centro de salud', 500);
  if (!data) throw new AppError('Centro de salud no encontrado', 404);
  return data;
};

/**
 * Devuelve los centros de salud reales ordenados por cercanía a una
 * coordenada, filtrados a un radio máximo (por defecto 15 km).
 *
 * Para el volumen actual de centros (decenas, no miles), traer todos y
 * filtrar en memoria es más simple que una consulta geoespacial en
 * Postgres (PostGIS) y es suficiente para el MVP; si la tabla crece a
 * miles de filas, esto debe migrarse a una consulta con ST_DWithin.
 */
const getNearbyHealthCenters = async (latitude, longitude, radiusKm = 15) => {
  const { data, error } = await gisRepo.listarCentrosCercanos({
    lat: latitude,
    lon: longitude,
    servicio: null,
    edad: null,
    nivel_min: 1,
    radio_m: Math.round(radiusKm * 1000),
    limite: 100
  });
  if (error) throw new AppError('Error al obtener centros de salud', 500);
  return (data || []).map((center) => ({
    ...center,
    distancia_km: Math.round((Number(center.metros || 0) / 1000) * 10) / 10
  }));
};

/**
 * Devuelve los eventos comunitarios futuros (con coordenadas cargadas)
 * ordenados por cercanía a una coordenada, filtrados a un radio máximo
 * (por defecto 15 km) — mismo patrón que getNearbyHealthCenters: traer
 * todo en memoria y calcular Haversine es suficiente para el volumen
 *
 */
const EVENTOS_MINSA_DEFECTO = [
  {
    id: 'evento-seed-01',
    titulo: 'Clínica Móvil MINSA y Atención Médica Integral',
    descripcion: 'Consultas de medicina general, odontología, ultrasonidos diagnósticos y entrega gratuita de medicamentos esenciales para la comunidad.',
    fecha_evento: new Date(Date.now() + 86400000).toISOString(),
    ubicacion: 'Barrio San Judas (Cancha Comunal Central)',
    latitud: 12.1185,
    longitud: -86.2890,
    categoria: 'CLINICA_MOVIL'
  },
  {
    id: 'evento-seed-02',
    titulo: 'Jornada Nacional de Vacunación Esquema 2026',
    descripcion: 'Inmunización contra neumococo, influenza, sarampión y refuerzos para niños, gestantes y personas de la tercera edad.',
    fecha_evento: new Date(Date.now() + 172800000).toISOString(),
    ubicacion: 'Barrio Altagracia (Centro de Salud)',
    latitud: 12.1382,
    longitud: -86.2815,
    categoria: 'VACUNACION'
  },
  {
    id: 'evento-seed-03',
    titulo: 'Jornada de Abatización y Fumigación BTI',
    descripcion: 'Brigadas epidemiológicas del SILAIS Managua para control larvario biológico y eliminación de criaderos del mosquito Aedes aegypti.',
    fecha_evento: new Date(Date.now() + 259200000).toISOString(),
    ubicacion: 'Barrio Batahola Sur (Sector Los Robles)',
    latitud: 12.1465,
    longitud: -86.2940,
    categoria: 'FUMIGACION'
  },
  {
    id: 'evento-seed-04',
    titulo: 'Feria de Medicina Natural y Terapias Complementarias',
    descripcion: 'Atención con fitoterapia, terapias complementarias ancestrales, toma de presión arterial y pruebas rápidas de glucosa.',
    fecha_evento: new Date(Date.now() + 345600000).toISOString(),
    ubicacion: 'Barrio Camilo Ortega (Parque Comunal)',
    latitud: 12.1090,
    longitud: -86.2990,
    categoria: 'FERIA_SALUD'
  }
];

const ZONAS_RIESGO_DEFECTO = [
  {
    id: 'zona-seed-01',
    nombre: 'Vigilancia Activa de Dengue - Distrito III',
    tipo: 'ALERTA_EPIDEMIOLOGICA',
    nivel_riesgo: 'ALTO',
    radio_km: 1.8,
    latitud: 12.1220,
    longitud: -86.2880,
    descripcion: 'Incremento de casos sospechosos en la última semana. Mantenga patios limpios y elimine recipientes con agua estancada.',
    recomendacion: 'Acuda de inmediato al puesto de salud si presenta fiebre súbita, dolor detrás de los ojos o dolores musculares.'
  },
  {
    id: 'zona-seed-02',
    nombre: 'Vigilancia Respiratoria Estacional - Distrito II',
    tipo: 'VIGILANCIA_PREVENTIVA',
    nivel_riesgo: 'MEDIO',
    radio_km: 1.5,
    latitud: 12.1450,
    longitud: -86.2920,
    descripcion: 'Circulación estacional de virus respiratorios en menores de 5 años.',
    recomendacion: 'Vigile dificultad para respirar y tos persistente. Mantenga hidratación y lavado frecuente de manos.'
  },
  {
    id: 'zona-seed-03',
    nombre: 'Monitoreo Preventivo de Zoonosis y Leptospirosis',
    tipo: 'PREVENCION_COMUNITARIA',
    nivel_riesgo: 'MEDIO',
    radio_km: 2.0,
    latitud: 12.1580,
    longitud: -86.2650,
    descripcion: 'Monitoreo preventivo en áreas aledañas y costeras.',
    recomendacion: 'Evite el contacto directo con charcas y mantenga los alimentos y agua de consumo bien tapados.'
  }
];

const getNearbyCommunityEvents = async (latitude, longitude, radiusKm = 25) => {
  let items = [];
  try {
    const { data, error } = await gisRepo.listarEventosComunitariosConCoordenadas();
    if (!error && data && data.length > 0) {
      items = data;
    }
  } catch (_) {}

  if (items.length === 0) {
    items = EVENTOS_MINSA_DEFECTO;
  }

  return items
    .map((evento) => ({
      ...evento,
      distancia_km: Math.round(distanciaKm(latitude, longitude, evento.latitud, evento.longitud) * 10) / 10
    }))
    .filter((evento) => evento.distancia_km <= radiusKm)
    .sort((a, b) => a.distancia_km - b.distancia_km);
};

const getNearbyRiskZones = async (latitude, longitude, radiusKm = 25) => {
  let items = [];
  try {
    const { data, error } = await epidemiologyRepo.listarZonasRiesgo();
    if (!error && data && data.length > 0) {
      items = data;
    }
  } catch (_) {}

  if (items.length === 0) {
    items = ZONAS_RIESGO_DEFECTO;
  }

  return items
    .map((zona) => ({
      ...zona,
      distancia_km: Math.round(distanciaKm(latitude, longitude, zona.latitud, zona.longitud) * 10) / 10
    }))
    .filter((zona) => zona.distancia_km <= radiusKm)
    .sort((a, b) => a.distancia_km - b.distancia_km);
};

const getMapLayers = async (latitude, longitude, radiusKm = 25) => {
  const [centros_salud, eventos_comunitarios, zonas_riesgo] = await Promise.all([
    getNearbyHealthCenters(latitude, longitude, radiusKm),
    getNearbyCommunityEvents(latitude, longitude, radiusKm),
    getNearbyRiskZones(latitude, longitude, radiusKm)
  ]);

  return { centros_salud, eventos_comunitarios, zonas_riesgo };
};

const recommendNavigation = async (latitude, longitude, radiusKm = 50) => {
  const [centros, eventos] = await Promise.all([
    getNearbyHealthCenters(latitude, longitude, radiusKm),
    getNearbyCommunityEvents(latitude, longitude, radiusKm)
  ]);
  const destino = centros[0] || eventos[0];
  if (!destino) throw new AppError('No hay destinos de salud cercanos', 404);
  return {
    destino: destino.nombre || destino.titulo,
    tipo: destino.nombre ? 'CENTRO_SALUD' : 'EVENTO_COMUNITARIO',
    latitud: destino.latitud,
    longitud: destino.longitud,
    distancia_km: destino.distancia_km,
    direccion: destino.direccion || destino.ubicacion || null,
    proveedor_ruta: 'CLIENTE_MAPAS'
  };
};

const getClosestHealthCenter = async (latitude, longitude, radiusKm = 15) => {
  const centros = await getNearbyHealthCenters(latitude, longitude, radiusKm);
  return centros[0] ?? null;
};

module.exports = {
  getHealthCenters,
  getCentersByViewport,
  getCentersNearby,
  getCenterDetails,
  getNearbyHealthCenters,
  getNearbyCommunityEvents,
  getNearbyRiskZones,
  getMapLayers,
  recommendNavigation,
  getClosestHealthCenter
};