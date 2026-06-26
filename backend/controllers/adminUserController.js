const pool = require('../config/connection');

/**
 * Get all users
 */
exports.getAllUsers = async (req, res) => {
  try {
    const [users] = await pool.query(
      `SELECT u.id, u.email, u.role, u.status, u.created_at, p.name, p.age, p.gender, p.fitness_goals, p.workout_types, p.availability, p.about_me, p.profile_image
       FROM users u
       LEFT JOIN profiles p ON u.id = p.user_id
       ORDER BY u.created_at DESC`
    );
    res.json({ success: true, data: users });
  } catch (error) {
    console.error('Error fetching users:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch users' });
  }
};

/**
 * Get user profile by ID
 */
exports.getUserProfile = async (req, res) => {
  try {
    const { id } = req.params;

    const [users] = await pool.query(
      `SELECT u.id, u.email, u.role, u.status, u.created_at, p.name, p.age, p.gender, p.fitness_goals, p.workout_types, p.availability, p.about_me, p.profile_image
       FROM users u
       LEFT JOIN profiles p ON u.id = p.user_id
       WHERE u.id = ?`,
      [id]
    );

    if (!users.length) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    res.json({ success: true, data: users[0] });
  } catch (error) {
    console.error('Error fetching user profile:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch user profile' });
  }
};

/**
 * Update user status (active/suspended)
 */
exports.updateUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['active', 'suspended'].includes(status)) {
      return res.status(400).json({ success: false, error: 'Valid status (active/suspended) is required' });
    }

    // Check if user exists
    const [users] = await pool.query('SELECT id FROM users WHERE id = ?', [id]);
    if (!users.length) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const [result] = await pool.query(
      'UPDATE users SET status = ? WHERE id = ?',
      [status, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    const [updatedUser] = await pool.query(
      `SELECT u.id, u.email, u.role, u.status, u.created_at, p.name, p.age, p.gender, p.fitness_goals, p.workout_types, p.availability, p.about_me, p.profile_image
       FROM users u
       LEFT JOIN profiles p ON u.id = p.user_id
       WHERE u.id = ?`,
      [id]
    );

    res.json({ success: true, data: updatedUser[0] });
  } catch (error) {
    console.error('Error updating user status:', error);
    res.status(500).json({ success: false, error: 'Failed to update user status' });
  }
};
