const { getPool } = require('../config/db');

const User = {
    async findAll() {
        const pool = getPool();
        const [rows] = await pool.query('SELECT id, name, email, date FROM users');
        return rows;
    },

    async findByEmail(email) {
        const pool = getPool();
        const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
        return rows[0];
    },

    async create(name, email, password) {
        const pool = getPool();
        const [result] = await pool.query(
            'INSERT INTO users (name, email, password) VALUES (?, ?, ?)',
            [name, email, password]
        );
        return { id: result.insertId, name, email };
    }
    // Add more user-related database operations here (e.g., findById, update, delete)
};

module.exports = User;
