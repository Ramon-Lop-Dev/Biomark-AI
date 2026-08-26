const supabase = require('../../config/supabase');

// Columnas reales de alertas_epidemiologicas: id, reporte_epidemiologico_id,
// zona_riesgo_id, nivel_alerta, mensaje, fecha_creacion. No existe columna
// "activa" — se filtra opcionalmente por zona via query param.
const listarAlertas = (zonaRiesgoId) => {
  let query = supabase
    .from('alertas_epidemiologicas')
    .select('*, zonas_riesgo(municipio, nivel_riesgo_actual)')
    .order('fecha_creacion', { ascending: false });

  if (zonaRiesgoId) {
    query = query.eq('zona_riesgo_id', zonaRiesgoId);
  }

  return query;
};

const listarZonasRiesgo = () => supabase.from('zonas_riesgo').select('*');

module.exports = { listarAlertas, listarZonasRiesgo };
