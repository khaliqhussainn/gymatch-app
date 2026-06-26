const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const dbConfig = require('../config/db');

// Hardcoded admin credentials (for development/testing only)
const ADMIN_CREDENTIALS = {
  email: 'admin@gymatch.com',
  password: '123456'
};

/**
 * Admin Login Controller
 * Separate from mobile app login to avoid affecting mobile APIs
 * Uses hardcoded credentials as requested
 */
exports.adminLogin = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    // Check against hardcoded credentials
    if (email.trim().toLowerCase() !== ADMIN_CREDENTIALS.email.toLowerCase()) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    if (password !== ADMIN_CREDENTIALS.password) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    // Generate JWT token with static admin user ID
    const token = jwt.sign(
      { userId: 'admin-001', email: ADMIN_CREDENTIALS.email, role: 'admin' },
      dbConfig.jwtSecret,
      { expiresIn: '24h' } // Admin tokens expire in 24 hours
    );

    res.json({
      token,
      user: {
        id: 'admin-001',
        email: ADMIN_CREDENTIALS.email,
        role: 'admin'
      }
    });
  } catch (error) {
    console.error('Admin login error:', error);
    res.status(500).json({ error: 'Login failed. Please try again.' });
  }
};

/**
 * Verify Admin Token
 * Used to validate token on frontend
 */
exports.verifyToken = async (req, res) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ error: 'Token is required' });
    }

    const decoded = jwt.verify(token, dbConfig.jwtSecret);

    // Verify token is for hardcoded admin
    if (decoded.userId !== 'admin-001' || decoded.role !== 'admin') {
      return res.status(403).json({ error: 'Access denied. Admin access only.' });
    }

    res.json({
      valid: true,
      user: {
        id: decoded.userId,
        email: decoded.email,
        role: decoded.role
      }
    });
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ error: 'Invalid token' });
    }
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ error: 'Token expired' });
    }
    console.error('Token verification error:', error);
    res.status(500).json({ error: 'Token verification failed' });
  }
};
