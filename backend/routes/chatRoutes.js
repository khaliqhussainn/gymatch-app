const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const authMiddleware = require('../middleware/authMiddleware');

// All chat routes require user authentication
router.post('/invite', authMiddleware.authenticate, chatController.invitePartner);
router.get('/thread-with/:partnerId', authMiddleware.authenticate, chatController.getThreadWithPartner);
router.get('/threads', authMiddleware.authenticate, chatController.getThreads);
router.get('/threads/:threadId/messages', authMiddleware.authenticate, chatController.getMessages);
router.post('/threads/:threadId/messages', authMiddleware.authenticate, chatController.sendMessage);
router.delete('/threads/:threadId', authMiddleware.authenticate, chatController.deleteThread);

module.exports = router;
