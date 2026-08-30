// Define las rutas autenticadas de recordatorios.
const express = require('express');
const { getReminders, addReminder, updateReminderStatus } = require('./reminders.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { addReminderSchema, updateReminderStatusSchema } = require('./reminders.validator');
const router = express.Router();

router.use(verifyToken);
router.get('/', getReminders);
router.post('/', validate(addReminderSchema), addReminder);
router.patch('/:id', validate(updateReminderStatusSchema), updateReminderStatus);

module.exports = router;
