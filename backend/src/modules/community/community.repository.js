// Consulta y modifica eventos y reportes comunitarios en Supabase.
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

// DECISIÓN POR DEFECTO (Fase A3): "statistics" sigue contando TODOS los
// estados (el desglose por_estado ya es útil para ver cuánto hay
// pendiente vs. validado, y no expone ninguna ubicación) — pero el
// "heatmap" (que sí plotea coordenadas reales en un mapa) solo incluye
// reportes ya VALIDADO. Un mapa de calor público no debería amplificar
// geográficamente reportes todavía sin confirmar (podrían ser falsos
// positivos, spam, o coordenadas erróneas) — para eso existe el flujo de
// validación de community.service.updateReportStatus. Si se prefiere
// mostrar también PENDIENTE_VALIDACION en el heatmap (p. ej. con un
// estilo visual distinto para "no confirmado"), basta con quitar el
// .eq('estado', 'VALIDADO') de abajo.
const listarReportesParaEstadisticas = () =>
  supabase.from('reportes_comunitarios').select('estado, cantidad_casos');

const listarReportesParaHeatmap = () =>
  supabase.from('reportes_comunitarios').select('latitud, longitud, cantidad_casos').eq('estado', 'VALIDADO');

// Transición de estado (PENDIENTE_VALIDACION -> VALIDADO/DESCARTADO) hecha
// por un TRABAJADOR_SALUD/LIDER_COMUNITARIO/ADMIN (ver requireRole en
// community.routes.js). No se filtra por usuario_id a propósito: quien
// valida un reporte comunitario no es necesariamente quien lo creó.
const actualizarEstadoReporte = (reporteId, estado) =>
  supabase
    .from('reportes_comunitarios')
    .update({ estado })
    .eq('id', reporteId)
    .select()
    .maybeSingle();

module.exports = {
  listarEventos,
  crearEvento,
  crearReporte,
  listarReportesParaEstadisticas,
  listarReportesParaHeatmap,
  actualizarEstadoReporte
};
