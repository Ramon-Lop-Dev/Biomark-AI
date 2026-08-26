const epidemiologyRepo = require('./epidemiology.repository');
const AppError = require('../../utils/AppError');

const getAlerts = async (zonaRiesgoId) => {
  const { data, error } = await epidemiologyRepo.listarAlertas(zonaRiesgoId);
  if (error) throw new AppError('Error al obtener alertas epidemiológicas', 500);
  return data;
};

const getRiskMap = async () => {
  const { data, error } = await epidemiologyRepo.listarZonasRiesgo();
  if (error) throw new AppError('Error al obtener el mapa de riesgo', 500);
  return data;
};

module.exports = { getAlerts, getRiskMap };
