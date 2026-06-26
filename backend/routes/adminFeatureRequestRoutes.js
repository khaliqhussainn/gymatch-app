const express = require('express');
const router = express.Router();
const adminFeatureRequestController = require('../controllers/adminFeatureRequestController');

// Admin-only routes for feature request management
router.get('/', adminFeatureRequestController.getAllFeatureRequests);
router.patch('/:id/approve', adminFeatureRequestController.approveFeatureRequest);
router.patch('/:id/reject', adminFeatureRequestController.rejectFeatureRequest);

module.exports = router;
