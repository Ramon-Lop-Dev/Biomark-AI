const express = require('express');
const { getHealthCenters, getNearbyHealthCenters } = require('./gis.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validateQuery } = require('../../middleware/validate.middleware');
const { nearbySchema } = require('./gis.validator');
const router = express.Router();

router.use(verifyToken);
router.get('/', getHealthCenters);

// GET /api/gis/nearby?latitude=..&longitude=..&radius_km=.. (radius_km opcional, default 15)
router.get('/nearby', validateQuery(nearbySchema), getNearbyHealthCenters);

module.exports = router;