const express = require('express');
const router = express.Router();
const locationController = require('../controllers/locationController');

// Public route — active location presets, consumed by the mobile app
router.get('/', locationController.getActiveLocations);

module.exports = router;
