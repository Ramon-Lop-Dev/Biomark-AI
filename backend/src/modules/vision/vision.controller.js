const axios = require('axios');
const FormData = require('form-data');

const AI_SERVICE_URL = process.env.AI_SERVICE_URL;
const AI_SERVICE_INTERNAL_KEY = process.env.AI_SERVICE_INTERNAL_KEY;

const TIPOS_VALIDOS = ['piel', 'garganta'];

/**
 * POST /api/vision?tipo=piel|garganta
 * Recibe una imagen (multipart/form-data, campo "archivo") y el tipo de
 * análisis, y lo reenvía al ai-service para clasificación visual.
 */
const analizarImagen = async (req, res) => {
    try {
        if (!AI_SERVICE_URL || !AI_SERVICE_INTERNAL_KEY) {
            return res.status(500).json({
                error: "Configuración del servicio de IA incompleta en el servidor",
                code: "500"
            });
        }

        // Acepta 'tipo' como query param o como campo del form-data
        const tipo = req.query.tipo || req.body.tipo;

        if (!tipo || !TIPOS_VALIDOS.includes(tipo)) {
            return res.status(400).json({
                error: `El parámetro 'tipo' debe ser uno de: ${TIPOS_VALIDOS.join(', ')}`,
                code: "400"
            });
        }

        if (!req.file) {
            return res.status(400).json({
                error: "Se requiere una imagen en el campo 'archivo'",
                code: "400"
            });
        }

        const formData = new FormData();
        formData.append('archivo', req.file.buffer, {
            filename: req.file.originalname || 'imagen.jpg',
            contentType: req.file.mimetype || 'image/jpeg'
        });

        const aiResponse = await axios.post(
            `${AI_SERVICE_URL}/vision`,
            formData,
            {
                params: { tipo }, // el ai-service espera 'tipo' como query param
                headers: {
                    ...formData.getHeaders(),
                    'X-Internal-Key': AI_SERVICE_INTERNAL_KEY
                },
                maxBodyLength: Infinity,
                maxContentLength: Infinity,
                timeout: 60000
            }
        );

        const {
            tipo_analisis,
            condicion_detectada,
            confidence_percentage,
            biomark_recommendation,
            risk_level,
            sources
        } = aiResponse.data;

        return res.status(200).json({
            tipo_analisis,
            condicion_detectada,
            confidence_percentage,
            reply: biomark_recommendation,
            risk_level,
            sources
        });

    } catch (error) {
        console.error("Error al comunicarse con el AI Service (vision):", error.message);
        const status = error.response ? error.response.status : 503;
        const details = error.response ? error.response.data : error.message;
        return res.status(status).json({
            error: "El servicio de análisis de imágenes no está disponible temporalmente",
            details,
            code: status.toString()
        });
    }
};

module.exports = { analizarImagen };
