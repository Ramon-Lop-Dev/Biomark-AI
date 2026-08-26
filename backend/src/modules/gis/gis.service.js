const gisRepo = require('./gis.repository');
const AppError = require('../../utils/AppError');

// NOTA: sin filtro geoespacial por cercanía todavía (queda para una fase
// posterior); por ahora solo lista todos los centros de salud.
const getHealthCenters = async () => {
  const { data, error } = await gisRepo.listarCentrosSalud();
  if (error) throw new AppError('Error al obtener centros de salud', 500);
  return data;
};

module.exports = { getHealthCenters };
