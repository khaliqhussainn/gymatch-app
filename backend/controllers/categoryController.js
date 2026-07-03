const pool = require('../config/connection');

/**
 * Public: get active gym categories for the mobile app (filter chips,
 * gym registration/edit dropdowns). Unlike the admin endpoint, this only
 * returns categories the admin has marked active, and requires no auth.
 */
exports.getActiveCategories = async (req, res) => {
  try {
    const [categories] = await pool.query(
      "SELECT id, name FROM gym_categories WHERE status = 'active' ORDER BY id ASC"
    );
    res.json({ success: true, data: categories });
  } catch (error) {
    console.error('Error fetching categories:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch categories' });
  }
};
