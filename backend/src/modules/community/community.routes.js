const express = require('express');
const { getEvents, createEvent, createReport, getStatistics, getHeatmap } = require('./community.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { createEventSchema, createReportSchema } = require('./community.validator');
const router = express.Router();

// GET /events es publico (consultar jornadas no requiere login);
// crear evento, reportar y ver estadisticas si requiere autenticacion.
//
// NOTA (pendiente de decisión de negocio, no aplicado aún): createEvent
// podría restringirse por rol con requireRole(...) (ver rbac.middleware.js)
// a LIDER_COMUNITARIO/PROMOTOR/ADMIN en vez de cualquier usuario
// autenticado — queda para cuando definas esa política.
router.get('/events', getEvents);
router.post('/events', verifyToken, validate(createEventSchema), createEvent);
router.post('/reports', verifyToken, validate(createReportSchema), createReport);
router.get('/statistics', verifyToken, getStatistics);
router.get('/heatmap', verifyToken, getHeatmap);

module.exports = router;
