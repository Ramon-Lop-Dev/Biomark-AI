const communityRepo = require('./community.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

const getEvents = async () => {
  const { data, error } = await communityRepo.listarEventos();
  if (error) throw new AppError('Error al obtener eventos comunitarios', 500);
  return data;
};

const createEvent = async (usuarioId, payload) => {
  const { data, error } = await communityRepo.crearEvento(usuarioId, payload);
  if (error) throw new AppError('Error al crear evento comunitario', 500);

  const evento = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'eventos_comunitarios',
    idEntidad: evento.id,
    accion: 'CREACION',
    detalle: { titulo: evento.titulo }
  });

  return evento;
};

const createReport = async (usuarioId, payload) => {
  const { data, error } = await communityRepo.crearReporte(usuarioId, payload);
  if (error) throw new AppError('Error al registrar el reporte comunitario', 500);

  const reporte = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'reportes_comunitarios',
    idEntidad: reporte.id,
    accion: 'CREACION',
    detalle: { estado: reporte.estado, cantidad_casos: reporte.cantidad_casos }
  });

  return { report_id: reporte.id, status: reporte.estado };
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
// de un reporte individual asociado a una persona.
const getHeatmap = async () => {
  const { data, error } = await communityRepo.listarReportesParaHeatmap();
  if (error) throw new AppError('Error al obtener el mapa de calor', 500);

  return data.map((r) => ({
    latitud: Math.round(r.latitud * 100) / 100,
    longitud: Math.round(r.longitud * 100) / 100,
    cantidad_casos: r.cantidad_casos
  }));
};

// Cierra el ciclo de vida de un reporte comunitario que hoy quedaba
// atascado en PENDIENTE_VALIDACION para siempre: un TRABAJADOR_SALUD,
// LIDER_COMUNITARIO o ADMIN (ver requireRole en community.routes.js) lo
// confirma como VALIDADO o lo descarta como DESCARTADO.
const updateReportStatus = async (usuarioValidadorId, reporteId, estado) => {
  const { data, error } = await communityRepo.actualizarEstadoReporte(reporteId, estado);
  if (error) throw new AppError('Error al actualizar el estado del reporte', 500);

  if (!data) {
    throw new AppError('Reporte comunitario no encontrado', 404);
  }

  await auditService.registrar({
    usuarioId: usuarioValidadorId,
    tipoEntidad: 'reportes_comunitarios',
    idEntidad: data.id,
    accion: 'VALIDACION_REPORTE',
    detalle: { estado_nuevo: estado }
  });

  return data;
};

module.exports = { getEvents, createEvent, createReport, getStatistics, getHeatmap, updateReportStatus };
