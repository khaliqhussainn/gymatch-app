const Gym = require('../models/Gym');
const pool = require('../config/connection');

/**
 * GET /api/gyms
 * Query: lat, lng, radius (km), search, category
 */
exports.getNearby = async (req, res) => {
  try {
    const { lat, lng, radius = 15, search = '', category = '' } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Location coordinates (lat, lng) are required.' });
    }

    const parsedLat = parseFloat(lat);
    const parsedLng = parseFloat(lng);

    if (isNaN(parsedLat) || isNaN(parsedLng)) {
      return res.status(400).json({ error: 'Invalid coordinates provided.' });
    }

    const gyms = await Gym.findNearby({
      lat: parsedLat,
      lng: parsedLng,
      radiusKm: parseFloat(radius),
      search,
      category,
    });

    res.json({ gyms, count: gyms.length });
  } catch (error) {
    console.error('[GymController.getNearby]', error);
    res.status(500).json({ error: 'Failed to fetch nearby gyms. Please try again.' });
  }
};

/**
 * GET /api/gyms/:id
 */
exports.getById = async (req, res) => {
  try {
    const { id } = req.params;
    const gym = await Gym.findById(parseInt(id, 10));

    if (!gym) {
      return res.status(404).json({ error: 'Gym not found.' });
    }

    // If user is authenticated, check if saved and if active partner
    let isSaved = false;
    let isActivePartner = false;
    if (req.user && req.user.userId) {
      isSaved = await Gym.isSaved(req.user.userId, gym.id);
      const [activeCheck] = await pool.query(
        'SELECT 1 FROM active_partners WHERE user_id = ? AND gym_id = ?',
        [req.user.userId, gym.id]
      );
      isActivePartner = activeCheck.length > 0;
    }

    res.json({ ...gym, is_saved: isSaved, is_active_partner: isActivePartner });
  } catch (error) {
    console.error('[GymController.getById]', error);
    res.status(500).json({ error: 'Failed to fetch gym details. Please try again.' });
  }
};

/**
 * POST /api/gyms/:id/favorite  (requires auth)
 */
exports.toggleFavorite = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.userId;

    const result = await Gym.toggleSaved(userId, parseInt(id, 10));
    res.json(result);
  } catch (error) {
    console.error('[GymController.toggleFavorite]', error);
    res.status(500).json({ error: 'Failed to update saved gym. Please try again.' });
  }
};

/**
 * GET /api/gyms/favorites  (requires auth)
 */
exports.getFavorites = async (req, res) => {
  try {
    const userId = req.user.userId;
    const gyms = await Gym.getSaved(userId);
    res.json({ gyms, count: gyms.length });
  } catch (error) {
    console.error('[GymController.getFavorites]', error);
    res.status(500).json({ error: 'Failed to fetch saved gyms. Please try again.' });
  }
};

/**
 * POST /api/gyms/:id/partner-toggle (requires auth)
 */
exports.togglePartnerStatus = async (req, res) => {
  try {
    const gymId = parseInt(req.params.id, 10);
    const userId = req.user.userId;
    const { status, workout_type, experience_level } = req.body;

    const [existing] = await pool.query(
      'SELECT 1 FROM active_partners WHERE user_id = ? AND gym_id = ?',
      [userId, gymId]
    );

    if (existing.length > 0) {
      await pool.query(
        'DELETE FROM active_partners WHERE user_id = ? AND gym_id = ?',
        [userId, gymId]
      );
      return res.json({ active: false });
    } else {
      const userStatus = status || 'Active Now';
      let workoutType = workout_type;
      let expLevel = experience_level;

      if (!workoutType || !expLevel) {
        const [profile] = await pool.query('SELECT workout_types FROM profiles WHERE user_id = ?', [userId]);
        if (profile.length > 0) {
          workoutType = workoutType || profile[0].workout_types || 'General';
        } else {
          workoutType = workoutType || 'General';
        }
        expLevel = expLevel || 'Intermediate';
      }

      await pool.query(
        'INSERT INTO active_partners (user_id, gym_id, status, workout_type, experience_level) VALUES (?, ?, ?, ?, ?)',
        [userId, gymId, userStatus, workoutType, expLevel]
      );
      return res.json({ active: true });
    }
  } catch (error) {
    console.error('[GymController.togglePartnerStatus]', error);
    res.status(500).json({ error: 'Failed to toggle partner status.' });
  }
};

/**
 * GET /api/gyms/:id/active-partners
 */
exports.getActivePartners = async (req, res) => {
  try {
    const gymId = parseInt(req.params.id, 10);
    let currentUserId = null;
    if (req.user && req.user.userId) {
      currentUserId = req.user.userId;
    }

    const query = `
      SELECT ap.*, p.name AS user_name, u.email
      FROM active_partners ap
      JOIN users u ON ap.user_id = u.id
      LEFT JOIN profiles p ON ap.user_id = p.user_id
      WHERE ap.gym_id = ? AND (? IS NULL OR ap.user_id != ?)
      ORDER BY ap.activated_at DESC
    `;
    const [rows] = await pool.query(query, [gymId, currentUserId, currentUserId]);
    
    const partners = rows.map(r => ({
      userId: r.user_id,
      gymId: r.gym_id,
      status: r.status,
      workoutType: r.workout_type || 'General',
      experienceLevel: r.experience_level || 'Intermediate',
      name: r.user_name || r.email.split('@')[0],
      activatedAt: r.activated_at
    }));

    res.json({ partners, count: partners.length });
  } catch (error) {
    console.error('[GymController.getActivePartners]', error);
    res.status(500).json({ error: 'Failed to fetch active partners.' });
  }
};
