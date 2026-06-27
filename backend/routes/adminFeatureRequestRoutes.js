const express = require('express');
const router = express.Router();
const adminFeatureRequestController = require('../controllers/adminFeatureRequestController');
const authMiddleware = require('../middleware/authMiddleware');

// Admin-only routes for feature request management
router.get('/', adminFeatureRequestController.getAllFeatureRequests);
router.patch('/:id/approve', adminFeatureRequestController.approveFeatureRequest);
router.patch('/:id/reject', adminFeatureRequestController.rejectFeatureRequest);

// User routes for creating and viewing their own feature requests
router.post('/', authMiddleware.authenticate, adminFeatureRequestController.createFeatureRequest);
router.get('/my-requests', authMiddleware.authenticate, adminFeatureRequestController.getUserFeatureRequests);

module.exports = router;
