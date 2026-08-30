// Persiste registros de auditoría en Supabase.
const supabase = require('../../config/supabase');

// Columnas reales de registros_auditoria: usuario_id (nullable), tipo_entidad,
// id_entidad, accion, detalle (jsonb), fecha_creacion (default now()).
const crearRegistro = ({ usuarioId, tipoEntidad, idEntidad, accion, detalle }) =>
  supabase.from('registros_auditoria').insert({
    usuario_id: usuarioId || null,
    tipo_entidad: tipoEntidad,
    id_entidad: idEntidad,
    accion,
    detalle: detalle || null
  });

module.exports = { crearRegistro };
