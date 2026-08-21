const express = require('express');
const { getEvents, createEvent, createReport, getStatistics, getHeatmap } = require('./community.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const router = express.Router();

// GET /api/community/events es publico (consultar jornadas no requiere login);
// crear evento, reportar y ver estadisticas si requiere autenticacion.
router.get('/events', getEvents);
router.post('/events', verifyToken, createEvent);
router.post('/reports', verifyToken, createReport);
router.get('/statistics', verifyToken, getStatistics);
router.get('/heatmap', verifyToken, getHeatmap);

module.exports = router;
