const supabase = require('../../config/supabase');

// Obtener las publicaciones de la comunidad
const getPosts = async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('comunidad_posts')
            .select('*, perfiles(full_name)') // Si tienes una relación con la tabla de perfiles
            .order('fecha_publicacion', { ascending: false });

        if (error) throw error;
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener publicaciones", details: error.message, code: "500" });
    }
};

// Crear una nueva publicación
const createPost = async (req, res) => {
    try {
        const userId = req.user.id;
        const { contenido, titulo } = req.body;

        if (!contenido) {
            return res.status(400).json({ error: "El contenido es obligatorio", code: "400" });
        }

        const { data, error } = await supabase
            .from('comunidad_posts')
            .insert([{ usuario_id: userId, titulo, contenido }])
            .select();

        if (error) throw error;
        return res.status(201).json(data[0]);
    } catch (error) {
        return res.status(500).json({ error: "Error al publicar", details: error.message, code: "500" });
    }
};

module.exports = { getPosts, createPost };