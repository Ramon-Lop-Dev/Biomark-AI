const express = require('express');
const { getSymptoms, addSymptom } = require('./symptoms.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const router = express.Router();

// Blindamos las rutas
router.use(verifyToken);

router.get('/', getSymptoms);
router.post('/', addSymptom);

module.exports = router;