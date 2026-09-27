// Resuelve el usuario interno desde Supabase Auth.
const supabase = require('../config/supabase');

/**
 * Dado el auth_id (data.user.id devuelto por supabase.auth.getUser, que
 * corresponde a auth.users.id), devuelve la fila de public.usuarios
 * (id interno, rol, activo).
 *
 * Es indispensable usar el id devuelto aquí (no auth_id) en cualquier
 * consulta contra tablas de dominio, porque todas sus foreign keys
 * (usuario_id) apuntan a public.usuarios(id), no a auth.users(id).
 *
 * También devolvemos "rol" y "activo" porque el middleware de auth los
 * necesita para RBAC y para bloquear cuentas desactivadas.
 */
async function resolverUsuario(authId) {
  const { data, error } = await supabase
    .from('usuarios')
    .select('id, rol, activo, centro_salud_id, estado_cuenta')
    .eq('auth_id', authId)
    .single();

  // Degradar con elegancia si la migración de las nuevas columnas aún no se ha ejecutado en este entorno
  if (error && (error.code === '42703' || error.message?.includes('column'))) {
    const fallback = await supabase
      .from('usuarios')
      .select('id, rol, activo')
      .eq('auth_id', authId)
      .single();
    if (!fallback.error && fallback.data) {
      return { ...fallback.data, centro_salud_id: null, estado_cuenta: 'ACTIVO' };
    }
  }

  if (error || !data) {
    const err = new Error('Usuario no encontrado en el sistema (tabla usuarios)');
    err.status = 404;
    throw err;
  }

  return data;
}

module.exports = { resolverUsuario };
