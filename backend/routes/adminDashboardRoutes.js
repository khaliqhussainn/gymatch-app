const express = require('express');
const router = express.Router();
const adminDashboardController = require('../controllers/adminDashboardController');

// Admin-only routes for dashboard metrics
router.get('/stats', adminDashboardController.getDashboardStats);

module.exports = router;
