const pool = require('../config/connection');

class Gym {
  /**
   * Find nearby gyms using Haversine formula.
   * Returns gyms within radiusKm, sorted by distance.
   */
  static async findNearby({ lat, lng, radiusKm = 10, search = '', category = '', featuredOnly = false }) {
    let query = `
      SELECT
        g.id, g.name, g.sub_name, g.location_name, g.near_location,
        g.latitude, g.longitude, g.rating, g.is_open,
        g.open_hours, g.contact_phone, g.category,
        COALESCE(g.is_featured, 0) AS is_featured,
        (6371 * acos(
          GREATEST(-1, LEAST(1,
            cos(radians(?)) * cos(radians(g.latitude)) *
            cos(radians(g.longitude) - radians(?)) +
            sin(radians(?)) * sin(radians(g.latitude))
          ))
        )) AS distance_km,
        (SELECT i.image_url FROM gym_images i WHERE i.gym_id = g.id ORDER BY i.sort_order ASC LIMIT 1) AS cover_image,
        (SELECT COUNT(*) FROM active_partners ap WHERE ap.gym_id = g.id) AS active_partners_count
      FROM gyms g
      WHERE 1=1
    `;
    const params = [lat, lng, lat];

    if (featuredOnly) {
      query += ` AND COALESCE(g.is_featured, 0) = 1`;
    }

    if (category && category.toUpperCase() !== 'ALL' && category.toUpperCase() !== 'GYM') {
      query += ` AND UPPER(g.category) = ?`;
      params.push(category.toUpperCase());
    }

    if (search && search.trim()) {
      query += ` AND (g.name LIKE ? OR g.location_name LIKE ? OR g.sub_name LIKE ?)`;
      const term = `%${search.trim()}%`;
      params.push(term, term, term);
    }

    query += `
      HAVING distance_km <= ?
      ORDER BY COALESCE(g.is_featured, 0) DESC, distance_km ASC
      LIMIT 50
    `;
    params.push(radiusKm);

    const [rows] = await pool.query(query, params);
    return rows;
  }

  /**
   * Get full gym detail with images, amenities, and plans.
   */
  static async findById(id) {
    const [gyms] = await pool.query(
      `SELECT g.id, g.name, g.sub_name, g.location_name, g.near_location,
        g.latitude, g.longitude, g.rating, g.is_open,
        g.open_hours, g.contact_phone, g.category,
        COALESCE(g.is_featured, 0) AS is_featured,
        g.created_at,
        (SELECT COUNT(*) FROM active_partners ap WHERE ap.gym_id = g.id) AS active_partners_count
       FROM gyms g WHERE g.id = ?`,
      [id]
    );
    if (gyms.length === 0) return null;

    const gym = gyms[0];

    const [images] = await pool.query(
      'SELECT image_url FROM gym_images WHERE gym_id = ? ORDER BY sort_order ASC',
      [id]
    );
    const [amenities] = await pool.query(
      'SELECT name FROM gym_amenities WHERE gym_id = ?',
      [id]
    );
    const [plans] = await pool.query(
      'SELECT * FROM gym_membership_plans WHERE gym_id = ? ORDER BY is_premium ASC',
      [id]
    );

    return {
      ...gym,
      images: images.map(img => img.image_url),
      amenities: amenities.map(am => am.name),
      plans: plans.map(pl => ({
        ...pl,
        features: (() => {
          try { return JSON.parse(pl.features); } catch { return []; }
        })(),
      })),
    };
  }

  /**
   * Toggle saved/favorite status for a user and gym.
   * Returns { saved: true/false }
   */
  static async toggleSaved(userId, gymId) {
    const [existing] = await pool.query(
      'SELECT 1 FROM saved_gyms WHERE user_id = ? AND gym_id = ?',
      [userId, gymId]
    );
    if (existing.length > 0) {
      await pool.query('DELETE FROM saved_gyms WHERE user_id = ? AND gym_id = ?', [userId, gymId]);
      return { saved: false };
    } else {
      await pool.query('INSERT INTO saved_gyms (user_id, gym_id) VALUES (?, ?)', [userId, gymId]);
      return { saved: true };
    }
  }

  /**
   * Get all gyms saved by a user.
   */
  static async getSaved(userId) {
    const [rows] = await pool.query(
      `SELECT g.id, g.name, g.sub_name, g.location_name, g.rating, g.category,
        COALESCE(g.is_featured, 0) AS is_featured,
        (SELECT i.image_url FROM gym_images i WHERE i.gym_id = g.id ORDER BY i.sort_order LIMIT 1) AS cover_image
       FROM saved_gyms s
       JOIN gyms g ON g.id = s.gym_id
       WHERE s.user_id = ?
       ORDER BY g.is_featured DESC, s.created_at DESC`,
      [userId]
    );
    return rows;
  }

  /**
   * Check if a gym is saved by the user.
   */
  static async isSaved(userId, gymId) {
    const [rows] = await pool.query(
      'SELECT 1 FROM saved_gyms WHERE user_id = ? AND gym_id = ?',
      [userId, gymId]
    );
    return rows.length > 0;
  }
}

module.exports = Gym;
