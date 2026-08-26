const supabase = require('../../config/supabase');

const listarEventos = () =>
  supabase
    .from('eventos_comunitarios')
    .select('*')
    .order('fecha_evento', { ascending: true });

const crearEvento = (organizadorId, { titulo, descripcion, fecha_evento, ubicacion }) =>
  supabase
    .from('eventos_comunitarios')
    .insert([{ organizador_id: organizadorId, titulo, descripcion, fecha_evento, ubicacion }])
    .select();

// El reporte SIEMPRE se crea como PENDIENTE_VALIDACION (default de la
// tabla) — nunca se debe permitir que el cliente marque un reporte como
// confirmado directamente, por eso "estado" nunca se incluye en el insert.
const crearReporte = (usuarioId, { case_count, description, latitude, longitude, zona_riesgo_id }) =>
  supabase
    .from('reportes_comunitarios')
    .insert([{
      usuario_id: usuarioId,
      zona_riesgo_id: zona_riesgo_id || null,
      cantidad_casos: case_count || 1,
      descripcion: description,
      latitud: latitude,
      longitud: longitude
    }])
    .select();

const listarReportesParaEstadisticas = () =>
  supabase.from('reportes_comunitarios').select('estado, cantidad_casos');

const listarReportesParaHeatmap = () =>
  supabase.from('reportes_comunitarios').select('latitud, longitud, cantidad_casos');

module.exports = {
  listarEventos,
  crearEvento,
  crearReporte,
  listarReportesParaEstadisticas,
  listarReportesParaHeatmap
};
