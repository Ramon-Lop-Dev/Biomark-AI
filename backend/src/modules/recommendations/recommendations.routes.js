// Define rutas públicas y de promotores/administradores para recomendaciones de salud.
const express = require('express');
const {
  getRecommendations,
  getRecommendationById,
  createRecommendation,
  updateRecommendation,
  deleteRecommendation
} = require('./recommendations.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { requireRole } = require('../../middleware/rbac.middleware');
const { validate } = require('../../middleware/validate.middleware');
const {
  createRecommendationSchema,
  updateRecommendationSchema
} = require('./recommendations.validator');

const router = express.Router();

// Todas las rutas requieren usuario autenticado
router.use(verifyToken);

// Lectura: Cualquier usuario autenticado puede consultar las recomendaciones validadas
router.get('/', getRecommendations);
router.get('/:id', getRecommendationById);

// Gestión: Exclusiva para personal de salud validado (TRABAJADOR_SALUD, PROMOTOR, ADMIN)
router.post(
  '/',
  requireRole('TRABAJADOR_SALUD', 'PROMOTOR', 'ADMIN'),
  validate(createRecommendationSchema),
  createRecommendation
);

router.put(
  '/:id',
  requireRole('TRABAJADOR_SALUD', 'PROMOTOR', 'ADMIN'),
  validate(updateRecommendationSchema),
  updateRecommendation
);

router.delete(
  '/:id',
  requireRole('TRABAJADOR_SALUD', 'PROMOTOR', 'ADMIN'),
  deleteRecommendation
);

module.exports = router;
