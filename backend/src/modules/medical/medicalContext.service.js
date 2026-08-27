// Construye contexto clínico minimizado cuando existe consentimiento.
const supabase = require('../../config/supabase');

const obtenerContextoClinico = async (usuarioId) => {
    try {
        // 1. Verificar consentimiento explícito
        const { data: consent, error: consentError } = await supabase
            .from('consentimientos')
            .select('otorgado')
            .eq('usuario_id', usuarioId)
            .eq('tipo_consentimiento', 'CONTEXTO_MEDICO_IA')
            .single();

        // Si hay error o no dio permiso, devolvemos null silenciosamente
        if (consentError || !consent || !consent.otorgado) {
            return null; 
        }

        // 2. Ejecutar consultas en paralelo para máxima velocidad
        const [alergiasRes, medsRes, historialRes, antecedentesRes, vacunasRes, sintomasRes] = await Promise.all([
            supabase.from('alergias').select('alergeno, severidad').eq('usuario_id', usuarioId),
            supabase.from('medicamentos').select('nombre_medicamento, dosis, frecuencia').eq('usuario_id', usuarioId).is('fecha_fin', null),
            supabase.from('historial_medico').select('nombre_condicion, fecha_diagnostico').eq('usuario_id', usuarioId).limit(20),
            supabase.from('antecedentes_familiares').select('parentesco, nombre_condicion').eq('usuario_id', usuarioId).limit(20),
            supabase.from('vacunas').select('nombre_vacuna, numero_dosis, fecha_aplicacion').eq('usuario_id', usuarioId).order('fecha_aplicacion', { ascending: false }).limit(20),
            supabase.from('sintomas').select('nombre_sintoma, registros_sintomas(temperatura, presion_arterial, fecha_registro)').eq('usuario_id', usuarioId).limit(20)
        ]);

        // 3. Retornar el objeto estructurado
        return {
            alergias: alergiasRes.data || [],
            medicamentos: medsRes.data || [],
            historial: historialRes.data || [],
            antecedentes_familiares: antecedentesRes.data || [],
            vacunas: vacunasRes.data || [],
            sintomas: sintomasRes.data || []
        };
    } catch (error) {
        console.error("[MedicalContext] Error al extraer datos:", error);
        return null; // Fallback: mejor sin contexto que tirar el servidor
    }
};

module.exports = { obtenerContextoClinico };