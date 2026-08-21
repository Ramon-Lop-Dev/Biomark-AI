const supabase = require('../../config/supabase');

// Obtener las alertas epidemiológicas.
// Columnas reales de alertas_epidemiologicas: id, reporte_epidemiologico_id,
// zona_riesgo_id, nivel_alerta, mensaje, fecha_creacion.
// No existe columna "activa": la tabla no tiene un flag de vigencia propio;
// se filtra opcionalmente por zona via query param.
const getAlerts = async (req, res) => {
    try {
        const { zona_riesgo_id } = req.query;

        let query = supabase
            .from('alertas_epidemiologicas')
            .select('*, zonas_riesgo(municipio, nivel_riesgo_actual)')
            .order('fecha_creacion', { ascending: false });

        if (zona_riesgo_id) {
            query = query.eq('zona_riesgo_id', zona_riesgo_id);
        }

        const { data, error } = await query;

        if (error) throw error;
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener alertas epidemiológicas", details: error.message, code: "500" });
    }
};

// GET /api/epidemiology/risk-map
const getRiskMap = async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('zonas_riesgo')
            .select('*');

        if (error) throw error;
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener el mapa de riesgo", details: error.message, code: "500" });
    }
};

module.exports = { getAlerts, getRiskMap };
