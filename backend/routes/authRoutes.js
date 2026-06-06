const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// Public routes
router.post('/register', authController.register);
router.post('/login', authController.login);
router.post('/google-login', authController.googleLogin);
router.get('/guest-token', authController.guestToken);

// Protected user routes
router.use(authMiddleware.authenticate);

// Admin-only routes
router.get('/admin/users', 
  authMiddleware.authorize('admin'), 
  (req, res) => {
    // Implement user management
  }
);

module.exports = router;