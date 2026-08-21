const supabase = require('../config/supabase');

const verifyToken = async (req, res, next) => {
    // 1. Obtener el encabezado de autorización
    const authHeader = req.headers['authorization'];
    
    // 2. Extraer el token
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) {
        return res.status(401).json({ error: "Acceso denegado. Token no proporcionado.", code: "401" });
    }

    try {
        // 3. Usar el cliente de Supabase para validar el token de forma segura
        const { data, error } = await supabase.auth.getUser(token);
        
        if (error || !data.user) {
            return res.status(401).json({ error: "Token inválido o expirado.", code: "401", details: error?.message });
        }

        // 4. Inyectar los datos del usuario validados en la request
        req.user = data.user;
        
        // 5. Dar paso al controlador
        next();
    } catch (error) {
        return res.status(500).json({ error: "Error interno al validar el token.", code: "500" });
    }
};

module.exports = { verifyToken };