// Define las rutas autenticadas de evolución y seguimiento.
const express = require('express');
const { getProgress, createProgress } = require('./progress.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { createProgressSchema } = require('./progress.validator');

const router = express.Router();
router.use(verifyToken);
router.get('/', getProgress);
router.post('/', validate(createProgressSchema), createProgress);

module.exports = router;
