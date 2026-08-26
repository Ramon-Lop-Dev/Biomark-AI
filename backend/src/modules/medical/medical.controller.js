const medicalService = require('./medical.service');
const asyncHandler = require('../../utils/asyncHandler');

const getMedicalHistory = asyncHandler(async (req, res) => {
    const data = await medicalService.getMedicalHistory(req.usuarioId);
    return res.status(200).json(data);
});

const createMedicalRecord = asyncHandler(async (req, res) => {
    const registro = await medicalService.createMedicalRecord(req.usuarioId, req.body);
    return res.status(201).json(registro);
});

module.exports = { getMedicalHistory, createMedicalRecord };
