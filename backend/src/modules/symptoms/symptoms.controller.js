const supabase = require('../../config/supabase');

// Consultar los síntomas registrados por el usuario
const getSymptoms = async (req, res) => {
    try {
        const userId = req.user.id; // Extraído por el middleware

        const { data, error } = await supabase
            .from('registros_sintomas')
            .select('*')
            .eq('usuario_id', userId)
            .order('fecha_registro', { ascending: false }); // Mostrar los más recientes primero

        if (error) throw error;

        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener los síntomas", details: error.message, code: "500" });
    }
};

// Registrar un nuevo síntoma
const addSymptom = async (req, res) => {
    try {
        const userId = req.user.id;
        // Campos definidos en la documentación técnica para el POST
        const { symptom, temperature, blood_pressure, notes, photo_url, date } = req.body;

        if (!symptom) {
            return res.status(400).json({ error: "El nombre del síntoma es obligatorio", code: "400" });
        }

        const { data, error } = await supabase
            .from('registros_sintomas')
            .insert([
                { 
                    usuario_id: userId,
                    sintoma: symptom,
                    temperatura: temperature,
                    presion_arterial: blood_pressure,
                    notas: notes,
                    foto_url: photo_url,
                    fecha_registro: date || new Date().toISOString()
                }
            ])
            .select();

        if (error) throw error;

        return res.status(201).json(data[0]);
    } catch (error) {
        return res.status(500).json({ error: "Error al registrar el síntoma", details: error.message, code: "500" });
    }
};

module.exports = { getSymptoms, addSymptom };