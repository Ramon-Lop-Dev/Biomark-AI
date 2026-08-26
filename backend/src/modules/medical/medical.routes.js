const express = require('express');
const { getMedicalHistory, createMedicalRecord } = require('./medical.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { createMedicalRecordSchema } = require('./medical.validator');
const router = express.Router();

router.use(verifyToken);

router.get('/', getMedicalHistory);
router.post('/', validate(createMedicalRecordSchema), createMedicalRecord);

module.exports = router;
