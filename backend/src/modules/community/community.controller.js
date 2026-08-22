const supabase = require('../../config/supabase');


// GET /api/community/events
const getEvents = async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('eventos_comunitarios')
            .select('*')
            .order('fecha_evento', { ascending: true });

        if (error) throw error;
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener eventos comunitarios", details: error.message, code: "500" });
    }
};

// POST /api/community/events
const createEvent = async (req, res) => {
    try {
        const usuarioId = req.usuarioId; // organizador
        const { titulo, descripcion, fecha_evento, ubicacion } = req.body;

        if (!titulo || !fecha_evento) {
            return res.status(400).json({ error: "Título y fecha del evento son obligatorios", code: "400" });
        }

        const { data, error } = await supabase
            .from('eventos_comunitarios')
            .insert([{ organizador_id: usuarioId, titulo, descripcion, fecha_evento, ubicacion }])
            .select();

        if (error) throw error;
        return res.status(201).json(data[0]);
    } catch (error) {
        return res.status(500).json({ error: "Error al crear evento comunitario", details: error.message, code: "500" });
    }
};

// POST /api/community/reports
// Importante: el reporte SIEMPRE se crea como PENDIENTE_VALIDACION
// (default de la tabla) — nunca se debe permitir que el cliente marque un
// reporte como confirmado directamente.
const createReport = async (req, res) => {
    try {
        const usuarioId = req.usuarioId;
        const { case_count, description, latitude, longitude, zona_riesgo_id } = req.body;

        if (!latitude || !longitude) {
            return res.status(400).json({ error: "latitude y longitude son obligatorios", code: "400" });
        }

        const { data, error } = await supabase
            .from('reportes_comunitarios')
            .insert([{
                usuario_id: usuarioId,
                zona_riesgo_id: zona_riesgo_id || null,
                cantidad_casos: case_count || 1,
                descripcion: description,
                latitud: latitude,
                longitud: longitude
                // "estado" NO se envia: se deja el default PENDIENTE_VALIDACION
            }])
            .select();

        if (error) throw error;
        return res.status(201).json({ report_id: data[0].id, status: data[0].estado });
    } catch (error) {
        return res.status(500).json({ error: "Error al registrar el reporte comunitario", details: error.message, code: "500" });
    }
};

// GET /api/community/statistics
// Datos agregados (conteos), nunca ubicaciones individuales.
const getStatistics = async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('reportes_comunitarios')
            .select('estado, cantidad_casos');

        if (error) throw error;

        const resumen = data.reduce((acc, reporte) => {
            acc.total_reportes += 1;
            acc.total_casos += reporte.cantidad_casos;
            acc.por_estado[reporte.estado] = (acc.por_estado[reporte.estado] || 0) + 1;
            return acc;
        }, { total_reportes: 0, total_casos: 0, por_estado: {} });

        return res.status(200).json(resumen);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener estadísticas comunitarias", details: error.message, code: "500" });
    }
};

// GET /api/community/heatmap
// Devuelve coordenadas agregadas (redondeadas) para no exponer la
// ubicacion exacta de un reporte individual asociado a una persona.
const getHeatmap = async (req, res) => {
    try {
        const { data, error } = await supabase
            .from('reportes_comunitarios')
            .select('latitud, longitud, cantidad_casos');

        if (error) throw error;

        const puntos = data.map((r) => ({
            latitud: Math.round(r.latitud * 100) / 100,
            longitud: Math.round(r.longitud * 100) / 100,
            cantidad_casos: r.cantidad_casos
        }));

        return res.status(200).json(puntos);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener el mapa de calor", details: error.message, code: "500" });
    }
};

module.exports = { getEvents, createEvent, createReport, getStatistics, getHeatmap };
