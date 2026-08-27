// Expone la recomendación autenticada de destino para navegación.
const express = require('express');
const { recommendNavigation } = require('./gis.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validateQuery } = require('../../middleware/validate.middleware');
const { nearbySchema } = require('./gis.validator');

const router = express.Router();
router.use(verifyToken);
router.post('/recommend', validateQuery(nearbySchema), recommendNavigation);

module.exports = router;
