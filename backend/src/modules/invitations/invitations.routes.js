const express = require('express');
const {
  createHealthWorkerInvitation,
  createPromoterInvitation,
  verifyInvitation,
  acceptInvitation,
  getMyPromoters,
  updatePromoterStatus
} = require('./invitations.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { requireRole } = require('../../middleware/rbac.middleware');
const { requireScope } = require('../../middleware/requireScope.middleware');
const { validate } = require('../../middleware/validate.middleware');
const {
  createHealthWorkerInvitationSchema,
  createPromoterInvitationSchema,
  acceptInvitationSchema,
  updatePromoterStatusSchema
} = require('./invitations.validator');

const router = express.Router();

// 1. ADMIN genera invitación a TRABAJADOR_SALUD fijando un centro de salud
router.post(
  '/health-worker',
  verifyToken,
  requireRole('ADMIN'),
  validate(createHealthWorkerInvitationSchema),
  createHealthWorkerInvitation
);

// 2. TRABAJADOR_SALUD o ADMIN genera invitación a PROMOTOR
router.post(
  '/promoter',
  verifyToken,
  requireRole('ADMIN', 'TRABAJADOR_SALUD'),
  validate(createPromoterInvitationSchema),
  createPromoterInvitation
);

// 3. TRABAJADOR_SALUD o ADMIN consulta los promotores de su centro y el historial de invitaciones
router.get(
  '/my-promoters',
  verifyToken,
  requireRole('TRABAJADOR_SALUD', 'ADMIN'),
  requireScope,
  getMyPromoters
);

// 4. TRABAJADOR_SALUD o ADMIN suspende o reactiva un promotor de su centro
router.patch(
  '/promoters/:id/status',
  verifyToken,
  requireRole('TRABAJADOR_SALUD', 'ADMIN'),
  requireScope,
  validate(updatePromoterStatusSchema),
  updatePromoterStatus
);

// 5. Verificación pública de token (para que la app muestre a qué centro y rol fue invitado antes de registrarse)
router.get(
  '/verify/:token',
  verifyInvitation
);

// 6. Canje público del token y alta del usuario con su rol y centro definitivo
router.post(
  '/accept',
  validate(acceptInvitationSchema),
  acceptInvitation
);

module.exports = router;
