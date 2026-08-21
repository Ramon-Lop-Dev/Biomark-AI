const express = require('express');
const { getAlerts } = require('./epidemiology.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const router = express.Router();

// Protegemos la ruta
router.use(verifyToken);

router.get('/', getAlerts);

module.exports = router;