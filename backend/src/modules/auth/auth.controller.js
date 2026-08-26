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

module.exports = { register, login, loginGoogle };
