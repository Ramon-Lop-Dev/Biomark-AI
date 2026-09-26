const express = require('express');
const {
  getHealthContent,
  getHealthContentDetails,
  ingestContent
} = require('./content.controller');
const { validate } = require('../../middleware/validate.middleware');
const { queryContentSchema, ingestContentSchema } = require('./content.validator');
const { verifyToken } = require('../../middleware/auth.middleware');
const { requireRole } = require('../../middleware/rbac.middleware');

const router = express.Router();

// Consulta pública o para usuarios de la app móvil
router.get('/', validate(queryContentSchema, 'query'), getHealthContent);
router.get('/:id', getHealthContentDetails);

// Endpoint de ingesta para automatizaciones (n8n, webhook, o promotores/admin)
router.post(
  '/ingest',
  verifyToken,
  requireRole(['ADMIN', 'PROMOTOR', 'TRABAJADOR_SALUD']),
  validate(ingestContentSchema),
  ingestContent
);

module.exports = router;
