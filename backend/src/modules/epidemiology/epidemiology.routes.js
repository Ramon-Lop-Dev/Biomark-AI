// Define rutas públicas y administrativas de epidemiología.
const express = require('express');
const { getAlerts, getRiskMap, createReport, createAlert, updateRiskZoneLevel } = require('./epidemiology.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { requireRole } = require('../../middleware/rbac.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { createReportSchema, createAlertSchema, updateRiskZoneLevelSchema } = require('./epidemiology.validator');
const router = express.Router();

router.use(verifyToken);

// Lectura: cualquier usuario autenticado puede consultar alertas y el
// mapa de riesgo (es información de salud pública para la comunidad).
router.get('/alerts', getAlerts);
router.get('/risk-map', getRiskMap);

// Escritura: ingestión de datos epidemiológicos requiere criterio clínico
// o autoridad sanitaria — se restringe a TRABAJADOR_SALUD/ADMIN. Un
// USUARIO normal no debe poder declarar un brote o subir el nivel de
// riesgo de una zona entera.
router.post(
  '/reports',
  requireRole('TRABAJADOR_SALUD', 'ADMIN'),
  validate(createReportSchema),
  createReport
);

router.post(
  '/alerts',
  requireRole('TRABAJADOR_SALUD', 'ADMIN'),
  validate(createAlertSchema),
  createAlert
);

router.patch(
  '/risk-map/:id',
  requireRole('TRABAJADOR_SALUD', 'ADMIN'),
  validate(updateRiskZoneLevelSchema),
  updateRiskZoneLevel
);

module.exports = router;
