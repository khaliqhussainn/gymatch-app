const pool = require('../config/connection');

class GymOwner {
  /**
   * Create a new gym owner
   */
  static async create({ userId, gymId }) {
    const [result] = await pool.query(
      'INSERT INTO gym_owners (user_id, gym_id) VALUES (?, ?)',
      [userId, gymId]
    );
    return { id: result.insertId, userId, gymId };
  }

  /**
   * Find gym owner by user ID
   */
  static async findByUserId(userId) {
    const [rows] = await pool.query(
      'SELECT * FROM gym_owners WHERE user_id = ?',
      [userId]
    );
    return rows[0];
  }

  /**
   * Find gym owner by gym ID
   */
  static async findByGymId(gymId) {
    const [rows] = await pool.query(
      'SELECT * FROM gym_owners WHERE gym_id = ?',
      [gymId]
    );
    return rows[0];
  }

  /**
   * Get gym owner with gym details
   */
  static async getGymOwnerWithDetails(userId) {
    const [rows] = await pool.query(
      `SELECT go.*, u.email, u.name as owner_name, g.name as gym_name, 
              g.location_name, g.category, g.is_featured, g.verification_status
       FROM gym_owners go
       JOIN users u ON go.user_id = u.id
       JOIN gyms g ON go.gym_id = g.id
       WHERE go.user_id = ?`,
      [userId]
    );
    return rows[0];
  }

  /**
   * Update gym owner's gym
   */
  static async updateGym(userId, newGymId) {
    await pool.query(
      'UPDATE gym_owners SET gym_id = ? WHERE user_id = ?',
      [newGymId, userId]
    );
  }

  /**
   * Delete gym owner
   */
  static async delete(userId) {
    await pool.query(
      'DELETE FROM gym_owners WHERE user_id = ?',
      [userId]
    );
  }

  /**
   * Get all gym owners with details
   */
  static async getAll() {
    const [rows] = await pool.query(
      `SELECT go.*, u.email, u.name as owner_name, u.created_at as user_created_at,
              g.name as gym_name, g.location_name, g.category, g.is_featured, g.verification_status
       FROM gym_owners go
       JOIN users u ON go.user_id = u.id
       JOIN gyms g ON go.gym_id = g.id
       ORDER BY go.created_at DESC`
    );
    return rows;
  }
}

module.exports = GymOwner;
