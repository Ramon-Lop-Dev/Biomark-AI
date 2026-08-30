// Persiste notificaciones pendientes de entrega al usuario.
const supabase = require('../../config/supabase');

// Columnas reales de notificaciones: usuario_id, tipo, mensaje, fecha_envio,
// fecha_lectura, fecha_creacion (default now()). "fecha_envio" se deja NULL
// aquí a propósito: se marcará cuando exista el envío real (push/SMS vía
// n8n, Fase 7) — esta fila hoy solo dice "esto debería notificarse".
const crear = ({ usuarioId, tipo, mensaje }) =>
  supabase
    .from('notificaciones')
    .insert({ usuario_id: usuarioId, tipo, mensaje })
    .select()
    .single();

module.exports = { crear };
