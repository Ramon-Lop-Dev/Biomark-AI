// Define el endpoint autenticado de conversación clínica.
const express = require('express');
const { enviarMensajeChat } = require('./chat.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { sendMessageSchema } = require('./chat.validator');

const router = express.Router();

router.use(verifyToken);
router.post('/', validate(sendMessageSchema), enviarMensajeChat);

module.exports = router;
