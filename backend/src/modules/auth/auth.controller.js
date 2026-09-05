// Atiende las solicitudes HTTP de registro, acceso y recuperación.
const authService = require('./auth.service');
const asyncHandler = require('../../utils/asyncHandler');

// El body ya llega validado y saneado por el middleware validate()
// (ver auth.routes.js + auth.validator.js), así que los controllers son
// deliberadamente delgados: solo llaman al service y traducen el
// resultado a una respuesta HTTP. Cualquier error se propaga a
// errorHandler.middleware.js gracias a asyncHandler.

const register = asyncHandler(async (req, res) => {
  const { email, password, full_name } = req.body;
  const result = await authService.registerUser(email, password, full_name);
  return res.status(201).json(result);
});

const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;
  const result = await authService.loginUser(email, password);
  return res.status(200).json(result);
});

// POST /api/auth/google — recibe el id_token nativo de Google Sign-In
// generado en la app Flutter.
const loginGoogle = asyncHandler(async (req, res) => {
  const { id_token, access_token, full_name } = req.body;
  const result = await authService.loginWithGoogle(id_token, access_token, full_name);
  return res.status(200).json(result);
});

// POST /api/auth/logout — requiere estar autenticado (verifyToken deja
// req.usuarioId y req.token listos, ver auth.routes.js).
const logout = asyncHandler(async (req, res) => {
  const result = await authService.logoutUser(req.usuarioId, req.token);
  return res.status(200).json(result);
});

// POST /api/auth/refresh
const refresh = asyncHandler(async (req, res) => {
  const { refresh_token } = req.body;
  const result = await authService.refreshToken(refresh_token);
  return res.status(200).json(result);
});

// POST /api/auth/forgot-password
const forgotPassword = asyncHandler(async (req, res) => {
  const { email, redirect_to } = req.body;
  const result = await authService.forgotPassword(email, redirect_to);
  return res.status(200).json(result);
});

// POST /api/auth/reset-password
const resetPassword = asyncHandler(async (req, res) => {
  const { access_token, new_password } = req.body;
  const result = await authService.resetPassword(access_token, new_password);
  return res.status(200).json(result);
});

module.exports = { register, login, loginGoogle, logout, refresh, forgotPassword, resetPassword };
