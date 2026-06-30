const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { OAuth2Client } = require('google-auth-library');
const appleSignin = require('apple-signin-auth');
const path = require('path');
const fs = require('fs');
const User = require('../models/User');
const GymOwner = require('../models/GymOwner');
const dbConfig = require('../config/db');
const pool = require('../config/connection');
const emailService = require('../services/emailService');
const LocationService = require('../services/locationService');

const client = new OAuth2Client(dbConfig.googleClientId);

/**
 * POST /api/auth/parse-location
 * Parse Google Maps URL to extract coordinates
 */
exports.parseLocation = async (req, res) => {
  try {
    const { location } = req.body;
    
    if (!location) {
      return res.status(400).json({ error: 'Location URL is required' });
    }

    const locationData = await LocationService.extractLocation(location);
    
    if (!locationData) {
      return res.status(400).json({ 
        error: LocationService.getErrorMessage(location) 
      });
    }

    res.json({
      latitude: locationData.latitude,
      longitude: locationData.longitude,
    });
  } catch (error) {
    console.error('[AuthController.parseLocation]', error);
    res.status(500).json({ error: 'Failed to parse location URL' });
  }
};

exports.register = async (req, res) => {
  try {
    const { email, password, name } = req.body;
    const existingUser = await User.findByEmail(email);
    
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await User.create({ email, password: hashedPassword });
    
    await pool.query(
      'INSERT INTO profiles (user_id, name) VALUES (?, ?)',
      [user.id, name || null]
    );

    try {
      await pool.query(
        `INSERT INTO notifications (user_id, title, body, type, gym_id) VALUES (?, ?, ?, ?, ?)`,
        [user.id, 'Welcome to GYMatch!', 'Start searching for gyms to match with workout partners near you.', 'profile', null]
      );
      await pool.query(
        `INSERT INTO notifications (user_id, title, body, type, gym_id) VALUES (?, ?, ?, ?, ?)`,
        [user.id, 'Workout Streak', "You've matched with partners 5 days in a row! Keep it up.", 'profile', null]
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

exports.registerGymOwner = async (req, res) => {
  try {
    const { 
      email, 
      password, 
      name,
      gymName,
      locationName,
      location,
      category,
      contactPhone
    } = req.body;

    // Check if email already exists
    const existingUser = await User.findByEmail(email);
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    // Extract and validate location
    const locationData = await LocationService.extractLocation(location);
    if (!locationData) {
      return res.status(400).json({ 
        error: 'Invalid Google Maps URL. Please use the full Google Maps URL (not the short link). Open the location in Google Maps, copy the full URL from the address bar, and paste it here.' 
      });
    }

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create gym owner user
    const user = await User.createGymOwner({ 
      email, 
      password: hashedPassword, 
      name 
    });

    // Create profile record for gym owner with name
    await pool.query(
      'INSERT INTO profiles (user_id, name) VALUES (?, ?)',
      [user.id, name || null]
    );

    // Create gym record
    const [gymResult] = await pool.query(
      `INSERT INTO gyms (name, location_name, latitude, longitude, 
                        category, contact_phone, open_hours, owner_id, verification_status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'verified')`,
      [
        gymName,
        locationName,
        locationData.latitude,
        locationData.longitude,
        category || 'GYM',
        contactPhone || null,
        '6:00 am - 11:00 pm',
        user.id
      ]
    );

    const gymId = gymResult.insertId;
    console.log('[AuthController.registerGymOwner] Gym created with ID:', gymId);

    // Process and save images if provided
    if (req.files && req.files.length > 0) {
      for (let i = 0; i < req.files.length; i++) {
        const file = req.files[i];
        // For now, we'll store base64 directly. In production, upload to S3/Cloudinary
        const base64Image = `data:${file.mimetype};base64,${file.buffer.toString('base64')}`;
        await pool.query(
          'INSERT INTO gym_images (gym_id, image_url, sort_order) VALUES (?, ?, ?)',
          [gymId, base64Image, i]
        );
      }
      console.log('[AuthController.registerGymOwner] Saved', req.files.length, 'images');
    }

    // Link gym owner to gym
    try {
      await GymOwner.create({ userId: user.id, gymId });
      console.log('[AuthController.registerGymOwner] Gym owner linked successfully');
    } catch (gymOwnerErr) {
      console.error('[AuthController.registerGymOwner] Failed to link gym owner:', gymOwnerErr);
      throw gymOwnerErr;
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, role: user.role, gymId },
      dbConfig.jwtSecret,
      { expiresIn: '7d' }
    );

    res.status(201).json({ 
      token, 
      userId: user.id, 
      role: user.role,
      gymId,
      message: 'Gym registered successfully' 
    });
  } catch (error) {
    console.error('Gym owner registration error:', error);
    res.status(500).json({ error: 'Gym registration failed', details: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password are required.' });
    }

    const user = await User.findByEmail(email.trim().toLowerCase());

    // Use HTTP 400 (not 401) so the old APK's validateStatus (< 500) treats it
    // as an error and reads data['error'] to show the message in the UI.
    if (!user) {
      return res.status(400).json({
        error: 'No account found with this email. Please create an account first.'
      });
    }

    if (!user.password) {
      const provider = user.apple_id
        ? 'Apple'
        : user.google_id
          ? 'Google'
          : 'social';
      return res.status(400).json({
        error: `This account uses ${provider} Sign-In. Please sign in with ${provider}.`
      });
    }

    const passwordMatch = await bcrypt.compare(password, user.password);
    if (!passwordMatch) {
      return res.status(400).json({
        error: 'Incorrect password. Please try again or use Forgot Password.'
      });
    }

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      dbConfig.jwtSecret,
      { expiresIn: '7d' }
    );

    res.json({ token, userId: user.id, role: user.role });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Login failed. Please try again.' });
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
    res.status(400).json({ error: 'Google authentication failed' });
  }
};

exports.appleLogin = async (req, res) => {
  try {
    const { token, name } = req.body;
    const tokenPayload = token ? jwt.decode(token) : null;

    if (!token) {
      return res.status(400).json({ error: 'Apple identity token is required.' });
    }

    const appleAudiences = dbConfig.appleClientIds && dbConfig.appleClientIds.length
      ? dbConfig.appleClientIds
      : [dbConfig.appleClientId].filter(Boolean);

    if (appleAudiences.length === 0) {
      return res.status(500).json({ error: 'Apple Sign-In is not configured on the server.' });
    }

    const payload = await appleSignin.verifyIdToken(token, {
      audience: appleAudiences.length === 1 ? appleAudiences[0] : appleAudiences,
      ignoreExpiration: false,
    });

    const user = await User.findOrCreateAppleUser(payload, name);

    const authToken = jwt.sign(
      { userId: user.id, role: user.role },
      dbConfig.jwtSecret,
      { expiresIn: '7d' }
    );

    res.json({ token: authToken, userId: user.id, role: user.role });
  } catch (error) {
    console.error('[AuthController.appleLogin]', error);
    if (error && error.message && error.message.toLowerCase().includes('audience')) {
      const tokenPayload = req.body && req.body.token ? jwt.decode(req.body.token) : null;
      const appleAudiences = dbConfig.appleClientIds && dbConfig.appleClientIds.length
        ? dbConfig.appleClientIds
        : [dbConfig.appleClientId].filter(Boolean);
      const receivedAud = tokenPayload && tokenPayload.aud ? tokenPayload.aud : 'unknown';
      console.error('[AuthController.appleLogin.audienceMismatch]', {
        tokenAudience: receivedAud,
        configuredAudiences: appleAudiences,
      });
      return res.status(400).json({
        error: `Apple Sign-In is not configured for this app bundle (${receivedAud}). Please contact support.`
      });
    }
    res.status(400).json({
      error: 'Apple authentication failed. Please try again or use another sign-in option.'
    });
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
      return res.json({ message: 'If an account exists with this email, a password reset link has been sent.' });
    }

    const resetToken = jwt.sign(
      { userId: user.id, type: 'password_reset' },
      dbConfig.jwtSecret,
      { expiresIn: '1h' }
    );

    const emailSent = await emailService.sendPasswordResetEmail(email, resetToken);

    if (emailSent) {
      res.json({
        message: 'If an account exists with this email, a password reset link has been sent.',
        ...(process.env.NODE_ENV === 'development' && { resetToken })
      });
    } else {
      console.log('Email service not configured. Reset token:', resetToken);
      res.json({
        message: 'Email service not configured. Use the token below:',
        resetToken
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

    const decoded = jwt.verify(token, dbConfig.jwtSecret);
    if (decoded.type !== 'password_reset') {
      return res.status(400).json({ error: 'Invalid reset token' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

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
