const contentRepo = require('./content.repository');
const auditService = require('../audit/audit.service');

const getPublishedContent = async (filtros = {}) => {
  try {
    const { data, error } = await contentRepo.listarContenidos(filtros);
    if (error || !data || data.length === 0) {
      // Si la tabla aún no tiene datos o está offline, retornamos el catálogo verificado
      return contentRepo.SEMILLAS_OFICIALES_FALLBACK;
    }
    return data;
  } catch (err) {
    console.warn('[ContentService] Usando semillas fallback por error de conexión:', err.message);
    return contentRepo.SEMILLAS_OFICIALES_FALLBACK;
  }
};

const getContentById = async (id) => {
  try {
    const { data, error } = await contentRepo.buscarPorId(id);
    if (!error && data) return data;
  } catch (_) {}

  // Buscar en fallback
  const fallback = contentRepo.SEMILLAS_OFICIALES_FALLBACK.find((item) => item.id === id);
  if (fallback) return fallback;

  throw new Error('Contenido médico no encontrado');
};

const ingestOfficialContent = async (payload, actorId = null) => {
  const { data, error } = await contentRepo.crearOActualizarContenido(payload);
  if (error) {
    throw new Error(`Error al persistir contenido médico: ${error.message}`);
  }

  if (actorId) {
    await auditService.registrar({
      usuarioId: actorId,
      tipoEntidad: 'contenido_salud',
      idEntidad: data.id,
      accion: 'INGESTA_CONTENIDO_OFICIAL',
      detalle: { titulo: data.titulo, fuente: data.fuente }
    });
  }

  return data;
};

module.exports = {
  getPublishedContent,
  getContentById,
  ingestOfficialContent
};
