const pool = require('../config/connection');

/**
 * Get all location presets (admin — includes inactive)
 */
exports.getAllLocations = async (req, res) => {
  try {
    const [locations] = await pool.query(
      'SELECT id, label, subtitle, latitude, longitude, status, created_at, updated_at FROM location_presets ORDER BY created_at DESC'
    );
    res.json({ success: true, data: locations });
  } catch (error) {
    console.error('Error fetching location presets:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch location presets' });
  }
};

/**
 * Create a new location preset
 */
exports.createLocation = async (req, res) => {
  try {
    const { label, subtitle, latitude, longitude } = req.body;

    if (!label || label.trim() === '') {
      return res.status(400).json({ success: false, error: 'Label is required' });
    }
    if (latitude === undefined || longitude === undefined || latitude === '' || longitude === '') {
      return res.status(400).json({ success: false, error: 'Latitude and longitude are required' });
    }

    const [result] = await pool.query(
      'INSERT INTO location_presets (label, subtitle, latitude, longitude, status) VALUES (?, ?, ?, ?, "active")',
      [label.trim(), (subtitle || '').trim(), parseFloat(latitude), parseFloat(longitude)]
    );

    const [newLocation] = await pool.query(
      'SELECT id, label, subtitle, latitude, longitude, status, created_at, updated_at FROM location_presets WHERE id = ?',
      [result.insertId]
    );

    res.status(201).json({ success: true, data: newLocation[0] });
  } catch (error) {
    console.error('Error creating location preset:', error);
    res.status(500).json({ success: false, error: 'Failed to create location preset' });
  }
};

/**
 * Update a location preset
 */
exports.updateLocation = async (req, res) => {
  try {
    const { id } = req.params;
    const { label, subtitle, latitude, longitude } = req.body;

    if (!label || label.trim() === '') {
      return res.status(400).json({ success: false, error: 'Label is required' });
    }
    if (latitude === undefined || longitude === undefined || latitude === '' || longitude === '') {
      return res.status(400).json({ success: false, error: 'Latitude and longitude are required' });
    }

    const [result] = await pool.query(
      'UPDATE location_presets SET label = ?, subtitle = ?, latitude = ?, longitude = ? WHERE id = ?',
      [label.trim(), (subtitle || '').trim(), parseFloat(latitude), parseFloat(longitude), id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, error: 'Location preset not found' });
    }

    const [updatedLocation] = await pool.query(
      'SELECT id, label, subtitle, latitude, longitude, status, created_at, updated_at FROM location_presets WHERE id = ?',
      [id]
    );

    res.json({ success: true, data: updatedLocation[0] });
  } catch (error) {
    console.error('Error updating location preset:', error);
    res.status(500).json({ success: false, error: 'Failed to update location preset' });
  }
};

/**
 * Update location preset status (active/inactive)
 */
exports.updateLocationStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || !['active', 'inactive'].includes(status)) {
      return res.status(400).json({ success: false, error: 'Valid status (active/inactive) is required' });
    }

    const [result] = await pool.query(
      'UPDATE location_presets SET status = ? WHERE id = ?',
      [status, id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, error: 'Location preset not found' });
    }

    const [updatedLocation] = await pool.query(
      'SELECT id, label, subtitle, latitude, longitude, status, created_at, updated_at FROM location_presets WHERE id = ?',
      [id]
    );

    res.json({ success: true, data: updatedLocation[0] });
  } catch (error) {
    console.error('Error updating location preset status:', error);
    res.status(500).json({ success: false, error: 'Failed to update location preset status' });
  }
};

/**
 * Delete a location preset
 */
exports.deleteLocation = async (req, res) => {
  try {
    const { id } = req.params;

    const [result] = await pool.query(
      'DELETE FROM location_presets WHERE id = ?',
      [id]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, error: 'Location preset not found' });
    }

    res.json({ success: true, message: 'Location preset deleted successfully' });
  } catch (error) {
    console.error('Error deleting location preset:', error);
    res.status(500).json({ success: false, error: 'Failed to delete location preset' });
  }
};
