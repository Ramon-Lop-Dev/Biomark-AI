// Expone la escritura uniforme y resiliente de auditoría.
const auditRepo = require('./audit.repository');

/**
 * Registra una entrada de auditoría. Se usa como hook transversal desde
 * los services de cualquier módulo (auth, medical, community, etc.)
 * cada vez que se crea/edita/borra un recurso relevante.
 *
 * Importante: un fallo al auditar NUNCA debe tumbar la operación de
 * negocio que la originó (por eso nunca lanza, solo loguea).
 *
 * @param {Object} params
 * @param {string|null} params.usuarioId - id interno (public.usuarios.id) de quien ejecuta la acción
 * @param {string} params.tipoEntidad - nombre de la tabla afectada (ej. 'usuarios', 'historial_medico')
 * @param {string} params.idEntidad - id de la fila afectada
 * @param {string} params.accion - acción realizada (ej. 'REGISTRO_EMAIL', 'ACTUALIZACION', 'BORRADO')
 * @param {Object} [params.detalle] - contexto adicional en JSON (ej. campos cambiados)
 */
const registrar = async ({ usuarioId, tipoEntidad, idEntidad, accion, detalle }) => {
  try {
    const { error } = await auditRepo.crearRegistro({ usuarioId, tipoEntidad, idEntidad, accion, detalle });
    if (error) {
      console.error('[Auditoría] No se pudo registrar:', error.message);
    }
  } catch (err) {
    console.error('[Auditoría] Error inesperado al registrar:', err.message);
  }
};

module.exports = { registrar };
