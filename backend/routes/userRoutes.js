const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');

// Profile routes (requires auth)
router.get('/profile', authMiddleware.authenticate, userController.getProfile);
router.put('/profile', authMiddleware.authenticate, userController.updateProfile);
router.delete('/account', authMiddleware.authenticate, userController.deleteAccount);

// Public partner profile (any authenticated user can view another user's profile)
router.get('/:id/profile', authMiddleware.optionalAuthenticate, userController.getPartnerProfile);

// Partner search
router.get('/search', userController.searchPartners);

// Nearby partners based on location
router.get('/nearby', authMiddleware.optionalAuthenticate, userController.getNearbyPartners);

// @route   GET api/users
// @desc    Get all users
// @access  Public
router.get('/', userController.getUsers);

// @route   POST api/users
// @desc    Register user
// @access  Public
router.post('/', userController.registerUser);

module.exports = router;
