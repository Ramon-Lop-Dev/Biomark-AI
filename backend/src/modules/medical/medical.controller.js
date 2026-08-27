// Atiende las operaciones HTTP del expediente médico.
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

const getAllergies = asyncHandler(async (req, res) => {
    const data = await medicalService.getAllergies(req.usuarioId);
    return res.status(200).json(data);
});

const createAllergy = asyncHandler(async (req, res) => {
    const registro = await medicalService.createAllergy(req.usuarioId, req.body);
    return res.status(201).json(registro);
});

const getMedications = asyncHandler(async (req, res) => {
    const data = await medicalService.getMedications(req.usuarioId);
    return res.status(200).json(data);
});

const createMedication = asyncHandler(async (req, res) => {
    const registro = await medicalService.createMedication(req.usuarioId, req.body);
    return res.status(201).json(registro);
});

const getFamilyHistory = asyncHandler(async (req, res) => {
    const data = await medicalService.getFamilyHistory(req.usuarioId);
    return res.status(200).json(data);
});

const createFamilyHistory = asyncHandler(async (req, res) => {
    const registro = await medicalService.createFamilyHistory(req.usuarioId, req.body);
    return res.status(201).json(registro);
});

module.exports = {
    getMedicalHistory,
    createMedicalRecord,
    getAllergies,
    createAllergy,
    getMedications,
    createMedication,
    getFamilyHistory,
    createFamilyHistory
};
