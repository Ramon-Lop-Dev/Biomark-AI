const supabase = require('../../config/supabase');

// Obtener el historial del usuario autenticado
const getMedicalHistory = async (req, res) => {
    try {
        const userId = req.user.id; // Extraído de forma segura por el middleware JWT

        const { data, error } = await supabase
            .from('historial_medico')
            .select('*')
            .eq('usuario_id', userId);

        if (error) throw error;

        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener el historial médico", details: error.message, code: "500" });
    }
};

// Crear un nuevo registro en el historial
const createMedicalRecord = async (req, res) => {
    try {
        const userId = req.user.id;
        const { tipo_registro, descripcion, fecha_diagnostico } = req.body;

        if (!tipo_registro || !descripcion) {
            return res.status(400).json({ error: "Faltan campos obligatorios", code: "400" });
        }

        const { data, error } = await supabase
            .from('historial_medico')
            .insert([
                { 
                    usuario_id: userId, 
                    tipo_registro, 
                    descripcion, 
                    fecha_diagnostico 
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