const supabase = require('../config/supabase');

/**
 * Dado el auth_id (data.user.id devuelto por supabase.auth.getUser, que
 * corresponde a auth.users.id), devuelve el id interno de public.usuarios.
 *
 * Es indispensable usar este id (no auth_id) en cualquier consulta contra
 * tablas de dominio, porque todas sus foreign keys (usuario_id) apuntan a
 * public.usuarios(id), no a auth.users(id).
 */
async function resolverUsuarioId(authId) {
  const { data, error } = await supabase
    .from('usuarios')
    .select('id')
    .eq('auth_id', authId)
    .single();

  if (error || !data) {
    const err = new Error('Usuario no encontrado en el sistema (tabla usuarios)');
    err.status = 404;
    err.code = '404';
    throw err;
  }

  return data.id;
}

module.exports = { resolverUsuarioId };
