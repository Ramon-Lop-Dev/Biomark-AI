// Define endpoints autenticados para información geográfica de salud.
const express = require('express');
const { getHealthCenters, getNearbyHealthCenters, getSmartMap, recommendNavigation } = require('./gis.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validateQuery } = require('../../middleware/validate.middleware');
const { nearbySchema } = require('./gis.validator');
const router = express.Router();

router.use(verifyToken);
router.get('/', getHealthCenters);

// GET /api/gis/nearby?latitude=..&longitude=..&radius_km=.. (radius_km opcional, default 15)
router.get('/nearby', validateQuery(nearbySchema), getNearbyHealthCenters);
router.get('/smart-map', validateQuery(nearbySchema), getSmartMap);
router.get('/navigation/recommend', validateQuery(nearbySchema), recommendNavigation);

module.exports = router;