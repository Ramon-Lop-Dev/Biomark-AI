const getProfile = async (req, res) => {
    try {
        // Gracias al middleware, aquí ya tenemos acceso a req.user
        // Por ahora, solo devolveremos los datos decodificados del token como prueba
        return res.status(200).json({
            message: "Acceso autorizado al perfil",
            user_data: req.user
        });
    } catch (error) {
        return res.status(500).json({ error: "Error interno del servidor", code: "500" });
    }
};

module.exports = { getProfile };