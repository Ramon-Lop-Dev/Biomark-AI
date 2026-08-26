const supabase = require('../../config/supabase');

// Trae usuarios + su perfil relacionado (1:1) en una sola consulta.
const findUsuarioConPerfil = (usuarioId) =>
  supabase
    .from('usuarios')
    .select('id, correo, rol, activo, fecha_creacion, perfiles(nombre_completo, fecha_nacimiento, sexo, telefono, direccion, municipio)')
    .eq('id', usuarioId)
    .single();

module.exports = { findUsuarioConPerfil };
