const supabase = require('../../config/supabase');

// Consultar los síntomas registrados por el usuario, con sus observaciones
// (join sintomas -> registros_sintomas)
const getSymptoms = async (req, res) => {
    try {
        const usuarioId = req.usuarioId;

        const { data, error } = await supabase
            .from('sintomas')
            .select('id, nombre_sintoma, fecha_creacion, registros_sintomas(*)')
            .eq('usuario_id', usuarioId)
            .order('fecha_creacion', { ascending: false });

        if (error) throw error;

        return res.status(200).json(data);
    } catch (error) {
        return res.status(500).json({ error: "Error al obtener los síntomas", details: error.message, code: "500" });
    }
};

// Registrar un nuevo síntoma (o una nueva observación de un síntoma existente).
//
// El esquema real separa "sintomas" (nombre_sintoma, por usuario) de
// "registros_sintomas" (temperatura, presion_arterial, notas, url_foto,
// asociados por sintoma_id). Este endpoint:
//   1. Busca si el usuario ya tiene un sintoma con ese nombre.
//   2. Si no existe, lo crea.
//   3. Inserta el registro (observacion) asociado a ese sintoma.
const addSymptom = async (req, res) => {
    try {
        const usuarioId = req.usuarioId;
        const { symptom, temperature, blood_pressure, notes, photo_url, date } = req.body;

        if (!symptom) {
            return res.status(400).json({ error: "El nombre del síntoma es obligatorio", code: "400" });
        }

        // 1. Buscar sintoma existente con ese nombre para este usuario
        const { data: sintomaExistente, error: buscarError } = await supabase
            .from('sintomas')
            .select('id')
            .eq('usuario_id', usuarioId)
            .eq('nombre_sintoma', symptom)
            .maybeSingle();

        if (buscarError) throw buscarError;

        let sintomaId = sintomaExistente?.id;

        // 2. Si no existe, crearlo
        if (!sintomaId) {
            const { data: nuevoSintoma, error: crearError } = await supabase
                .from('sintomas')
                .insert({ usuario_id: usuarioId, nombre_sintoma: symptom })
                .select('id')
                .single();

            if (crearError) throw crearError;
            sintomaId = nuevoSintoma.id;
        }

        // 3. Insertar el registro/observacion asociado
        const { data, error } = await supabase
            .from('registros_sintomas')
            .insert([
                {
                    sintoma_id: sintomaId,
                    temperatura: temperature,
                    presion_arterial: blood_pressure,
                    notas: notes,
                    url_foto: photo_url,
                    fecha_registro: date || new Date().toISOString()
                }
            ])
            .select();

        if (error) throw error;

        return res.status(201).json({ sintoma_id: sintomaId, ...data[0] });
    } catch (error) {
        return res.status(500).json({ error: "Error al registrar el síntoma", details: error.message, code: "500" });
    }
};

module.exports = { getSymptoms, addSymptom };
