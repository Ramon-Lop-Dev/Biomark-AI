const communityService = require('./community.service');
const asyncHandler = require('../../utils/asyncHandler');
const AppError = require('../../utils/AppError');

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// GET /api/community/events
const getEvents = asyncHandler(async (req, res) => {
    const data = await communityService.getEvents();
    return res.status(200).json(data);
});

// POST /api/community/events
const createEvent = asyncHandler(async (req, res) => {
    const evento = await communityService.createEvent(req.usuarioId, req.body);
    return res.status(201).json(evento);
});

// POST /api/community/reports
const createReport = asyncHandler(async (req, res) => {
    const resultado = await communityService.createReport(req.usuarioId, req.body);
    return res.status(201).json(resultado);
});

// GET /api/community/statistics
const getStatistics = asyncHandler(async (req, res) => {
    const resumen = await communityService.getStatistics();
    return res.status(200).json(resumen);
});

// GET /api/community/heatmap
const getHeatmap = asyncHandler(async (req, res) => {
    const puntos = await communityService.getHeatmap();
    return res.status(200).json(puntos);
});

// PATCH /api/community/reports/:id/estado
const updateReportStatus = asyncHandler(async (req, res) => {
    const { id } = req.params;

    if (!UUID_REGEX.test(id)) {
        throw new AppError('El id del reporte debe ser un UUID válido', 400);
    }

    const data = await communityService.updateReportStatus(req.usuarioId, id, req.body.estado);
    return res.status(200).json(data);
});

module.exports = { getEvents, createEvent, createReport, getStatistics, getHeatmap, updateReportStatus };
