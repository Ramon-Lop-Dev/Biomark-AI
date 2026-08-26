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

module.exports = { getVaccines, addVaccine };
