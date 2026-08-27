// Atiende audio clínico y síntesis de respuestas de voz.
const voiceService = require('./voice.service');
const asyncHandler = require('../../utils/asyncHandler');

/**
 * POST /api/voice
 * Recibe un archivo de audio (multipart/form-data, campo "archivo"),
 * lo reenvía al ai-service para transcripción (ASR) + respuesta clínica.
 * Requiere que 'multer' haya poblado req.file (ver voice.routes.js).
 */
const enviarAudioChat = asyncHandler(async (req, res) => {
    const resultado = await voiceService.transcribirYResponder(req.usuarioId, req.file, req.body.session_id);
    return res.status(200).json(resultado);
});

/**
 * POST /api/voice/synthesize
 * Recibe { text } en JSON, reenvía al ai-service para generar audio (TTS),
 * y devuelve el audio binario (audio/wav) directamente al cliente.
 */
const sintetizarVoz = asyncHandler(async (req, res) => {
    const audioBuffer = await voiceService.sintetizarVoz(req.body.text);
    res.set('Content-Type', 'audio/wav');
    return res.status(200).send(audioBuffer);
});

module.exports = { enviarAudioChat, sintetizarVoz };
