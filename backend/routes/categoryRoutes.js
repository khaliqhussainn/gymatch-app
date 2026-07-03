const express = require('express');
const router = express.Router();
const categoryController = require('../controllers/categoryController');

// Public route — active gym categories, consumed by the mobile app
router.get('/', categoryController.getActiveCategories);

module.exports = router;
