const goalsService = require('./goals.service');
const asyncHandler = require('../../utils/asyncHandler');
const AppError = require('../../utils/AppError');

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const getGoals = asyncHandler(async (req, res) => {
  res.status(200).json(await goalsService.getGoals(req.usuarioId));
});

const createGoal = asyncHandler(async (req, res) => {
  res.status(201).json(await goalsService.createGoal(req.usuarioId, req.body));
});

const updateMilestone = asyncHandler(async (req, res) => {
  const { objetivoId, hitoId } = req.params;
  if (!UUID_REGEX.test(objetivoId) || !UUID_REGEX.test(hitoId)) {
    throw new AppError('Los ids del objetivo y hito deben ser UUID válidos', 400);
  }
  res.status(200).json(await goalsService.updateMilestone(
    req.usuarioId,
    objetivoId,
    hitoId,
    req.body.completado
  ));
});

module.exports = { getGoals, createGoal, updateMilestone };