const supabase = require('../../config/supabase');

// Obtener el historial del usuario autenticado
const getMedicalHistory = async (req, res) => {
    try {
        const usuarioId = req.usuarioId; // id interno (public.usuarios.id), no el auth_id

        const { data, error } = await supabase
            .from('historial_medico')
            .select('*')
            .eq('usuario_id', usuarioId)
            .order('fecha_creacion', { ascending: false });

        if (error) throw error;

        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener el historial médico", details: error.message, code: "500" });
    }
};

// Crear un nuevo registro en el historial
// Columnas reales de historial_medico: nombre_condicion, fecha_diagnostico, notas
const createMedicalRecord = async (req, res) => {
    try {
        const usuarioId = req.usuarioId;
        const { nombre_condicion, notas, fecha_diagnostico } = req.body;

        if (!nombre_condicion) {
            return res.status(400).json({ error: "El campo 'nombre_condicion' es obligatorio", code: "400" });
        }

        const { data, error } = await supabase
            .from('historial_medico')
            .insert([
                {
                    usuario_id: usuarioId,
                    nombre_condicion,
                    fecha_diagnostico,
                    notas
                }
            ])
            .select();

        if (error) throw error;

        return res.status(201).json(data[0]);
    } catch (error) {
        return res.status(500).json({ error: "Error al guardar el registro médico", details: error.message, code: "500" });
    }
};

module.exports = { getMedicalHistory, createMedicalRecord };
