const pool = require('../config/connection');

/**
 * Public: get active location presets for the mobile app's
 * "Location Preferences" screen. Requires no auth.
 */
exports.getActiveLocations = async (req, res) => {
  try {
    const [locations] = await pool.query(
      "SELECT id, label, subtitle, latitude, longitude FROM location_presets WHERE status = 'active' ORDER BY id ASC"
    );
    res.json({ success: true, data: locations });
  } catch (error) {
    console.error('Error fetching location presets:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch location presets' });
  }
};
