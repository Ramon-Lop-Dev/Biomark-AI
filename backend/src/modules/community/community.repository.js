// Consulta y modifica eventos y reportes comunitarios en Supabase.
const supabase = require('../../config/supabase');

const listarEventos = () =>
  supabase
    .from('eventos_comunitarios')
    .select('*')
    .order('fecha_evento', { ascending: true });

const crearEvento = (organizadorId, { titulo, descripcion, fecha_evento, ubicacion, latitud, longitud, tipo }) =>
  supabase
    .from('eventos_comunitarios')
    .insert([{ organizador_id: organizadorId, titulo, descripcion, fecha_evento, ubicacion, latitud, longitud, tipo }])
    .select();

// El reporte SIEMPRE se crea como PENDIENTE_VALIDACION (default de la
// tabla) — nunca se debe permitir que el cliente marque un reporte como
// confirmado directamente, por eso "estado" nunca se incluye en el insert.
// Soporta campos extendidos MINSA (Migración 018) con degradación elegante.
const crearReporte = async (usuarioId, payload) => {
  const {
    case_count,
    description,
    latitude,
    longitude,
    zona_riesgo_id,
    tipo_enfermedad,
    direccion_exacta,
    fecha_inicio_sintomas,
    medidas_tomadas,
    contacto_reportante
  } = payload;

  const baseInsert = {
    usuario_id: usuarioId,
    zona_riesgo_id: zona_riesgo_id || null,
    cantidad_casos: case_count || 1,
    descripcion: description,
    latitud: latitude,
    longitud: longitude
  };

  const extendedInsert = {
    ...baseInsert,
    ...(tipo_enfermedad ? { tipo_enfermedad } : {}),
    ...(direccion_exacta ? { direccion_exacta } : {}),
    ...(fecha_inicio_sintomas ? { fecha_inicio_sintomas } : {}),
    ...(medidas_tomadas ? { medidas_tomadas } : {}),
    ...(contacto_reportante ? { contacto_reportante } : {})
  };

  const res = await supabase
    .from('reportes_comunitarios')
    .insert([extendedInsert])
    .select();

  // Fallback seguro si la migración 018 no está aplicada en esta instancia de base de datos
  if (res.error && (res.error.code === '42703' || res.error.message?.includes('column'))) {
    return supabase
      .from('reportes_comunitarios')
      .insert([baseInsert])
      .select();
  }
  return res;
};

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
  supabase.from('reportes_comunitarios').select('latitud, longitud, cantidad_casos, descripcion').eq('estado', 'VALIDADO');

const listarReportesParaOperacion = async (estado) => {
  let query = supabase
    .from('reportes_comunitarios')
    .select('id, usuario_id, cantidad_casos, descripcion, latitud, longitud, estado, fecha_creacion, tipo_enfermedad, direccion_exacta, fecha_inicio_sintomas, medidas_tomadas, contacto_reportante, usuarios(correo, perfiles(nombre_completo))')
    .order('fecha_creacion', { ascending: false });
  if (estado) query = query.eq('estado', estado);
  const res = await query;
  if (res.error && (res.error.code === '42703' || res.error.message?.includes('column'))) {
    let fallbackQuery = supabase
      .from('reportes_comunitarios')
      .select('id, usuario_id, cantidad_casos, descripcion, latitud, longitud, estado, fecha_creacion, usuarios(correo, perfiles(nombre_completo))')
      .order('fecha_creacion', { ascending: false });
    if (estado) fallbackQuery = fallbackQuery.eq('estado', estado);
    return fallbackQuery;
  }
  return res;
};

// Transición de estado (PENDIENTE_VALIDACION -> VALIDADO/DESCARTADO) hecha
// por un TRABAJADOR_SALUD/LIDER_COMUNITARIO/ADMIN (ver requireRole en
// community.routes.js). No se filtra por usuario_id a propósito: quien
// valida un reporte comunitario no es necesariamente quien lo creó.
const actualizarEstadoReporte = (reporteId, estado) =>
  supabase
    .from('reportes_comunitarios')
    .update({ estado })
    .eq('id', reporteId)
    .eq('estado', 'PENDIENTE_VALIDACION')
    .select()
    .maybeSingle();

module.exports = {
  listarEventos,
  crearEvento,
  crearReporte,
  listarReportesParaEstadisticas,
  listarReportesParaHeatmap,
  listarReportesParaOperacion,
  actualizarEstadoReporte
};
