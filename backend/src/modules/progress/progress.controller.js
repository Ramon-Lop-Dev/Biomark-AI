// Expone el seguimiento de evolución del usuario autenticado.
const progressService = require('./progress.service');
const asyncHandler = require('../../utils/asyncHandler');

const getProgress = asyncHandler(async (req, res) => {
  const data = await progressService.getProgress(req.usuarioId);
  return res.status(200).json(data);
});

const createProgress = asyncHandler(async (req, res) => {
  const data = await progressService.createProgress(req.usuarioId, req.body);
  return res.status(201).json(data);
});

module.exports = { getProgress, createProgress };
