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

  static async findOrCreateGoogleUser(profile) {
    const { id, emails, displayName } = profile;
    const email = emails[0].value;
    
    let user = await this.findByEmail(email);
    if (!user) {
      user = await this.createWithGoogle({ 
        email, 
        googleId: id,
        name: displayName
      });
    }
    return user;
  }
}

module.exports = User;