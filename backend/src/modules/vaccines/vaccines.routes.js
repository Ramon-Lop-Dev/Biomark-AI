const express = require('express');
const { getVaccines, addVaccine } = require('./vaccines.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const router = express.Router();

router.use(verifyToken);
router.get('/', getVaccines);
router.post('/', addVaccine);

module.exports = router;