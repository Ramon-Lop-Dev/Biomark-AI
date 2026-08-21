const express = require('express');
const { register, login } = require('./auth.controller');
const router = express.Router();

// Rutas de autenticación (no requieren JWT)
router.post('/register', register);
router.post('/login', login);

module.exports = router;