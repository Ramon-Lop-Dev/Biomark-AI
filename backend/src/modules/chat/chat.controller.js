const chatService = require('./chat.service');
const asyncHandler = require('../../utils/asyncHandler');

const enviarMensajeChat = asyncHandler(async (req, res) => {
    const { message, session_id } = req.body;
    const resultado = await chatService.enviarMensaje(req.usuarioId, message, session_id);
    return res.status(200).json(resultado);
});

module.exports = { enviarMensajeChat };
