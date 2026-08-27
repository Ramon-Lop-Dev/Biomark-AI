// Atiende la confirmación interna de envíos realizada por n8n.
const remindersService = require('./reminders.service');
const asyncHandler = require('../../utils/asyncHandler');

const markReminderSent = asyncHandler(async (req, res) => {
  const data = await remindersService.markReminderSent(req.params.id);
  return res.status(200).json(data);
});

module.exports = { markReminderSent };