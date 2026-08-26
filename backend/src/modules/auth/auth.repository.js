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
  findUsuarioByAuthId,
  createUsuario,
  createPerfil,
  eliminarUsuario
};
