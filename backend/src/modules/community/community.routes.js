const express = require('express');
const { getEvents, createEvent, createReport, getStatistics, getHeatmap, updateReportStatus } = require('./community.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { requireRole } = require('../../middleware/rbac.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { createEventSchema, createReportSchema, updateReportStatusSchema } = require('./community.validator');
const router = express.Router();

// GET /events es publico (consultar jornadas no requiere login);
// crear evento, reportar y ver estadisticas si requiere autenticacion.
//
// Política de negocio ya definida: organizar una jornada comunitaria es
// una acción de coordinación, no algo que cualquier usuario deba poder
// hacer — se restringe a quienes tienen un rol de organización real.
router.get('/events', getEvents);
router.post(
  '/events',
  verifyToken,
  requireRole('LIDER_COMUNITARIO', 'PROMOTOR', 'ADMIN'),
  validate(createEventSchema),
  createEvent
);

// Reportar un caso sospechoso sí debe quedar abierto a cualquier usuario
// autenticado (ese es el propósito del "modo comunitario": vigilancia
// desde la ciudadanía) — por eso NO lleva requireRole.
router.post('/reports', verifyToken, validate(createReportSchema), createReport);

// Validar/descartar un reporte comunitario sí requiere criterio clínico o
// de coordinación territorial: se restringe a quien puede confirmar que
// el reporte es real antes de que cuente en estadísticas/heatmap.
router.patch(
  '/reports/:id/estado',
  verifyToken,
  requireRole('TRABAJADOR_SALUD', 'LIDER_COMUNITARIO', 'ADMIN'),
  validate(updateReportStatusSchema),
  updateReportStatus
);

router.get('/statistics', verifyToken, getStatistics);
router.get('/heatmap', verifyToken, getHeatmap);

module.exports = router;
