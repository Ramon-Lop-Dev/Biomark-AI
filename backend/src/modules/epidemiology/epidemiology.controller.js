const supabase = require('../../config/supabase');

// Obtener las alertas epidemiológicas activas
const getAlerts = async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('alertas_epidemiologicas')
            .select('*')
            .eq('activa', true) // Solo mostrar alertas activas
            .order('fecha_alerta', { ascending: false });

        if (error) throw error;
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener alertas epidemiológicas", details: error.message, code: "500" });
    }
};

module.exports = { getAlerts };