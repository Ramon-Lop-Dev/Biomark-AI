// Persiste y consulta información epidemiológica territorial.
const supabase = require('../../config/supabase');

const listarAlertas = (zonaRiesgoId) => {
  let query = supabase
    .from('alertas_epidemiologicas')
    .select('*, zonas_riesgo(municipio, nivel_riesgo_actual)')
    .or(`fecha_expiracion.is.null,fecha_expiracion.gte.${new Date().toISOString()}`)
    .order('fecha_creacion', { ascending: false });

  if (zonaRiesgoId) {
    query = query.eq('zona_riesgo_id', zonaRiesgoId);
  }

  return query;
};

const listarZonasRiesgo = () => supabase.from('zonas_riesgo').select('*');

// --- lado de escritura (ingestión epidemiológica) ---

const crearReporteEpidemiologico = (cargadoPor, { fuente, enfermedad, municipio, fecha_reporte }) =>
  supabase
    .from('reportes_epidemiologicos')
    .insert([{ cargado_por: cargadoPor, fuente, enfermedad, municipio, fecha_reporte }])
    .select();

const crearAlerta = ({ reporte_epidemiologico_id, zona_riesgo_id, nivel_alerta, mensaje, fecha_expiracion }) =>
  supabase
    .from('alertas_epidemiologicas')
    .insert([{
      reporte_epidemiologico_id,
      zona_riesgo_id,
      nivel_alerta,
      mensaje,
      fecha_expiracion
    }])
    .select();

// Filtra por id de zona; no hay usuario_id en zonas_riesgo (no es un
// recurso propiedad de un usuario, es infraestructura territorial
// compartida — por eso la protección real aquí es requireRole, no un
// filtro de propiedad como en reminders/chat).
const actualizarNivelRiesgoZona = (zonaId, nivelRiesgoActual) =>
  supabase
    .from('zonas_riesgo')
    .update({ nivel_riesgo_actual: nivelRiesgoActual, fecha_actualizacion: new Date().toISOString() })
    .eq('id', zonaId)
    .select()
    .maybeSingle();

module.exports = {
  listarAlertas,
  listarZonasRiesgo,
  crearReporteEpidemiologico,
  crearAlerta,
  actualizarNivelRiesgoZona
};
