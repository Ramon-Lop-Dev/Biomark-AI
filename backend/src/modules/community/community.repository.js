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
    contacto_reportante,
    centro_salud_id,
    clasificacion_ccm
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
    ...(contacto_reportante ? { contacto_reportante } : {}),
    ...(centro_salud_id ? { centro_salud_id } : {}),
    ...(clasificacion_ccm ? { clasificacion_ccm } : {})
  };

  const res = await supabase
    .from('reportes_comunitarios')
    .insert([extendedInsert])
    .select();

  // Fallback seguro si las migraciones 018/021 no están aplicadas en esta instancia de base de datos
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
  supabase
    .from('reportes_comunitarios')
    .select('id, latitud, longitud, cantidad_casos, descripcion, tipo_enfermedad, direccion_exacta, clasificacion_ccm, fecha_creacion')
    .eq('estado', 'VALIDADO')
    .order('fecha_creacion', { ascending: false });

const listarReportesParaOperacion = async (estado, scopeCentroSaludId = null) => {
  let query = supabase
    .from('reportes_comunitarios')
    .select('id, usuario_id, cantidad_casos, descripcion, latitud, longitud, estado, clasificacion_ccm, centro_salud_id, fecha_creacion, tipo_enfermedad, direccion_exacta, fecha_inicio_sintomas, medidas_tomadas, contacto_reportante, centros_salud(id, nombre, codigo_establecimiento), usuarios!reportes_comunitarios_usuario_id_fkey(correo, perfiles(nombre_completo))')
    .order('fecha_creacion', { ascending: false });

  if (estado) query = query.eq('estado', estado);
  if (scopeCentroSaludId) query = query.eq('centro_salud_id', scopeCentroSaludId);

  const res = await query;
  if (res.error && (res.error.code === '42703' || res.error.code === 'PGRST200' || res.error.code === 'PGRST201' || res.error.message?.includes('column') || res.error.message?.includes('relationship'))) {
    let fallbackQuery = supabase
      .from('reportes_comunitarios')
      .select('id, usuario_id, cantidad_casos, descripcion, latitud, longitud, estado, fecha_creacion, usuarios!reportes_comunitarios_usuario_id_fkey(correo, perfiles(nombre_completo))')
      .order('fecha_creacion', { ascending: false });
    if (estado) fallbackQuery = fallbackQuery.eq('estado', estado);
    if (scopeCentroSaludId) fallbackQuery = fallbackQuery.eq('centro_salud_id', scopeCentroSaludId);
    return fallbackQuery;
  }
  return res;
};

// Transición de estado (PENDIENTE_VALIDACION -> VALIDADO/DESCARTADO) hecha
// por un TRABAJADOR_SALUD/LIDER_COMUNITARIO/ADMIN (ver requireRole en
// community.routes.js). Si se especifica scopeCentroSaludId, restringe la acción
// a reportes que pertenezcan a la jurisdicción territorial de ese centro.
const actualizarEstadoReporte = (reporteId, estado, scopeCentroSaludId = null) => {
  let query = supabase
    .from('reportes_comunitarios')
    .update({ estado })
    .eq('id', reporteId)
    .eq('estado', 'PENDIENTE_VALIDACION');

  if (scopeCentroSaludId) {
    query = query.eq('centro_salud_id', scopeCentroSaludId);
  }

  return query
    .select()
    .maybeSingle();
};

module.exports = {
  listarEventos,
  crearEvento,
  crearReporte,
  listarReportesParaEstadisticas,
  listarReportesParaHeatmap,
  listarReportesParaOperacion,
  actualizarEstadoReporte
};
