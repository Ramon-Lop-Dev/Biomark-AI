// Define las rutas autenticadas de vacunación.
const express = require('express');
const { getVaccines, addVaccine, getRecommendations } = require('./vaccines.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { addVaccineSchema } = require('./vaccines.validator');
const router = express.Router();

router.use(verifyToken);
router.get('/', getVaccines);
router.get('/recommendations', getRecommendations);
router.post('/', validate(addVaccineSchema), addVaccine);

module.exports = router;
