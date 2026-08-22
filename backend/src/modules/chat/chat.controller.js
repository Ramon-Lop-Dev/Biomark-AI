const axios = require('axios');

const enviarMensajeChat = async (req, res) => {
    try {
        const { message, session_id } = req.body;

        if (!message) {
            return res.status(400).json({ 
                error: "El campo 'message' es obligatorio", 
                code: "400" 
            });
        }

        // Validar que las variables de entorno estén configuradas
        const aiServiceUrl = process.env.AI_SERVICE_URL;
        const internalKey = process.env.AI_SERVICE_INTERNAL_KEY;

        if (!aiServiceUrl || !internalKey) {
            return res.status(500).json({ 
                error: "Configuración del servicio de IA incompleta en el servidor", 
                code: "500" 
            });
        }

        // Llamar al microservicio de IA (Colab / VPS) con la llave de seguridad
        const aiResponse = await axios.post(`${aiServiceUrl}/chat`, {
            message: message
        }, {
            headers: {
                'X-Internal-Key': internalKey,
                'Content-Type': 'application/json'
            },
            timeout: 180000 // Timeout de 30 segundos por la inferencia del modelo
        });

        const { reply, risk_level, sources } = aiResponse.data;

        return res.status(200).json({
            session_id: session_id || "sesion-activa",
            reply,
            risk_level,
            sources
        });

    } catch (error) {
        console.error("Error al comunicarse con el AI Service:", error.message);
        
        const status = error.response ? error.response.status : 503;
        const details = error.response ? error.response.data : error.message;

        return res.status(status).json({ 
            error: "El servicio de Inteligencia Artificial no está disponible temporalmente", 
            details: details,
            code: status.toString() 
        });
    }
};

module.exports = { enviarMensajeChat };