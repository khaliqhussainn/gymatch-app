const express = require('express');
const router = express.Router();
const adminLocationController = require('../controllers/adminLocationController');

// Admin-only routes for location presets
router.get('/', adminLocationController.getAllLocations);
router.post('/', adminLocationController.createLocation);
router.put('/:id', adminLocationController.updateLocation);
router.patch('/:id/status', adminLocationController.updateLocationStatus);
router.delete('/:id', adminLocationController.deleteLocation);

module.exports = router;
