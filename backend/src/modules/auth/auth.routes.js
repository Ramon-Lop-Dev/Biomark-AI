const express = require('express');
const { register, login, loginGoogle, logout, refresh, forgotPassword, resetPassword } = require('./auth.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const {
  registerSchema,
  loginSchema,
  googleAuthSchema,
  refreshSchema,
  forgotPasswordSchema,
  resetPasswordSchema
} = require('./auth.validator');

const router = express.Router();

// Rutas de autenticación (no requieren JWT — son las que lo emiten,
// renuevan o lo dejan sin efecto antes de tener uno vigente)
router.post('/register', validate(registerSchema), register);
router.post('/login', validate(loginSchema), login);

// Login/registro con Google OAuth (ID Token nativo desde Flutter)
router.post('/google', validate(googleAuthSchema), loginGoogle);

// Renovar un access_token vencido sin volver a pedir password
router.post('/refresh', validate(refreshSchema), refresh);

// Recuperación de contraseña (dos pasos: pedir el correo, luego usar el
// access_token del enlace recibido para fijar la contraseña nueva)
router.post('/forgot-password', validate(forgotPasswordSchema), forgotPassword);
router.post('/reset-password', validate(resetPasswordSchema), resetPassword);

// Logout SÍ requiere sesión vigente: se necesita el access_token actual
// para revocarlo (ver auth.service.logoutUser).
router.post('/logout', verifyToken, logout);

module.exports = router;
