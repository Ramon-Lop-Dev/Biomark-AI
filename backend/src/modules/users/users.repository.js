// Consulta y actualiza usuarios y perfiles en Supabase.
const supabase = require('../../config/supabase');

// Trae usuarios + su perfil relacionado (1:1) en una sola consulta.
const findUsuarioConPerfil = (usuarioId) =>
  supabase
    .from('usuarios')
    .select('id, correo, rol, activo, fecha_creacion, perfiles(nombre_completo, fecha_nacimiento, sexo, telefono, direccion, municipio)')
    .eq('id', usuarioId)
    .single();

// Actualiza solo los campos recibidos en "cambios" (ya validados/saneados
// por Zod en users.validator.js). "fecha_actualizacion" se setea a mano
// porque la tabla no tiene trigger que lo haga automáticamente al hacer
// UPDATE (su DEFAULT now() solo aplica al INSERT).
const actualizarPerfil = (usuarioId, cambios) =>
  supabase
    .from('perfiles')
    .update({ ...cambios, fecha_actualizacion: new Date().toISOString() })
    .eq('usuario_id', usuarioId)
    .select('nombre_completo, fecha_nacimiento, sexo, telefono, direccion, municipio')
    .maybeSingle();

module.exports = { findUsuarioConPerfil, actualizarPerfil };
