const express = require('express');
const { getHealthCenters } = require('./gis.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const router = express.Router();

router.use(verifyToken);
router.get('/', getHealthCenters);

module.exports = router;