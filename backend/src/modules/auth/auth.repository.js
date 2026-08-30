// Ejecuta operaciones de autenticación y persistencia de usuarios.
const supabase = require('../../config/supabase');       // service_role: solo para tablas de dominio
const supabaseAuth = require('../../config/supabaseAuth'); // anon: solo para operaciones de Supabase Auth

// --- Supabase Auth (siempre con el cliente anon) ---

const signUpWithPassword = (email, password, fullName) =>
  supabaseAuth.auth.signUp({
    email,
    password,
    options: { data: { full_name: fullName } }
  });

const signInWithPassword = (email, password) =>
  supabaseAuth.auth.signInWithPassword({ email, password });

// Verifica un ID Token de Google directamente con Supabase Auth (Supabase
// a su vez lo valida contra Google). No requiere flujo de redirect, por
// eso funciona bien para apps móviles.
const signInWithGoogleIdToken = (idToken, accessToken) =>
  supabaseAuth.auth.signInWithIdToken({
    provider: 'google',
    token: idToken,
    access_token: accessToken
  });

// Revoca la sesión asociada a este access_token. Requiere el cliente de
// service_role (admin API) — el cliente anon no puede revocar sesiones
// de otros usuarios, solo la suya propia en memoria (que aquí no existe,
// porque el backend nunca mantiene sesión de cliente).
// scope 'global' invalida TODOS los refresh tokens de este usuario (todos
// sus dispositivos), no solo el de este access_token puntual.
const signOut = (accessToken) => supabase.auth.admin.signOut(accessToken, 'global');

// Cambia el access_token vencido por uno nuevo usando el refresh_token,
// sin pedir password de nuevo. Se usa el cliente anon porque es una
// operación de autenticación normal, no administrativa.
const refreshSession = (refreshToken) => supabaseAuth.auth.refreshSession({ refresh_token: refreshToken });

// Envía el correo de recuperación de contraseña (Supabase gestiona la
// plantilla y el enlace). Se usa el cliente anon: es lo mismo que haría
// cualquier cliente público, no requiere privilegios de admin.
const resetPasswordForEmail = (email) => supabaseAuth.auth.resetPasswordForEmail(email);

// Cambia la contraseña de un usuario ya identificado (por su id interno
// de Supabase Auth, NO el id de public.usuarios) usando la Admin API.
// Se usa en vez de auth.updateUser() porque el backend nunca mantiene una
// sesión activa del usuario que le permita llamar a ese método con el
// cliente anon — en su lugar, primero se valida el access_token de
// recuperación con supabase.auth.getUser() (ver auth.service.resetPassword)
// y luego se fuerza el cambio aquí con privilegios de admin.
const updateUserPasswordById = (authUserId, newPassword) =>
  supabase.auth.admin.updateUserById(authUserId, { password: newPassword });

// --- Tablas de dominio (siempre con el cliente service_role) ---

const findUsuarioByAuthId = (authId) =>
  supabase.from('usuarios').select('*').eq('auth_id', authId).maybeSingle();

const createUsuario = (authId, correo) =>
  supabase.from('usuarios').insert({ auth_id: authId, correo }).select().single();

const createPerfil = (usuarioId, nombreCompleto) =>
  supabase.from('perfiles').insert({ usuario_id: usuarioId, nombre_completo: nombreCompleto });

// Usado únicamente para revertir un insert en "usuarios" cuando el insert
// subsecuente en "perfiles" falla (ver auth.service.js: aprovisionarUsuario).
const eliminarUsuario = (usuarioId) =>
  supabase.from('usuarios').delete().eq('id', usuarioId);

module.exports = {
  signUpWithPassword,
  signInWithPassword,
  signInWithGoogleIdToken,
  signOut,
  refreshSession,
  resetPasswordForEmail,
  updateUserPasswordById,
  findUsuarioByAuthId,
  createUsuario,
  createPerfil,
  eliminarUsuario
};
