const epidemiologyService = require('./epidemiology.service');
const asyncHandler = require('../../utils/asyncHandler');
const AppError = require('../../utils/AppError');

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const getAlerts = asyncHandler(async (req, res) => {
    const { zona_riesgo_id } = req.query;

    if (zona_riesgo_id && !UUID_REGEX.test(zona_riesgo_id)) {
        throw new AppError('zona_riesgo_id debe ser un UUID válido', 400);
    }

    const data = await epidemiologyService.getAlerts(zona_riesgo_id);
    return res.status(200).json(data);
});

const getRiskMap = asyncHandler(async (req, res) => {
    const data = await epidemiologyService.getRiskMap();
    return res.status(200).json(data);
});

// POST /api/epidemiology/reports
const createReport = asyncHandler(async (req, res) => {
    const reporte = await epidemiologyService.createReport(req.usuarioId, req.body);
    return res.status(201).json(reporte);
});

// POST /api/epidemiology/alerts
const createAlert = asyncHandler(async (req, res) => {
    const alerta = await epidemiologyService.createAlert(req.usuarioId, req.body);
    return res.status(201).json(alerta);
});

// PATCH /api/epidemiology/risk-map/:id
const updateRiskZoneLevel = asyncHandler(async (req, res) => {
    const { id } = req.params;

    if (!UUID_REGEX.test(id)) {
        throw new AppError('El id de la zona de riesgo debe ser un UUID válido', 400);
    }

    const data = await epidemiologyService.updateRiskZoneLevel(req.usuarioId, id, req.body.nivel_riesgo_actual);
    return res.status(200).json(data);
});

module.exports = { getAlerts, getRiskMap, createReport, createAlert, updateRiskZoneLevel };
