const express = require('express');
const { enviarMensajeChat } = require('./chat.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

const router = express.Router();

// Todas las rutas del chat requieren autenticación previa del usuario
router.use(verifyToken);

// Ruta para enviar mensajes al asistente médico preventivo
router.post('/', enviarMensajeChat);

module.exports = router;