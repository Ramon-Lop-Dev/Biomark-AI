const express = require('express');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { getGoals, createGoal, updateMilestone } = require('./goals.controller');
const { createGoalSchema, updateMilestoneSchema } = require('./goals.validator');

const router = express.Router();
router.use(verifyToken);
router.get('/', getGoals);
router.post('/', validate(createGoalSchema), createGoal);
router.patch('/:objetivoId/hitos/:hitoId', validate(updateMilestoneSchema), updateMilestone);

module.exports = router;