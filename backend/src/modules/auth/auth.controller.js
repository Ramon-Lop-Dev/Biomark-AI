const authService = require('./auth.service');

const register = async (req, res) => {
    try {
        const { email, password, full_name } = req.body;
        
        // Validaciones requeridas por la arquitectura
        if (!email || !password || !full_name) {
            return res.status(400).json({ error: "Faltan datos requeridos (email, password, full_name)", code: "400" });
        }
        if (password.length < 6) {
            return res.status(400).json({ error: "La contraseña debe tener al menos 6 caracteres", code: "400" });
        }

        const result = await authService.registerUser(email, password, full_name);
        return res.status(201).json(result);

    } catch (error) {
        // Retornamos 409 si el correo ya existe, u otro error capturado
        const code = error.message.includes('already registered') ? "409" : "400";
        return res.status(parseInt(code)).json({ error: error.message, code });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({ error: "Email y password son requeridos", code: "400" });
        }

        const result = await authService.loginUser(email, password);
        return res.status(200).json(result);

    } catch (error) {
        return res.status(401).json({ error: error.message, code: "401" });
    }
};

module.exports = { register, login };