const supabase = require('../../config/supabase');

// Obtener lista de centros de salud
const getHealthCenters = async (req, res) => {
    try {
        // Opcional: Podrías recibir latitud y longitud en req.query para filtrar por cercanía en el futuro
        const { data, error } = await supabase
            .from('centros_salud')
            .select('*')
            .order('nombre', { ascending: true });

        if (error) throw error;
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener centros de salud", details: error.message, code: "500" });
    }
};

module.exports = { getHealthCenters };