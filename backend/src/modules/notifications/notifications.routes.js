// Define endpoints para la bandeja de notificaciones in-app.
const express = require('express');
const {
  getMyNotifications,
  markNotificationAsRead,
  markAllNotificationsAsRead
} = require('./notifications.controller');
const { verifyToken } = require('../../middleware/auth.middleware');

const router = express.Router();

router.use(verifyToken);

router.get('/', getMyNotifications);
router.patch('/read-all', markAllNotificationsAsRead);
router.patch('/:id/read', markNotificationAsRead);

module.exports = router;
