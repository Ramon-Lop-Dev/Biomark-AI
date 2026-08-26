const remindersService = require('./reminders.service');
const asyncHandler = require('../../utils/asyncHandler');

const getReminders = asyncHandler(async (req, res) => {
    const data = await remindersService.getReminders(req.usuarioId);
    return res.status(200).json(data);
});

const addReminder = asyncHandler(async (req, res) => {
    const registro = await remindersService.addReminder(req.usuarioId, req.body);
    return res.status(201).json(registro);
});

module.exports = { getReminders, addReminder };
