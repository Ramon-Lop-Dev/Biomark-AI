// Controlador HTTP para recomendaciones de salud.
const recommendationsService = require('./recommendations.service');

const getRecommendations = async (req, res, next) => {
  try {
    const { categoria, estado } = req.query;
    const recomendaciones = await recommendationsService.getRecommendations({ categoria, estado });
    res.status(200).json({
      success: true,
      data: recomendaciones
    });
  } catch (error) {
    next(error);
  }
};

const getRecommendationById = async (req, res, next) => {
  try {
    const { id } = req.params;
    const recomendacion = await recommendationsService.getRecommendationById(id);
    res.status(200).json({
      success: true,
      data: recomendacion
    });
  } catch (error) {
    next(error);
  }
};

const createRecommendation = async (req, res, next) => {
  try {
    const usuarioId = req.usuarioId;
    const nueva = await recommendationsService.createRecommendation(usuarioId, req.body);
    res.status(201).json({
      success: true,
      data: nueva,
      message: 'Recomendación médica creada y validada exitosamente'
    });
  } catch (error) {
    next(error);
  }
};

const updateRecommendation = async (req, res, next) => {
  try {
    const usuarioId = req.usuarioId;
    const { id } = req.params;
    const actualizada = await recommendationsService.updateRecommendation(usuarioId, id, req.body);
    res.status(200).json({
      success: true,
      data: actualizada,
      message: 'Recomendación actualizada correctamente'
    });
  } catch (error) {
    next(error);
  }
};

const deleteRecommendation = async (req, res, next) => {
  try {
    const usuarioId = req.usuarioId;
    const { id } = req.params;
    const resultado = await recommendationsService.deleteRecommendation(usuarioId, id);
    res.status(200).json({
      success: true,
      message: resultado.message
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getRecommendations,
  getRecommendationById,
  createRecommendation,
  updateRecommendation,
  deleteRecommendation
};
