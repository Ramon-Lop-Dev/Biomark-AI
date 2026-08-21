const supabase = require('../../config/supabase');

// Consultar recordatorios activos
const getReminders = async (req, res) => {
    try {
        const usuarioId = req.usuarioId;
        const { data, error } = await supabase
            .from('recordatorios')
            .select('*')
            .eq('usuario_id', usuarioId)
            .order('fecha_programada', { ascending: true });

        if (error) throw error;
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener recordatorios", details: error.message, code: "500" });
    }
};

// Crear un recordatorio (Aquí luego conectaremos n8n)
// NOTA: "tipo" y "estado" son tipos ENUM en Postgres (USER-DEFINED en el
// esquema). Confirma con tu proyecto de Supabase los valores validos
// exactos para la columna "tipo" (ej. via `SELECT enum_range(NULL::tipo_recordatorio)`)
// antes de mandar el campo desde el frontend.
const addReminder = async (req, res) => {
    try {
        const usuarioId = req.usuarioId;
        const { titulo, descripcion, fecha_programada, tipo } = req.body;

        if (!titulo || !fecha_programada) {
            return res.status(400).json({ error: "Título y fecha son obligatorios", code: "400" });
        }

        const { data, error } = await supabase
            .from('recordatorios')
            .insert([{ usuario_id: usuarioId, titulo, descripcion, fecha_programada, tipo }])
            .select();

        if (error) throw error;

        // TODO: Hacer el POST al webhook de n8n aquí (N8N_WEBHOOK_URL)

        return res.status(201).json(data[0]);
    } catch (error) {
        return res.status(500).json({ error: "Error al crear recordatorio", details: error.message, code: "500" });
    }
};

module.exports = { getReminders, addReminder };
