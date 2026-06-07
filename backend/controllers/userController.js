const User = require('../models/User'); // Import the new User model
const bcrypt = require('bcryptjs'); // Needed for password hashing
const pool = require('../config/connection');

// @route   GET api/users
// @desc    Get all users
// @access  Public (for now, will be Private/Admin later)
exports.getUsers = async (req, res) => {
    try {
        const users = await User.findAll();
        res.json(users);
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
};

// @route   POST api/users
// @desc    Register a user
// @access  Public
exports.registerUser = async (req, res) => {
    const { name, email, password } = req.body;

    try {
        let user = await User.findByEmail(email);

        if (user) {
            return res.status(400).json({ msg: 'User already exists' });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Create user
        const newUser = await User.create(name, email, hashedPassword);

        // In a real scenario, you'd generate a JWT token here and send it back.
        // const payload = { user: { id: newUser.id } };
        // jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: 360000 }, (err, token) => {
        //     if (err) throw err;
        //     res.json({ token });
        // });

        res.status(201).json({ msg: 'User registered successfully', user: newUser });
    } catch (err) {
        console.error(err.message);
        res.status(500).send('Server Error');
    }
};

// Profile controller methods
exports.getProfile = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [rows] = await pool.query(
      `SELECT u.email, u.role, p.name, p.age, p.gender, p.fitness_goals, p.workout_types, p.availability
       FROM users u
       LEFT JOIN profiles p ON u.id = p.user_id
       WHERE u.id = ?`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const userData = rows[0];

    const [matchRows] = await pool.query(
      'SELECT COUNT(DISTINCT id) AS match_count FROM chat_threads WHERE (user_1 = ? OR user_2 = ?)',
      [userId, userId]
    );

    const [activeRows] = await pool.query(
      'SELECT COUNT(DISTINCT id) AS active_count FROM chat_threads WHERE (user_1 = ? OR user_2 = ?) AND expires_at > NOW()',
      [userId, userId]
    );

    res.json({
      userId,
      email: userData.email,
      role: userData.role,
      name: userData.name || '',
      age: userData.age || null,
      gender: userData.gender || null,
      fitnessGoals: userData.fitness_goals || '',
      workoutTypes: userData.workout_types || '',
      availability: userData.availability || '',
      stats: {
        matches: matchRows[0].match_count || 0,
        activeThreads: activeRows[0].active_count || 0
      }
    });
  } catch (error) {
    console.error('[UserController.getProfile]', error);
    res.status(500).json({ error: 'Failed to retrieve profile.' });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { name, age, gender, fitnessGoals, workoutTypes, availability } = req.body;

    const [existing] = await pool.query(
      'SELECT 1 FROM profiles WHERE user_id = ?',
      [userId]
    );

    if (existing.length > 0) {
      await pool.query(
        `UPDATE profiles 
         SET name = ?, age = ?, gender = ?, fitness_goals = ?, workout_types = ?, availability = ?
         WHERE user_id = ?`,
        [name || null, age || null, gender || null, fitnessGoals || null, workoutTypes || null, availability || null, userId]
      );
    } else {
      await pool.query(
        `INSERT INTO profiles (user_id, name, age, gender, fitness_goals, workout_types, availability)
         VALUES (?, ?, ?, ?, ?, ?, ?)`,
        [userId, name || null, age || null, gender || null, fitnessGoals || null, workoutTypes || null, availability || null]
      );
    }

    if (name) {
      await pool.query('UPDATE users SET name = ? WHERE id = ?', [name, userId]);
    }

    res.json({ message: 'Profile updated successfully.' });
  } catch (error) {
    console.error('[UserController.updateProfile]', error);
    res.status(500).json({ error: 'Failed to update profile.' });
  }
};
