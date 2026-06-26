const pool = require('../config/connection');

/**
 * Get all gym categories
 */
exports.getAllCategories = async (req, res) => {
  try {
    const [categories] = await pool.query(
      'SELECT id, name, status, created_at, updated_at FROM gym_categories ORDER BY created_at DESC'
    );
    res.json({ success: true, data: categories });
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch categories' });
  }
};

/**
 * Create a new gym category
 */
exports.createCategory = async (req, res) => {
  try {
    const { name } = req.body;

    if (!name || name.trim() === '') {
      return res.status(400).json({ success: false, error: 'Category name is required' });
    }

    const [result] = await pool.query(
      'INSERT INTO gym_categories (name, status) VALUES (?, "active")',
      [name.trim()]
    );

    const [newCategory] = await pool.query(
      'SELECT id, name, status, created_at, updated_at FROM gym_categories WHERE id = ?',
      [result.insertId]
    );

    res.status(201).json({ success: true, data: newCategory[0] });
  } catch (error) {
    console.error('Error creating category:', error);
    res.status(500).json({ success: false, error: 'Failed to create category' });
  }
};

/**
 * Update a gym category
 */
exports.updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { name } = req.body;

    if (!name || name.trim() === '') {
      return res.status(400).json({ success: false, error: 'Category name is required' });
    }

    const [result] = await pool.query(
      'UPDATE gym_categories SET name = ? WHERE id = ?',
      [name.trim(), id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, error: 'Category not found' });
    }

    const [updatedCategory] = await pool.query(
      'SELECT id, name, status, created_at, updated_at FROM gym_categories WHERE id = ?',
      [id]
    );

    res.json({ success: true, data: updatedCategory[0] });
  } catch (error) {
    console.error('Error updating category:', error);
    res.status(500).json({ success: false, error: 'Failed to update category' });
  }
};

/**
 * Update category status (active/inactive)
 */
exports.updateCategoryStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['active', 'inactive'].includes(status)) {
      return res.status(400).json({ success: false, error: 'Valid status (active/inactive) is required' });
    }

    const [result] = await pool.query(
      'UPDATE gym_categories SET status = ? WHERE id = ?',
      [status, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, error: 'Category not found' });
    }

    const [updatedCategory] = await pool.query(
      'SELECT id, name, status, created_at, updated_at FROM gym_categories WHERE id = ?',
      [id]
    );

    res.json({ success: true, data: updatedCategory[0] });
  } catch (error) {
    console.error('Error updating category status:', error);
    res.status(500).json({ success: false, error: 'Failed to update category status' });
  }
};

/**
 * Delete a gym category
 */
exports.deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await pool.query(
      'DELETE FROM gym_categories WHERE id = ?',
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, error: 'Category not found' });
    }

    res.json({ success: true, message: 'Category deleted successfully' });
  } catch (error) {
    console.error('Error deleting category:', error);
    res.status(500).json({ success: false, error: 'Failed to delete category' });
  }
};
