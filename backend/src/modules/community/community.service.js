// Aplica reglas de negocio, privacidad, triaje CCM y validación comunitaria.
const communityRepo = require('./community.repository');
const gisService = require('../gis/gis.service');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');
const { publicarEvento } = require('../../config/n8nClient');

const DANGER_SIGNS_KEYWORDS = [
  'dificultad respiratoria', 'disnea', 'falta de aire', 'asfixia', 'dificultad para respirar',
  'sangrado', 'hemorragia', 'petequia', 'petequias', 'epistaxis', 'gingivorragia', 'sangre',
  'letargia', 'letargo', 'somnolencia extrema', 'inconsciente', 'perdida de conocimiento',
  'convulsion', 'convulsiones',
  'vomito incoercible', 'vomitos frecuentes', 'vomito constante', 'intolerancia oral',
  'dolor abdominal intenso', 'dolor de estomago severo',
  'choque', 'shock', 'extremidades frias', 'cianosis',
  'deshidratacion grave'
];

const MODERATE_SIGNS_KEYWORDS = [
  'fiebre', 'calentura', 'temperatura',
  'erupcion', 'rash', 'manchas rojas', 'ronchas',
  'mialgia', 'dolor muscular', 'dolor de cuerpo', 'artralgia', 'dolor articular', 'dolor de huesos',
  'cefalea', 'dolor de cabeza', 'dolor retroocular', 'dolor detras de los ojos',
  'diarrea', 'nausea', 'nauseas', 'vomito',
  'tos', 'gripe', 'congestion'
];

/**
 * Clasifica la severidad según el protocolo de Manejo de Casos Comunitarios (CCM)
 * y Guías Clínicas de Alerta Epidemiológica (MINSA).
 * Fail-safe: si se detecta cualquier signo de alarma, se clasifica como ROJO.
 */
const clasificarCCM = (payload = {}) => {
  const {
    description = '',
    tipo_enfermedad = '',
    medidas_tomadas = '',
    signos_peligro = [],
    clasificacion_ccm
  } = payload;

  const texto = `${description} ${tipo_enfermedad} ${medidas_tomadas} ${Array.isArray(signos_peligro) ? signos_peligro.join(' ') : ''}`.toLowerCase();

  const tieneSignoPeligro = DANGER_SIGNS_KEYWORDS.some((kw) => texto.includes(kw)) ||
    (Array.isArray(signos_peligro) && signos_peligro.some((s) =>
      typeof s === 'string' && (s.toUpperCase().includes('ROJO') || DANGER_SIGNS_KEYWORDS.some((kw) => s.toLowerCase().includes(kw)))
    ));

  if (tieneSignoPeligro || clasificacion_ccm === 'ROJO') {
    return 'ROJO';
  }

  const tieneSignoModerado = MODERATE_SIGNS_KEYWORDS.some((kw) => texto.includes(kw));
  if (tieneSignoModerado || clasificacion_ccm === 'AMARILLO') {
    return 'AMARILLO';
  }

  return clasificacion_ccm === 'VERDE' ? 'VERDE' : 'VERDE';
};

const getEvents = async () => {
  const { data, error } = await communityRepo.listarEventos();
  if (error) throw new AppError('Error al obtener eventos comunitarios', 500);
  return data;
};

const createEvent = async (usuarioId, payload) => {
  let fechaFin = payload.fecha_fin;
  if (!fechaFin && payload.fecha_evento) {
    const d = new Date(payload.fecha_evento);
    d.setHours(d.getHours() + 4);
    fechaFin = d.toISOString();
  }

  const { data, error } = await communityRepo.crearEvento(usuarioId, {
    ...payload,
    fecha_fin: fechaFin
  });
  if (error) throw new AppError('Error al crear evento comunitario', 500);

  const evento = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'eventos_comunitarios',
    idEntidad: evento.id,
    accion: 'CREACION',
    detalle: { titulo: evento.titulo }
  });

  // Emite notificación push y registra la nueva jornada comunitaria
  try {
    const notificationsService = require('../notifications/notifications.service');
    await notificationsService.notificarJornadaSalud(evento);
  } catch (error) {
    console.error('[Community] No se pudo notificar la jornada comunitaria:', error.message);
  }

  return evento;
};

