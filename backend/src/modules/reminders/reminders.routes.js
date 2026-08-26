const express = require('express');
const { getReminders, addReminder } = require('./reminders.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const { validate } = require('../../middleware/validate.middleware');
const { addReminderSchema } = require('./reminders.validator');
const router = express.Router();

router.use(verifyToken);
router.get('/', getReminders);
router.post('/', validate(addReminderSchema), addReminder);

module.exports = router;
