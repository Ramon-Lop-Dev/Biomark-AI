const express = require('express');
const multer = require('multer');
const { enviarAudioChat, sintetizarVoz } = require('./voice.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

const router = express.Router();

// Guarda el archivo en memoria (buffer) para reenviarlo tal cual al ai-service,
// sin escribirlo a disco en el servidor de Node.
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 25 * 1024 * 1024 } // 25 MB máx. por archivo de audio
});

router.use(verifyToken);

// Recibe audio del usuario -> transcripción + respuesta clínica de Biomark AI
router.post('/', upload.single('archivo'), enviarAudioChat);

// Recibe texto -> devuelve audio (TTS) para reproducir en la app
router.post('/synthesize', sintetizarVoz);

module.exports = router;
