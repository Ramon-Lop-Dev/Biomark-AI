const express = require('express');
const { register, login, loginGoogle } = require('./auth.controller');
const { validate } = require('../../middleware/validate.middleware');
const { registerSchema, loginSchema, googleAuthSchema } = require('./auth.validator');

const router = express.Router();

// Rutas de autenticación (no requieren JWT — son las que lo emiten)
router.post('/register', validate(registerSchema), register);
router.post('/login', validate(loginSchema), login);

// Login/registro con Google OAuth (ID Token nativo desde Flutter)
router.post('/google', validate(googleAuthSchema), loginGoogle);

module.exports = router;
