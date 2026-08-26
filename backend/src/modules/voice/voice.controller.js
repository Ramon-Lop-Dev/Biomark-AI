const axios = require('axios');
const FormData = require('form-data');

const AI_SERVICE_URL = process.env.AI_SERVICE_URL;
const AI_SERVICE_INTERNAL_KEY = process.env.AI_SERVICE_INTERNAL_KEY;

function validarConfig(res) {
    if (!AI_SERVICE_URL || !AI_SERVICE_INTERNAL_KEY) {
        res.status(500).json({
            error: "Configuración del servicio de IA incompleta en el servidor",
            code: "500"
        });
        return false;
    }
    return true;
}

/**
 * POST /api/voice
 * Recibe un archivo de audio (multipart/form-data, campo "archivo"),
 * lo reenvía al ai-service para transcripción (ASR) + respuesta clínica.
 * Requiere que 'multer' haya poblado req.file (ver voice.routes.js).
 */
const enviarAudioChat = async (req, res) => {
    try {
        if (!validarConfig(res)) return;

        if (!req.file) {
            return res.status(400).json({
                error: "Se requiere un archivo de audio en el campo 'archivo'",
                code: "400"
            });
        }

        const formData = new FormData();
        formData.append('archivo', req.file.buffer, {
            filename: req.file.originalname || 'audio.wav',
            contentType: req.file.mimetype || 'audio/wav'
        });

        const aiResponse = await axios.post(`${AI_SERVICE_URL}/voice`, formData, {
            headers: {
                ...formData.getHeaders(),
                'X-Internal-Key': AI_SERVICE_INTERNAL_KEY
            },
            maxBodyLength: Infinity,
            maxContentLength: Infinity,
            timeout: 120000 // la transcripción + inferencia puede tardar
        });

        const { transcription, reply, risk_level, sources } = aiResponse.data;

        return res.status(200).json({
            session_id: req.body.session_id || "sesion-activa",
            transcription,
            reply,
            risk_level,
            sources
        });

    } catch (error) {
        console.error("Error al comunicarse con el AI Service (voice):", error.message);
        const status = error.response ? error.response.status : 503;
        const details = error.response ? error.response.data : error.message;
        return res.status(status).json({
            error: "El servicio de voz no está disponible temporalmente",
            details,
            code: status.toString()
        });
    }
};

/**
 * POST /api/voice/synthesize
 * Recibe { text } en JSON, reenvía al ai-service para generar audio (TTS),
 * y devuelve el audio binario (audio/wav) directamente al cliente.
 */
const sintetizarVoz = async (req, res) => {
    try {
        if (!validarConfig(res)) return;

        const { text } = req.body;
        if (!text || !text.trim()) {
            return res.status(400).json({
                error: "El campo 'text' es obligatorio",
                code: "400"
            });
        }

        const aiResponse = await axios.post(
            `${AI_SERVICE_URL}/audio/synthesize`,
            { text },
            {
                headers: {
                    'X-Internal-Key': AI_SERVICE_INTERNAL_KEY,
                    'Content-Type': 'application/json'
                },
                responseType: 'arraybuffer', // clave: la respuesta es audio binario, no JSON
                timeout: 60000
            }
        );

        res.set('Content-Type', 'audio/wav');
        return res.status(200).send(aiResponse.data);

    } catch (error) {
        console.error("Error al comunicarse con el AI Service (synthesize):", error.message);
        const status = error.response ? error.response.status : 503;
        // Si el error vino como arraybuffer, no es JSON legible directamente
        let details = error.message;
        if (error.response && error.response.data) {
            try {
                details = JSON.parse(Buffer.from(error.response.data).toString('utf-8'));
            } catch {
                details = error.response.data;
            }
        }
        return res.status(status).json({
            error: "El servicio de síntesis de voz no está disponible temporalmente",
            details,
            code: status.toString()
        });
    }
};

module.exports = { enviarAudioChat, sintetizarVoz };
