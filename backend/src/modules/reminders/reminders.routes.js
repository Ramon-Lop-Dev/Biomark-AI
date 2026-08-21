const express = require('express');
const { getReminders, addReminder } = require('./reminders.controller');
const { verifyToken } = require('../../middleware/auth.middleware');
const router = express.Router();

router.use(verifyToken);
router.get('/', getReminders);
router.post('/', addReminder);

module.exports = router;