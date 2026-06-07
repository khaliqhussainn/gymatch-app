const express = require('express');
const router = express.Router();
const notificationController = require('../controllers/notificationController');
const authMiddleware = require('../middleware/authMiddleware');

// Protect all routes with auth middleware
router.use(authMiddleware.authenticate);

router.get('/', notificationController.getNotifications);
router.post('/read-all', notificationController.markAllRead);
router.post('/clear', notificationController.clearAll);
router.post('/:id/read', notificationController.markRead);

module.exports = router;
