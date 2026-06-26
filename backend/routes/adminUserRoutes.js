const express = require('express');
const router = express.Router();
const adminUserController = require('../controllers/adminUserController');

// Admin-only routes for user management
router.get('/', adminUserController.getAllUsers);
router.get('/:id', adminUserController.getUserProfile);
router.patch('/:id/status', adminUserController.updateUserStatus);

module.exports = router;
