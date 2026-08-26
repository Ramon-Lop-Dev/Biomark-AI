const symptomsService = require('./symptoms.service');
const asyncHandler = require('../../utils/asyncHandler');

const getSymptoms = asyncHandler(async (req, res) => {
    const data = await symptomsService.getSymptoms(req.usuarioId);
    return res.status(200).json(data);
});

const addSymptom = asyncHandler(async (req, res) => {
    const registro = await symptomsService.addSymptom(req.usuarioId, req.body);
    return res.status(201).json(registro);
});

module.exports = { getSymptoms, addSymptom };
