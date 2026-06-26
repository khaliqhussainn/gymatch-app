const express = require('express');
const router = express.Router();
const adminGymController = require('../controllers/adminGymController');

// Admin-only routes for gym management
router.get('/', adminGymController.getAllGyms);
router.get('/:id', adminGymController.getGymDetails);

module.exports = router;
