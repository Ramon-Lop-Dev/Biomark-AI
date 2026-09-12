// Define rutas de perfil, consentimiento y dispositivos del usuario.
const express = require('express');
const multer = require('multer');
const { getProfile, updateProfile, updateProfilePhoto } = require('./users.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { updateProfileSchema } = require('./users.validator');
const { getConsentimientos, putConsentimiento } = require('./consent.controller');
const { consentSchema } = require('./consent.validator');
const { registerToken, deleteToken } = require('./push.controller');
const { pushTokenSchema } = require('./push.validator');
const router = express.Router();
const uploadFoto = multer({
	storage: multer.memoryStorage(),
	limits: { fileSize: 5 * 1024 * 1024, files: 1 },
	fileFilter: (req, file, callback) => {
		const permitidos = ['image/jpeg', 'image/png', 'image/webp'];
		callback(null, permitidos.includes(file.mimetype));
	}
});

// Al poner verifyToken antes de los controllers, protegemos ambas rutas
router.get('/profile', verifyToken, getProfile);
router.put('/profile', verifyToken, validate(updateProfileSchema), updateProfile);
router.post('/profile/photo', verifyToken, uploadFoto.single('foto'), updateProfilePhoto);
router.get('/consent', verifyToken, getConsentimientos);
router.put('/consent', verifyToken, validate(consentSchema), putConsentimiento);
router.post('/push-token', verifyToken, validate(pushTokenSchema), registerToken);
router.delete('/push-token', verifyToken, validate(pushTokenSchema.pick({ fcm_token: true })), deleteToken);

module.exports = router;