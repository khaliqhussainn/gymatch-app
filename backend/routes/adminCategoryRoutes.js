const express = require('express');
const router = express.Router();
const adminCategoryController = require('../controllers/adminCategoryController');

// Admin-only routes for gym categories
router.get('/', adminCategoryController.getAllCategories);
router.post('/', adminCategoryController.createCategory);
router.put('/:id', adminCategoryController.updateCategory);
router.patch('/:id/status', adminCategoryController.updateCategoryStatus);
router.delete('/:id', adminCategoryController.deleteCategory);

module.exports = router;
