const express = require('express');
const router = express.Router();
const multer = require('multer');
const authController = require('../controllers/authController');
const authMiddleware = require('../middleware/authMiddleware');

// Configure multer for memory storage (for gym registration images)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB limit per file
  },
});

// Public routes
router.post('/register', authController.register);
router.post('/register-gym-owner', upload.array('images', 10), authController.registerGymOwner);
router.post('/login', authController.login);
router.post('/google-login', authController.googleLogin);
router.post('/apple-login', authController.appleLogin);
router.get('/guest-token', authController.guestToken);
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);
router.post('/parse-location', authController.parseLocation);

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