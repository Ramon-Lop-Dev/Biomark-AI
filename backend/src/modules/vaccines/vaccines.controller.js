const supabase = require('../../config/supabase');

// Obtener las vacunas aplicadas del usuario
const getVaccines = async (req, res) => {
    try {
        const userId = req.user.id;
        const { data, error } = await supabase
            .from('vacunas')
            .select('*')
            .eq('usuario_id', userId)
            .order('fecha_aplicacion', { ascending: false });

        if (error) throw error;
        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener vacunas", details: error.message, code: "500" });
    }
};

// Registrar una vacuna aplicada
const addVaccine = async (req, res) => {
    try {
        const userId = req.user.id;
        const { nombre_vacuna, fecha_aplicacion, dosis, notas } = req.body;

        if (!nombre_vacuna || !fecha_aplicacion) {
            return res.status(400).json({ error: "Nombre y fecha son obligatorios", code: "400" });
        }

        const { data, error } = await supabase
            .from('vacunas')
            .insert([{ usuario_id: userId, nombre_vacuna, fecha_aplicacion, dosis, notas }])
            .select();

        if (error) throw error;
        return res.status(201).json(data[0]);
    } catch (error) {
        return res.status(500).json({ error: "Error al registrar vacuna", details: error.message, code: "500" });
    }
};

module.exports = { getVaccines, addVaccine };