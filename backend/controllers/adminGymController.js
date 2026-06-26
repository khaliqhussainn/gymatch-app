const pool = require('../config/connection');

/**
 * Get all gyms
 */
exports.getAllGyms = async (req, res) => {
  try {
    const [gyms] = await pool.query(
      `SELECT g.id, g.name, g.sub_name, g.location_name, g.near_location, g.latitude, g.longitude, 
              g.rating, g.is_open, g.open_hours, g.contact_phone, g.category, g.is_featured, g.created_at
       FROM gyms g
       ORDER BY g.created_at DESC`
    );
    res.json({ success: true, data: gyms });
  } catch (error) {
    console.error('Error fetching gyms:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch gyms' });
  }
};

/**
 * Get gym details by ID
 */
exports.getGymDetails = async (req, res) => {
  try {
    const { id } = req.params;

    const [gyms] = await pool.query(
      `SELECT g.id, g.name, g.sub_name, g.location_name, g.near_location, g.latitude, g.longitude, 
              g.rating, g.is_open, g.open_hours, g.contact_phone, g.category, g.is_featured, g.created_at
       FROM gyms g
       WHERE g.id = ?`,
      [id]
    );

    if (!gyms.length) {
      return res.status(404).json({ success: false, error: 'Gym not found' });
    }

    // Get gym images
    const [images] = await pool.query(
      'SELECT image_url, sort_order FROM gym_images WHERE gym_id = ? ORDER BY sort_order',
      [id]
    );

    // Get gym amenities
    const [amenities] = await pool.query(
      'SELECT name FROM gym_amenities WHERE gym_id = ?',
      [id]
    );

    // Get gym membership plans
    const [plans] = await pool.query(
      'SELECT id, name, price, billing_period, features, is_premium FROM gym_membership_plans WHERE gym_id = ?',
      [id]
    );

    const gymDetails = {
      ...gyms[0],
      images: images,
      amenities: amenities.map(a => a.name),
      membership_plans: plans
    };

    res.json({ success: true, data: gymDetails });
  } catch (error) {
    console.error('Error fetching gym details:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch gym details' });
  }
};
