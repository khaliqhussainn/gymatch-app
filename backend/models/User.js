const pool = require('../config/connection');

class User {
  static async findByEmail(email) {
    const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
    return rows[0];
  }

  static async create({ email, password, role = 'user' }) {
    const [result] = await pool.query(
      'INSERT INTO users (email, password, role) VALUES (?, ?, ?)',
      [email, password, role]
    );
    return { id: result.insertId, email, role };
  }

  static async createWithGoogle({ email, googleId, role = 'user' }) {
    const [result] = await pool.query(
      'INSERT INTO users (email, google_id, role) VALUES (?, ?, ?)',
      [email, googleId, role]
    );
    return { id: result.insertId, email, role };
  }

  static async findOrCreateGoogleUser(payload) {
    const googleId = payload.sub || payload.id;
    const email = payload.email || (payload.emails && payload.emails[0] && payload.emails[0].value);
    const name = payload.name || payload.displayName;

    if (!email) {
      throw new Error('Email field is missing in Google OAuth payload');
    }

    let user = await this.findByEmail(email);
    if (!user) {
      user = await this.createWithGoogle({ 
        email, 
        googleId,
      });

      // Create profile with name
      try {
        await pool.query(
          'INSERT INTO profiles (user_id, name) VALUES (?, ?)',
          [user.id, name || null]
        );
      } catch (profileErr) {
        console.error('[User.findOrCreateGoogleUser.createProfile]', profileErr);
      }
    }
    return user;
  }
}

module.exports = User;