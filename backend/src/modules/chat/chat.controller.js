// Atiende mensajes de chat y delega la lógica clínica al servicio.
const chatService = require('./chat.service');
const asyncHandler = require('../../utils/asyncHandler');

const enviarMensajeChat = asyncHandler(async (req, res) => {
    const { message, session_id, latitude, longitude } = req.body;
    const resultado = await chatService.enviarMensaje(req.usuarioId, message, session_id, latitude, longitude);
    return res.status(200).json(resultado);
});

const obtenerHistorialChat = asyncHandler(async (req, res) => {
    const resultado = await chatService.obtenerHistorial(req.usuarioId, req.query.session_id);
    return res.status(200).json(resultado);
});

module.exports = { enviarMensajeChat, obtenerHistorialChat };
