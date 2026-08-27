// Define endpoints autenticados para conversación y síntesis por voz.
const express = require('express');
const multer = require('multer');
const { enviarAudioChat, sintetizarVoz } = require('./voice.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { synthesizeSchema } = require('./voice.validator');

const router = express.Router();

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 25 * 1024 * 1024, files: 1 } // 25 MB máx. por archivo de audio
});

router.use(verifyToken);

// Recibe audio del usuario -> transcripción + respuesta clínica de Biomark AI
// (multipart/form-data: no se valida con Zod, el archivo se valida en el service)
router.post('/', upload.single('archivo'), enviarAudioChat);

// Recibe texto -> devuelve audio (TTS) para reproducir en la app
router.post('/synthesize', validate(synthesizeSchema), sintetizarVoz);

module.exports = router;
