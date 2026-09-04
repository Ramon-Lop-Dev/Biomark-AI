// Coordina reportes, alertas, niveles de riesgo y auditoría.
const epidemiologyRepo = require('./epidemiology.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');
const { publicarEvento } = require('../../config/n8nClient');

const getAlerts = async (zonaRiesgoId) => {
  const { data, error } = await epidemiologyRepo.listarAlertas(zonaRiesgoId);
  if (error) throw new AppError('Error al obtener alertas epidemiológicas', 500);
  return data;
};

const getRiskMap = async () => {
  const { data, error } = await epidemiologyRepo.listarZonasRiesgo();
  if (error) throw new AppError('Error al obtener el mapa de riesgo', 500);
  return data;
};

// --- lado de escritura ---

const createReport = async (usuarioId, payload) => {
  const { data, error } = await epidemiologyRepo.crearReporteEpidemiologico(usuarioId, payload);
  if (error) throw new AppError('Error al registrar el reporte epidemiológico', 500);

  const reporte = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'reportes_epidemiologicos',
    idEntidad: reporte.id,
    accion: 'CREACION',
    detalle: { enfermedad: reporte.enfermedad, municipio: reporte.municipio }
  });

  return reporte;
};

const createAlert = async (usuarioId, payload) => {
  const { data, error } = await epidemiologyRepo.crearAlerta(payload);
  if (error) throw new AppError('Error al crear la alerta epidemiológica', 500);

  const alerta = data[0];

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'alertas_epidemiologicas',
    idEntidad: alerta.id,
    accion: 'CREACION',
    detalle: { nivel_alerta: alerta.nivel_alerta, zona_riesgo_id: alerta.zona_riesgo_id }
  });

  // Publica el evento hacia n8n para que la alerta se traduzca en
  // notificaciones push a los usuarios del municipio de la zona
  // afectada. No debe bloquear ni hacer fallar la creación de la
  // alerta si n8n está caído: mismo patrón que reminders.service.js.
  try {
    await publicarEvento('alerta.epidemiologica.creada', { alerta });
  } catch (error) {
    console.error('[Epidemiology] No se pudo publicar el evento en n8n:', error.message);
  }

  return alerta;
};

const updateRiskZoneLevel = async (usuarioId, zonaId, nivelRiesgoActual) => {
  const { data, error } = await epidemiologyRepo.actualizarNivelRiesgoZona(zonaId, nivelRiesgoActual);
  if (error) throw new AppError('Error al actualizar el nivel de riesgo de la zona', 500);

  if (!data) {
    throw new AppError('Zona de riesgo no encontrada', 404);
  }

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'zonas_riesgo',
    idEntidad: data.id,
    accion: 'ACTUALIZACION_NIVEL_RIESGO',
    detalle: { nivel_riesgo_actual: nivelRiesgoActual }
  });

  return data;
};

module.exports = { getAlerts, getRiskMap, createReport, createAlert, updateRiskZoneLevel };