const createReport = async (usuarioId, payload) => {
  let centroSaludId = payload.centro_salud_id || null;

  // Si no se especificó centro de salud, resolverlo automáticamente por proximidad GIS
  if (!centroSaludId && payload.latitude != null && payload.longitude != null) {
    try {
      const centroCercano = await gisService.getClosestHealthCenter(payload.latitude, payload.longitude);
      if (centroCercano && centroCercano.id) {
        centroSaludId = centroCercano.id;
      }
    } catch (err) {
      console.error('[Community] Error al resolver centro de salud más cercano:', err.message);
    }
  }

  const clasificacionCcm = clasificarCCM(payload);

  const payloadCompleto = {
    ...payload,
    centro_salud_id: centroSaludId,
    clasificacion_ccm: clasificacionCcm
  };

  const { data, error } = await communityRepo.crearReporte(usuarioId, payloadCompleto);
  if (error) {
    console.error('[Community] Error al registrar reporte en base de datos:', error.message || error);
    throw new AppError('Error al registrar el reporte comunitario', 500);
  }

  const reporte = (data && data[0]) ? data[0] : {};
  if (!reporte.id) {
    console.error('[Community] El reporte insertado no devolvió datos válidos:', data);
    throw new AppError('No se pudo confirmar el reporte comunitario', 500);
  }

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'reportes_comunitarios',
    idEntidad: reporte.id,
    accion: 'CREACION',
    detalle: {
      estado: reporte.estado,
      cantidad_casos: reporte.cantidad_casos,
      clasificacion_ccm: reporte.clasificacion_ccm || clasificacionCcm,
      centro_salud_id: reporte.centro_salud_id || centroSaludId
    }
  });

  // Si es triaje ROJO (signos de peligro / alarma), despachar evento de notificación inmediata
  if (clasificacionCcm === 'ROJO') {
    try {
      await publicarEvento('reporte_comunitario.urgente_rojo', {
        reporte: {
          ...reporte,
          clasificacion_ccm: 'ROJO',
          centro_salud_id: centroSaludId
        }
      });
    } catch (error) {
      console.error('[Community] No se pudo publicar reporte urgente en n8n:', error.message);
    }
  }

  return {
    report_id: reporte.id,
    status: reporte.estado,
    clasificacion_ccm: reporte.clasificacion_ccm || clasificacionCcm,
    centro_salud_id: reporte.centro_salud_id || centroSaludId
  };
};

// Datos agregados (conteos), nunca ubicaciones individuales.
const getStatistics = async () => {
  const { data, error } = await communityRepo.listarReportesParaEstadisticas();
  if (error) throw new AppError('Error al obtener estadísticas comunitarias', 500);

  return data.reduce((acc, reporte) => {
    acc.total_reportes += 1;
    acc.total_casos += reporte.cantidad_casos;
    acc.por_estado[reporte.estado] = (acc.por_estado[reporte.estado] || 0) + 1;
    return acc;
  }, { total_reportes: 0, total_casos: 0, por_estado: {} });
};

// Coordenadas agregadas (redondeadas) para no exponer la ubicación exacta
// Entrega reportes comunitarios validados con georreferenciación y metadatos clínicos.
const getHeatmap = async () => {
  const { data, error } = await communityRepo.listarReportesParaHeatmap();
  if (error) throw new AppError('Error al obtener el mapa de calor', 500);

  return (data || []).map((r) => ({
    id: r.id,
    latitud: Number(r.latitud),
    longitud: Number(r.longitud),
    cantidad_casos: r.cantidad_casos,
    descripcion: r.descripcion || '',
    tipo_enfermedad: r.tipo_enfermedad || null,
    direccion_exacta: r.direccion_exacta || null,
    clasificacion_ccm: r.clasificacion_ccm || 'VERDE',
    fecha_creacion: r.fecha_creacion || null
  }));
};

const getOperationalReports = async (estado, scopeCentroSaludId = null) => {
  const allowed = [undefined, 'PENDIENTE_VALIDACION', 'VALIDADO', 'DESCARTADO'];
  if (!allowed.includes(estado)) throw new AppError('Estado de reporte inválido', 400);
  const { data, error } = await communityRepo.listarReportesParaOperacion(estado, scopeCentroSaludId);
  if (error) throw new AppError('Error al obtener los reportes comunitarios', 500);
  return data;
};

// Cierra el ciclo de vida de un reporte comunitario que hoy quedaba
// atascado en PENDIENTE_VALIDACION para siempre: un TRABAJADOR_SALUD,
// LIDER_COMUNITARIO o ADMIN (ver requireRole en community.routes.js) lo
// confirma como VALIDADO o lo descarta como DESCARTADO.
// Con scopeCentroSaludId restringe la validación a reportes de su propio centro.
const updateReportStatus = async (usuarioValidadorId, reporteId, estado, scopeCentroSaludId = null) => {
  const { data, error } = await communityRepo.actualizarEstadoReporte(reporteId, estado, scopeCentroSaludId);
  if (error) throw new AppError('Error al actualizar el estado del reporte', 500);

  if (!data) {
    throw new AppError('Reporte comunitario no encontrado o no pertenece a tu centro de salud', 404);
  }

  await auditService.registrar({
    usuarioId: usuarioValidadorId,
    tipoEntidad: 'reportes_comunitarios',
    idEntidad: data.id,
    accion: 'VALIDACION_REPORTE',
    detalle: { estado_nuevo: estado }
  });

  // Notificar a la población sobre alerta comunitaria y difusión en n8n
  if (estado === 'VALIDADO') {
    try {
      const notificationsService = require('../notifications/notifications.service');
      await notificationsService.notificarAlertaReporte(data);
    } catch (n8nError) {
      console.error('[Community] No se pudo notificar el reporte validado:', n8nError.message);
    }
  }

  return data;
};

module.exports = {
  getEvents,
  createEvent,
  createReport,
  getStatistics,
  getHeatmap,
  getOperationalReports,
  updateReportStatus,
  clasificarCCM
};