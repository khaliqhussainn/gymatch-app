const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { OAuth2Client } = require('google-auth-library');
const User = require('../models/User');
const dbConfig = require('../config/db');

const client = new OAuth2Client(dbConfig.googleClientId);

exports.register = async (req, res) => {
  try {
    const { email, password } = req.body;
    const existingUser = await User.findByEmail(email);
    
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await User.create({ email, password: hashedPassword });
    
    // Create profile with default values
    await pool.query(
      'INSERT INTO profiles (user_id) VALUES (?)',
      [user.id]
    );

    const token = jwt.sign(
      { userId: user.id, role: user.role },
      dbConfig.jwtSecret,
      { expiresIn: '7d' }
    );

    res.status(201).json({ token, userId: user.id, role: user.role });
  } catch (error) {
    res.status(500).json({ error: 'Registration failed' });
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