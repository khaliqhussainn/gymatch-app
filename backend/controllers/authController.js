const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const dbConfig = require('../config/db');
const pool = require('../config/connection');
const emailService = require('../services/emailService');

const client = new OAuth2Client(dbConfig.googleClientId);

exports.register = async (req, res) => {
  try {
    const { email, password, name } = req.body;
    const existingUser = await User.findByEmail(email);
    
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await User.create({ email, password: hashedPassword });
    
    // Create profile with name if provided
    await pool.query(
      'INSERT INTO profiles (user_id, name) VALUES (?, ?)',
      [user.id, name || null]
    );

    try {
      // Welcome Notification
      await pool.query(
        `INSERT INTO notifications (user_id, title, body, type, gym_id)
         VALUES (?, ?, ?, ?, ?)`,
        [
          user.id,
          'Welcome to GYMatch!',
          'Start searching for gyms to match with workout partners near you.',
          'profile',
          null
        ]
      );

      // Workout Streak Notification
      await pool.query(
        `INSERT INTO notifications (user_id, title, body, type, gym_id)
         VALUES (?, ?, ?, ?, ?)`,
        [
          user.id,
          'Workout Streak',
          'You\'ve matched with partners 5 days in a row! Keep it up.',
          'profile',
          null
        ]
      );
    } catch (seedErr) {
      console.error('[AuthController.register.seedNotifications]', seedErr);
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      dbConfig.jwtSecret,
      { expiresIn: '7d' }
    );

    res.status(201).json({ token, userId: user.id, role: user.role });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Registration failed', details: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findByEmail(email);
    
    if (!user || !(await bcrypt.compare(password, user.password))) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      dbConfig.jwtSecret,
      { expiresIn: '7d' }
    );

    res.json({ token, userId: user.id, role: user.role });
  } catch (error) {
    res.status(500).json({ error: 'Login failed' });
  }
};

exports.googleLogin = async (req, res) => {
  try {
    const { token } = req.body;
    const ticket = await client.verifyIdToken({
      idToken: token,
      audience: dbConfig.googleClientId
    });

    const payload = ticket.getPayload();
    const user = await User.findOrCreateGoogleUser(payload);

    const authToken = jwt.sign(
      { userId: user.id, role: user.role },
      dbConfig.jwtSecret,
      { expiresIn: '7d' }
    );

    res.json({ token: authToken, userId: user.id, role: user.role });
  } catch (error) {
    res.status(401).json({ error: 'Google authentication failed' });
  }
};

exports.guestToken = async (req, res) => {
  try {
    const token = jwt.sign(
      { role: 'guest' },
      dbConfig.jwtSecret,
      { expiresIn: '1d' }
    );
    res.json({ token, role: 'guest' });
  } catch (error) {
    res.status(500).json({ error: 'Guest token generation failed' });
  }
};

exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    const user = await User.findByEmail(email);

    if (!user) {
      // Don't reveal if email exists or not for security
      return res.json({ message: 'If an account exists with this email, a password reset link has been sent.' });
    }

    // Generate a reset token (valid for 1 hour)
    const resetToken = jwt.sign(
      { userId: user.id, type: 'password_reset' },
      dbConfig.jwtSecret,
      { expiresIn: '1h' }
    );

    // Try to send email
    const emailSent = await emailService.sendPasswordResetEmail(email, resetToken);

    if (emailSent) {
      res.json({
        message: 'If an account exists with this email, a password reset link has been sent.',
        // In development, also return token for testing
        ...(process.env.NODE_ENV === 'development' && { resetToken })
      });
    } else {
      // Email service not configured, return token for manual testing
      console.log('Email service not configured. Reset token:', resetToken);
      res.json({
        message: 'Email service not configured. Use the token below:',
        resetToken // For testing when email is not configured
      });
    }
  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ error: 'Failed to process password reset request' });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    // Verify the reset token
    const decoded = jwt.verify(token, dbConfig.jwtSecret);
    if (decoded.type !== 'password_reset') {
      return res.status(400).json({ error: 'Invalid reset token' });
    }

    // Hash the new password
    const hashedPassword = await bcrypt.hash(newPassword, 10);

    // Update the user's password
    await pool.query(
      'UPDATE users SET password = ? WHERE id = ?',
      [hashedPassword, decoded.userId]
    );

    res.json({ message: 'Password reset successful' });
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(400).json({ error: 'Invalid or expired reset token' });
    }
    console.error('Reset password error:', error);
    res.status(500).json({ error: 'Failed to reset password' });
  }
};