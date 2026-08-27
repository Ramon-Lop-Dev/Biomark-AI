const gisRepo = require('./gis.repository');
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

module.exports = { getHealthCenters, getNearbyHealthCenters };