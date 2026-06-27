const pool = require('../config/connection');

/**
 * Get all feature requests
 */
exports.getAllFeatureRequests = async (req, res) => {
  try {
    const [requests] = await pool.query(
      `SELECT fr.id, fr.request_type, fr.entity_id, fr.requester_id, fr.status, fr.reason, fr.created_at,
              u.name as requester_name, u.email as requester_email,
              CASE 
                WHEN fr.request_type = 'gym' THEN (SELECT name FROM gyms WHERE id = fr.entity_id)
                WHEN fr.request_type = 'user' THEN (SELECT name FROM profiles WHERE user_id = fr.entity_id)
              END as entity_name
       FROM feature_requests fr
       LEFT JOIN users u ON fr.requester_id = u.id
       ORDER BY fr.created_at DESC`
    );
    res.json({ success: true, data: requests });
  } catch (error) {
    console.error('Error fetching feature requests:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch feature requests' });
  }
};

/**
 * Approve feature request
 */
exports.approveFeatureRequest = async (req, res) => {
  try {
    const { id } = req.params;

    // Get the feature request
    const [requests] = await pool.query('SELECT * FROM feature_requests WHERE id = ?', [id]);
    if (!requests.length) {
      return res.status(404).json({ success: false, error: 'Feature request not found' });
    }

    const request = requests[0];

    // Update request status
    await pool.query('UPDATE feature_requests SET status = ? WHERE id = ?', ['approved', id]);

    // Update entity is_featured status
    if (request.request_type === 'gym') {
      await pool.query('UPDATE gyms SET is_featured = TRUE WHERE id = ?', [request.entity_id]);
    } else if (request.request_type === 'user') {
      // For users, we might need to add an is_featured column to profiles or users table
      // For now, we'll just update the request status
      await pool.query('UPDATE profiles SET is_featured = TRUE WHERE user_id = ?', [request.entity_id]);
    }

    res.json({ success: true, message: 'Feature request approved' });
  } catch (error) {
    console.error('Error approving feature request:', error);
    res.status(500).json({ success: false, error: 'Failed to approve feature request' });
  }
};

/**
 * Reject feature request
 */
exports.rejectFeatureRequest = async (req, res) => {
  try {
    const { id } = req.params;

    const [requests] = await pool.query('SELECT * FROM feature_requests WHERE id = ?', [id]);
    if (!requests.length) {
      return res.status(404).json({ success: false, error: 'Feature request not found' });
    }

    await pool.query('UPDATE feature_requests SET status = ? WHERE id = ?', ['rejected', id]);

    res.json({ success: true, message: 'Feature request rejected' });
  } catch (error) {
    console.error('Error rejecting feature request:', error);
    res.status(500).json({ success: false, error: 'Failed to reject feature request' });
  }
};

/**
 * Create feature request (gym owner or user)
 */
exports.createFeatureRequest = async (req, res) => {
  try {
    const { request_type, entity_id, reason } = req.body;
    const requester_id = req.user.userId;

    // Validate request_type
    if (!['gym', 'user'].includes(request_type)) {
      return res.status(400).json({ success: false, error: 'Invalid request type. Must be "gym" or "user"' });
    }

    // Check if there's already a pending request for this entity
    const [existing] = await pool.query(
      'SELECT * FROM feature_requests WHERE request_type = ? AND entity_id = ? AND status = ?',
      [request_type, entity_id, 'pending']
    );

    if (existing.length > 0) {
      return res.status(400).json({ success: false, error: 'A pending feature request already exists for this entity' });
    }

    // Create feature request
    const [result] = await pool.query(
      'INSERT INTO feature_requests (request_type, entity_id, requester_id, reason, status) VALUES (?, ?, ?, ?, ?)',
      [request_type, entity_id, requester_id, reason || null, 'pending']
    );

    res.json({ 
      success: true, 
      message: 'Feature request submitted successfully',
      requestId: result.insertId 
    });
  } catch (error) {
    console.error('Error creating feature request:', error);
    res.status(500).json({ success: false, error: 'Failed to create feature request' });
  }
};

/**
 * Get feature requests for current user
 */
exports.getUserFeatureRequests = async (req, res) => {
  try {
    const requester_id = req.user.userId;

    const [requests] = await pool.query(
      `SELECT fr.id, fr.request_type, fr.entity_id, fr.status, fr.reason, fr.created_at,
              CASE 
                WHEN fr.request_type = 'gym' THEN (SELECT name FROM gyms WHERE id = fr.entity_id)
                WHEN fr.request_type = 'user' THEN (SELECT name FROM profiles WHERE user_id = fr.entity_id)
              END as entity_name
       FROM feature_requests fr
       WHERE fr.requester_id = ?
       ORDER BY fr.created_at DESC`,
      [requester_id]
    );

    res.json({ success: true, data: requests });
  } catch (error) {
    console.error('Error fetching user feature requests:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch feature requests' });
  }
};
