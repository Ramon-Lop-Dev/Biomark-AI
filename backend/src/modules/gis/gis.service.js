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
  const { data, error } = await gisRepo.listarCentrosSalud();
  if (error) throw new AppError('Error al obtener centros de salud', 500);

  if (!data || data.length === 0) return [];

  return data
    .map((centro) => ({
      ...centro,
      distancia_km: Math.round(distanciaKm(latitude, longitude, centro.latitud, centro.longitud) * 10) / 10
    }))
    .filter((centro) => centro.distancia_km <= radiusKm)
    .sort((a, b) => a.distancia_km - b.distancia_km);
};

/**
 * Devuelve los eventos comunitarios futuros (con coordenadas cargadas)
 * ordenados por cercanía a una coordenada, filtrados a un radio máximo
 * (por defecto 15 km) — mismo patrón que getNearbyHealthCenters: traer
 * todo en memoria y calcular Haversine es suficiente para el volumen
 *
 */
const getNearbyCommunityEvents = async (latitude, longitude, radiusKm = 15) => {
  const { data, error } = await gisRepo.listarEventosComunitariosConCoordenadas();
  if (error) throw new AppError('Error al obtener eventos comunitarios', 500);

  if (!data || data.length === 0) return [];

  return data
    .map((evento) => ({
      ...evento,
      distancia_km: Math.round(distanciaKm(latitude, longitude, evento.latitud, evento.longitud) * 10) / 10
    }))
    .filter((evento) => evento.distancia_km <= radiusKm)
    .sort((a, b) => a.distancia_km - b.distancia_km);
};

/**
 * Devuelve las zonas de riesgo ordenadas por cercanía a una coordenada,
 * filtradas a un radio máximo (por defecto 15 km) — mismo patrón que las
 * otras dos funciones "nearby". zonas_riesgo ya tiene su propio radio_km
 * (el área que la zona cubre), que no se toca acá: lo que se filtra es la
 * distancia del usuario al centro de la zona, igual que con centros y
 * eventos, para mantener un único criterio de "qué entra al radio
 * pedido" en las tres capas.
 */
const getNearbyRiskZones = async (latitude, longitude, radiusKm = 15) => {
  const { data, error } = await epidemiologyRepo.listarZonasRiesgo();
  if (error) throw new AppError('Error al obtener zonas de riesgo', 500);

  if (!data || data.length === 0) return [];

  return data
    .map((zona) => ({
      ...zona,
      distancia_km: Math.round(distanciaKm(latitude, longitude, zona.latitud, zona.longitud) * 10) / 10
    }))
    .filter((zona) => zona.distancia_km <= radiusKm)
    .sort((a, b) => a.distancia_km - b.distancia_km);
};

/**
 * Endpoint combinado de "capas del mapa" :
 * una sola llamada que devuelve las tres capas geolocalizadas dentro del
 * mismo radio, en vez de que Flutter tenga que hacer 3 llamadas separadas
 * y ensamblarlas del lado del cliente. Reutiliza las tres funciones
 * "nearby" ya existentes — no duplica la lógica de distancia/filtro.
 */
const getMapLayers = async (latitude, longitude, radiusKm = 15) => {
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

module.exports = {
  getHealthCenters,
  getNearbyHealthCenters,
  getNearbyCommunityEvents,
  getNearbyRiskZones,
  getMapLayers
  ,recommendNavigation
};