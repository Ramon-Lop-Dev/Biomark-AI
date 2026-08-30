// Define rutas de perfil, consentimiento y dispositivos del usuario.
const express = require('express');
const { getProfile, updateProfile } = require('./users.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { updateProfileSchema } = require('./users.validator');
const { getConsentimientos, putConsentimiento } = require('./consent.controller');
const { consentSchema } = require('./consent.validator');
const { registerToken, deleteToken } = require('./push.controller');
const { pushTokenSchema } = require('./push.validator');
const router = express.Router();

// Al poner verifyToken antes de los controllers, protegemos ambas rutas
router.get('/profile', verifyToken, getProfile);
router.put('/profile', verifyToken, validate(updateProfileSchema), updateProfile);
router.get('/consent', verifyToken, getConsentimientos);
router.put('/consent', verifyToken, validate(consentSchema), putConsentimiento);
router.post('/push-token', verifyToken, validate(pushTokenSchema), registerToken);
router.delete('/push-token', verifyToken, validate(pushTokenSchema.pick({ fcm_token: true })), deleteToken);

module.exports = router;