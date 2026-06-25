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

  static async createWithApple({ email, appleId, role = 'user' }) {
    const [result] = await pool.query(
      'INSERT INTO users (email, apple_id, role) VALUES (?, ?, ?)',
      [email, appleId, role]
    );
    return { id: result.insertId, email, role };
  }

  static async findByAppleId(appleId) {
    const [rows] = await pool.query('SELECT * FROM users WHERE apple_id = ?', [appleId]);
    return rows[0];
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

  static async findOrCreateAppleUser(payload, displayName) {
    const appleId = payload.sub;
    if (!appleId) {
      throw new Error('Apple user ID is missing in token payload');
    }

    let user = await this.findByAppleId(appleId);
    if (user) {
      if (displayName && displayName.trim()) {
        await this.updateMissingProfileName(user.id, displayName.trim());
      }
      return user;
    }

    const email = payload.email ? payload.email.toLowerCase() : null;
    if (email) {
      user = await this.findByEmail(email);
      if (user) {
        await pool.query('UPDATE users SET apple_id = ? WHERE id = ?', [appleId, user.id]);
        user.apple_id = appleId;
        if (displayName && displayName.trim()) {
          await this.updateMissingProfileName(user.id, displayName.trim());
        }
        return user;
      }
    }

    const fallbackEmail = email || `apple_${appleId}@privaterelay.gymatch.local`;
    user = await this.createWithApple({ email: fallbackEmail, appleId });

    try {
      await pool.query(
        'INSERT INTO profiles (user_id, name) VALUES (?, ?)',
        [user.id, displayName || null]
      );
    } catch (profileErr) {
      console.error('[User.findOrCreateAppleUser.createProfile]', profileErr);
    }

    return user;
  }

  static async updateMissingProfileName(userId, displayName) {
    const [rows] = await pool.query(
      'SELECT name FROM profiles WHERE user_id = ?',
      [userId]
    );

    if (rows.length === 0) {
      await pool.query(
        'INSERT INTO profiles (user_id, name) VALUES (?, ?)',
        [userId, displayName]
      );
      return;
    }

    if (!rows[0].name) {
      await pool.query(
        'UPDATE profiles SET name = ? WHERE user_id = ?',
        [displayName, userId]
      );
    }
  }
}

module.exports = User;
