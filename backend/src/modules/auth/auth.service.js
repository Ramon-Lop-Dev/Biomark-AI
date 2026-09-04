// Coordina autenticación, perfiles, sesiones y auditoría.
const authRepo = require('./auth.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');
const supabase = require('../../config/supabase');

/**
 * Crea las filas de dominio (usuarios + perfiles) para un auth_id que ya
 * existe en Supabase Auth (recién creado por signUp o por primer login
 * con Google). Si el insert de "perfiles" falla, revierte el insert de
 * "usuarios" (compensating transaction) para no dejar un usuario huérfano:
 * Supabase no permite una transacción real de dos inserts desde el
 * cliente JS, así que el rollback se hace a mano aquí.
 */
const aprovisionarUsuario = async (authId, correo, nombreCompleto) => {
  const { data: usuario, error: usuarioError } = await authRepo.createUsuario(authId, correo);

  if (usuarioError) {
    if (usuarioError.code === '23505') { // unique_violation
      throw new AppError('Ya existe una cuenta con ese correo', 409);
    }
    throw new AppError('No se pudo crear el registro en usuarios', 500);
  }

  const { error: perfilError } = await authRepo.createPerfil(usuario.id, nombreCompleto || correo);

  if (perfilError) {
    await authRepo.eliminarUsuario(usuario.id);
    throw new AppError('No se pudo crear el registro en perfiles', 500);
  }

  return usuario;
};

const registerUser = async (email, password, fullName) => {
  const { data, error } = await authRepo.signUpWithPassword(email, password, fullName);

  if (error) {
    const status = error.message?.toLowerCase().includes('already registered') ? 409 : 400;
    throw new AppError(error.message, status);
  }

  const usuario = await aprovisionarUsuario(data.user.id, email, fullName);

  await auditService.registrar({
    usuarioId: usuario.id,
    tipoEntidad: 'usuarios',
    idEntidad: usuario.id,
    accion: 'REGISTRO_EMAIL'
  });

  return {
    user_id: usuario.id,
    token: data.session?.access_token || null,
    refresh_token: data.session?.refresh_token || null,
    expires_in: data.session?.expires_in || null
  };
};

const loginUser = async (email, password) => {
  const { data, error } = await authRepo.signInWithPassword(email, password);

  if (error) {
    throw new AppError('Credenciales inválidas', 401);
  }

  return {
    token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    expires_in: data.session.expires_in || 3600
  };
};

/**
 * Login (o registro implícito, si es la primera vez) con Google.
 * El cliente Flutter obtiene un ID Token nativo con google_sign_in y lo
 * manda aquí. Supabase valida ese token contra Google y devuelve una
 * sesión igual que con email/password.
 *
 * Como con Google no hay un paso de "registro" separado, si es la
 * primera vez que este auth_id inicia sesión, se aprovisiona
 * usuarios+perfiles aquí mismo (equivalente a un registro automático).
 */
const loginWithGoogle = async (idToken, accessToken, fullNameFallback) => {
  const { data, error } = await authRepo.signInWithGoogleIdToken(idToken, accessToken);

  if (error) {
    throw new AppError(`No se pudo verificar la sesión de Google: ${error.message}`, 401);
  }

  const authUser = data.user;
  const correo = authUser.email;

  if (!correo) {
    throw new AppError('La cuenta de Google no tiene un correo verificado disponible', 400);
  }

  const { data: usuarioExistente, error: buscarError } = await authRepo.findUsuarioByAuthId(authUser.id);

  if (buscarError) {
    throw new AppError('Error al verificar el usuario en el sistema', 500);
  }

  let usuario = usuarioExistente;
  let esNuevo = false;

  if (!usuario) {
    const nombreCompleto = authUser.user_metadata?.full_name || fullNameFallback || correo;
    usuario = await aprovisionarUsuario(authUser.id, correo, nombreCompleto);
    esNuevo = true;
  } else if (!usuario.activo) {
    throw new AppError('Esta cuenta ha sido desactivada', 403);
  }

  await auditService.registrar({
    usuarioId: usuario.id,
    tipoEntidad: 'usuarios',
    idEntidad: usuario.id,
    accion: esNuevo ? 'REGISTRO_GOOGLE' : 'LOGIN_GOOGLE'
  });

  return {
    token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    expires_in: data.session.expires_in || 3600,
    is_new_user: esNuevo
  };
};

