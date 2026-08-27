// Define las rutas autenticadas de síntomas.
const express = require('express');
const { getSymptoms, addSymptom } = require('./symptoms.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { addSymptomSchema } = require('./symptoms.validator');
const router = express.Router();

router.use(verifyToken);

router.get('/', getSymptoms);
router.post('/', validate(addSymptomSchema), addSymptom);

module.exports = router;
