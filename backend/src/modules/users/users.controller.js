const supabase = require('../../config/supabase');

// GET /api/users/profile
// Devuelve los datos reales de usuarios + perfiles, no el token crudo.
const getProfile = async (req, res) => {
    try {
        const usuarioId = req.usuarioId;

        const { data, error } = await supabase
            .from('usuarios')
            .select('id, correo, rol, activo, fecha_creacion, perfiles(nombre_completo, fecha_nacimiento, sexo, telefono, direccion, municipio)')
            .eq('id', usuarioId)
            .single();

        if (error) throw error;

        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener el perfil", details: error.message, code: "500" });
    }
};

module.exports = { getProfile };