// Revoca la sesión (todos los refresh tokens del usuario, scope 'global'
// en el repository) — a partir de aquí el access_token actual sigue
// siendo válido hasta que expire por su cuenta (son JWT autocontenidos,
// no hay forma de invalidar uno puntual sin una lista de revocación
// aparte), pero ya no se podrá renovar con /auth/refresh.
const logoutUser = async (usuarioId, accessToken) => {
  const { error } = await authRepo.signOut(accessToken);

  if (error) {
    throw new AppError('No se pudo cerrar la sesión', 500);
  }

  await auditService.registrar({
    usuarioId,
    tipoEntidad: 'usuarios',
    idEntidad: usuarioId,
    accion: 'LOGOUT'
  });

  return { message: 'Sesión cerrada correctamente' };
};

const refreshToken = async (refreshToken) => {
  const { data, error } = await authRepo.refreshSession(refreshToken);

  if (error || !data.session) {
    throw new AppError('El refresh_token es inválido o ya expiró', 401);
  }

  return {
    token: data.session.access_token,
    refresh_token: data.session.refresh_token,
    expires_in: data.session.expires_in || 3600
  };
};

// SEGURIDAD: la respuesta es idéntica exista o no una cuenta con ese
// correo (mismo mensaje, mismo status 200) — de lo contrario este
// endpoint se convierte en un oráculo para enumerar qué correos están
// registrados en Biomark AI, algo especialmente sensible tratándose de
// una app de salud (revela quién es o no paciente/usuario de salud).
const MENSAJE_FORGOT_PASSWORD = 'Si existe una cuenta con ese correo, se enviaron instrucciones para restablecer la contraseña.';

const forgotPassword = async (email) => {
  const { error } = await authRepo.resetPasswordForEmail(email);

  if (error) {
    // Se loguea para diagnóstico interno, pero NUNCA se refleja al
    // cliente (ver nota de seguridad arriba) — salvo que sea un error de
    // infraestructura real (p. ej. Supabase caído), donde sí conviene
    // que el cliente sepa que falló y reintente.
    console.error('[Auth] Error al enviar correo de recuperación:', error.message);
    if (error.status && error.status >= 500) {
      throw new AppError('No se pudo procesar la solicitud, intenta de nuevo más tarde', 502);
    }
  }

  return { message: MENSAJE_FORGOT_PASSWORD };
};

// El access_token viene del enlace de recuperación que el usuario recibió
// por correo (Flutter lo captura vía deep link). Se valida con
// supabase.auth.getUser() -igual que hace el middleware normal- para
// resolver a qué usuario pertenece, y luego se fuerza la nueva
// contraseña con la Admin API (ver nota en auth.repository.updateUserPasswordById).
const resetPassword = async (accessToken, newPassword) => {
  const { data, error: getUserError } = await supabase.auth.getUser(accessToken);

  if (getUserError || !data.user) {
    throw new AppError('El enlace de recuperación es inválido o ya expiró', 401);
  }

  const { error } = await authRepo.updateUserPasswordById(data.user.id, newPassword);

  if (error) {
    throw new AppError('No se pudo actualizar la contraseña', 500);
  }

  const { data: usuario } = await authRepo.findUsuarioByAuthId(data.user.id);

  await auditService.registrar({
    usuarioId: usuario ? usuario.id : null,
    tipoEntidad: 'usuarios',
    idEntidad: usuario ? usuario.id : data.user.id,
    accion: 'RESET_PASSWORD'
  });

  return { message: 'Contraseña actualizada correctamente' };
};

module.exports = {
  registerUser,
  loginUser,
  loginWithGoogle,
  logoutUser,
  refreshToken,
  forgotPassword,
  resetPassword
};
