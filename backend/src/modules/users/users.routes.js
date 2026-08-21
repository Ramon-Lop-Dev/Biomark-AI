const express = require('express');
const { getProfile } = require('./users.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const router = express.Router();

// Al poner verifyToken antes de getProfile, protegemos esta ruta
router.get('/profile', verifyToken, getProfile);

module.exports = router;