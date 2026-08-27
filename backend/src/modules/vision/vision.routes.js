// Define el endpoint autenticado de análisis visual.
const express = require('express');
const multer = require('multer');
const { analizarImagen } = require('./vision.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

const router = express.Router();

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 10 * 1024 * 1024, files: 1 } // 10 MB máx. por imagen
});

router.use(verifyToken);

// ?tipo=piel o ?tipo=garganta + archivo de imagen en form-data
router.post('/', upload.single('archivo'), analizarImagen);

module.exports = router;
