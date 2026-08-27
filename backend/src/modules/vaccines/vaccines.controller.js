// Atiende vacunas registradas y próximas dosis del usuario.
const vaccinesService = require('./vaccines.service');
const asyncHandler = require('../../utils/asyncHandler');

const getVaccines = asyncHandler(async (req, res) => {
    const data = await vaccinesService.getVaccines(req.usuarioId);
    return res.status(200).json(data);
});

const addVaccine = asyncHandler(async (req, res) => {
    const registro = await vaccinesService.addVaccine(req.usuarioId, req.body);
    return res.status(201).json(registro);
});

const getRecommendations = asyncHandler(async (req, res) => {
    return res.status(200).json(await vaccinesService.getRecommendations(req.usuarioId));
});

module.exports = { getVaccines, addVaccine, getRecommendations };
