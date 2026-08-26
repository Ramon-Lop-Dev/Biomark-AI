const authRepo = require('./auth.repository');
const AppError = require('../../utils/AppError');
const auditService = require('../audit/audit.service');

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
    token: data.session?.access_token || null
  };
};

const loginUser = async (email, password) => {
  const { data, error } = await authRepo.signInWithPassword(email, password);

  if (error) {
    throw new AppError('Credenciales inválidas', 401);
  }

  return {
    token: data.session.access_token,
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
    expires_in: data.session.expires_in || 3600,
    is_new_user: esNuevo
  };
};

module.exports = { registerUser, loginUser, loginWithGoogle };
