// Atiende las solicitudes HTTP de la bandeja de notificaciones del usuario.
const notificationsService = require('./notifications.service');
const asyncHandler = require('../../utils/asyncHandler');

const getMyNotifications = asyncHandler(async (req, res) => {
  const { limit, offset, solo_no_leidas } = req.query;
  const result = await notificationsService.getNotifications(req.usuario.id, {
    limit: limit ? parseInt(limit, 10) : 30,
    offset: offset ? parseInt(offset, 10) : 0,
    soloNoLeidas: solo_no_leidas === 'true' || solo_no_leidas === true
  });
  return res.status(200).json(result);
});

const markNotificationAsRead = asyncHandler(async (req, res) => {
  const result = await notificationsService.markAsRead(req.usuario.id, req.params.id);
  return res.status(200).json(result);
});

const markAllNotificationsAsRead = asyncHandler(async (req, res) => {
  const result = await notificationsService.markAllAsRead(req.usuario.id);
  return res.status(200).json(result);
});

module.exports = {
  getMyNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead
};
