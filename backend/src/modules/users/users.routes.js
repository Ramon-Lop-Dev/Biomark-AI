const express = require('express');
const { getProfile, updateProfile } = require('./users.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { updateProfileSchema } = require('./users.validator');
const router = express.Router();

// Al poner verifyToken antes de los controllers, protegemos ambas rutas
router.get('/profile', verifyToken, getProfile);
router.put('/profile', verifyToken, validate(updateProfileSchema), updateProfile);

module.exports = router;