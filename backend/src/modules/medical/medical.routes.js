const express = require('express');
const { getMedicalHistory, createMedicalRecord } = require('./medical.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const router = express.Router();

// Aplicamos el middleware verifyToken a todas las rutas de este router
router.use(verifyToken);

router.get('/', getMedicalHistory);
router.post('/', createMedicalRecord);

module.exports = router;