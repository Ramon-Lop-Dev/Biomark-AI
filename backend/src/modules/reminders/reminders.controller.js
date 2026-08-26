const remindersService = require('./reminders.service');
const asyncHandler = require('../../utils/asyncHandler');
const AppError = require('../../utils/AppError');

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const getReminders = asyncHandler(async (req, res) => {
    const data = await remindersService.getReminders(req.usuarioId);
    return res.status(200).json(data);
});

const addReminder = asyncHandler(async (req, res) => {
    const registro = await remindersService.addReminder(req.usuarioId, req.body);
    return res.status(201).json(registro);
});

const updateReminderStatus = asyncHandler(async (req, res) => {
    const { id } = req.params;

    if (!UUID_REGEX.test(id)) {
        throw new AppError('El id del recordatorio debe ser un UUID válido', 400);
    }

    const data = await remindersService.updateReminderStatus(req.usuarioId, id, req.body.estado);
    return res.status(200).json(data);
});

module.exports = { getReminders, addReminder, updateReminderStatus };
