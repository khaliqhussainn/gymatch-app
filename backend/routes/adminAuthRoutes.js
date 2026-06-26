const express = require('express');
const router = express.Router();
const adminAuthController = require('../controllers/adminAuthController');

// Admin-only routes
router.post('/login', adminAuthController.adminLogin);
router.post('/verify', adminAuthController.verifyToken);

module.exports = router;
