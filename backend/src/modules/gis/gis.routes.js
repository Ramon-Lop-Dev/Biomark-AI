// Define endpoints autenticados para información geográfica de salud.
const express = require('express');
const {
	getHealthCenters,
	getNearbyHealthCenters,
	getSmartMap,
	getCentersByViewport,
	getCentersNearby,
	getCenterDetails,
	getClosestHealthCenter,
	recommendNavigation
} = require('./gis.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validateQuery } = require('../../middleware/validate.middleware');
const { nearbySchema, bboxSchema, centersNearbySchema, centerIdSchema } = require('./gis.validator');
const AppError = require('../../utils/AppError');
const router = express.Router();

const validateCenterId = (req, res, next) => {
	const result = centerIdSchema.safeParse(req.params);
	if (!result.success) return next(new AppError('Datos inválidos: id debe ser un UUID válido', 400));
	req.params = result.data;
	next();
};

// Endpoints públicos para consulta de centros de salud y mapa
router.get('/', getHealthCenters);

// GET /api/gis/nearby?latitude=..&longitude=..&radius_km=.. (radius_km opcional, default 15)
router.get('/nearby', validateQuery(nearbySchema), getNearbyHealthCenters);
router.get('/closest', validateQuery(nearbySchema), getClosestHealthCenter);
router.get('/smart-map', validateQuery(nearbySchema), getSmartMap);
router.get('/centros', validateQuery(bboxSchema), getCentersByViewport);
router.get('/centros-cercanos', validateQuery(centersNearbySchema), getCentersNearby);
router.get('/centros/:id', validateCenterId, getCenterDetails);
router.get('/navigation/recommend', validateQuery(nearbySchema), recommendNavigation);

module.exports = router;