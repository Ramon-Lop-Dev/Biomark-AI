const communityService = require('./community.service');
const asyncHandler = require('../../utils/asyncHandler');

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

module.exports = { getEvents, createEvent, createReport, getStatistics, getHeatmap };
