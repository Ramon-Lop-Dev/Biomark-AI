const express = require('express');
const { getAlerts, getRiskMap } = require('./epidemiology.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const router = express.Router();

router.use(verifyToken);

router.get('/alerts', getAlerts);
router.get('/risk-map', getRiskMap);

module.exports = router;
