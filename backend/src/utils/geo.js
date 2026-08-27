/**
 * Fórmula de Haversine: distancia en línea recta (km) entre dos
 * coordenadas. Misma lógica que ai-service/gis/locator.py — se mantiene
 * duplicada intencionalmente (Node y Python no comparten runtime), pero
 * ambas implementaciones deben coincidir si se modifica una.
 */
const distanciaKm = (lat1, lon1, lat2, lon2) => {
  const R = 6371;
  const toRad = (deg) => (deg * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;

  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

module.exports = { distanciaKm };