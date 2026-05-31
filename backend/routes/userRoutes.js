const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');

// @route   GET api/users
// @desc    Get all users
// @access  Public
router.get('/', userController.getUsers);

// @route   POST api/users
// @desc    Register user
// @access  Public
router.post('/', userController.registerUser);

module.exports = router;
