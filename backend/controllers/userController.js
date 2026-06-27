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
    console.log('[UserController.getProfile] Fetching profile for userId:', userId);

    const [rows] = await pool.query(
      `SELECT u.email, u.role, p.name, p.age, p.gender, p.fitness_goals, p.workout_types, p.availability, p.profile_image, p.about_me, go.gym_id
       FROM users u
       LEFT JOIN profiles p ON u.id = p.user_id
       LEFT JOIN gym_owners go ON u.id = go.user_id
       WHERE u.id = ?`,
      [userId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const userData = rows[0];
    console.log('[UserController.getProfile] User data:', {
      email: userData.email,
      role: userData.role,
      name: userData.name,
      gymId: userData.gym_id
    });

    const [matchRows] = await pool.query(
      'SELECT COUNT(DISTINCT id) AS match_count FROM chat_threads WHERE (user_1 = ? OR user_2 = ?)',
      [userId, userId]
    );

    const [activeRows] = await pool.query(
      'SELECT COUNT(DISTINCT id) AS active_count FROM chat_threads WHERE (user_1 = ? OR user_2 = ?) AND expires_at > NOW()',
      [userId, userId]
    );

    const response = {
      userId,
      email: userData.email,
      role: userData.role,
      name: userData.name || '',
      age: userData.age || null,
      gender: userData.gender || null,
      fitnessGoals: userData.fitness_goals || '',
      workoutTypes: userData.workout_types || '',
      availability: userData.availability || '',
      profileImage: userData.profile_image || null,
      aboutMe: userData.about_me || '',
      gymId: userData.gym_id || null,
      stats: {
        matches: matchRows[0].match_count || 0,
        activeThreads: activeRows[0].active_count || 0
      }
    };
    
    console.log('[UserController.getProfile] Response gymId:', response.gymId);
    res.json(response);
  } catch (error) {
    console.error('[UserController.getProfile]', error);
    res.status(500).json({ error: 'Failed to retrieve profile.' });
  }
};

exports.updateProfile = async (req, res) => {
  try {
    const userId = req.user.userId;
    const { name, age, gender, fitnessGoals, workoutTypes, availability, profileImage, aboutMe } = req.body;

    const [existing] = await pool.query(
      'SELECT 1 FROM profiles WHERE user_id = ?',
      [userId]
    );

    // Check if about_me column exists (graceful handling before migration runs)
    let hasAboutMe = true;
    try {
      await pool.query('SELECT about_me FROM profiles LIMIT 1');
    } catch (colErr) {
      hasAboutMe = false;
    }

    // Build dynamic update to only set profileImage when provided
    if (existing.length > 0) {
      if (hasAboutMe) {
        if (profileImage !== undefined) {
          await pool.query(
            `UPDATE profiles 
             SET name = ?, age = ?, gender = ?, fitness_goals = ?, workout_types = ?, availability = ?, profile_image = ?, about_me = ?
             WHERE user_id = ?`,
            [name || null, age || null, gender || null, fitnessGoals || null, workoutTypes || null, availability || null, profileImage || null, aboutMe || null, userId]
          );
        } else {
          await pool.query(
            `UPDATE profiles 
             SET name = ?, age = ?, gender = ?, fitness_goals = ?, workout_types = ?, availability = ?, about_me = ?
             WHERE user_id = ?`,
            [name || null, age || null, gender || null, fitnessGoals || null, workoutTypes || null, availability || null, aboutMe || null, userId]
          );
        }
      } else {
        // Fallback: update without about_me (column not yet migrated)
        if (profileImage !== undefined) {
          await pool.query(
            `UPDATE profiles 
             SET name = ?, age = ?, gender = ?, fitness_goals = ?, workout_types = ?, availability = ?, profile_image = ?
             WHERE user_id = ?`,
            [name || null, age || null, gender || null, fitnessGoals || null, workoutTypes || null, availability || null, profileImage || null, userId]
          );
        } else {
          await pool.query(
            `UPDATE profiles 
             SET name = ?, age = ?, gender = ?, fitness_goals = ?, workout_types = ?, availability = ?
             WHERE user_id = ?`,
            [name || null, age || null, gender || null, fitnessGoals || null, workoutTypes || null, availability || null, userId]
          );
        }
      }
    } else {
      if (hasAboutMe) {
        await pool.query(
          `INSERT INTO profiles (user_id, name, age, gender, fitness_goals, workout_types, availability, profile_image, about_me)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [userId, name || null, age || null, gender || null, fitnessGoals || null, workoutTypes || null, availability || null, profileImage || null, aboutMe || null]
        );
      } else {
        await pool.query(
          `INSERT INTO profiles (user_id, name, age, gender, fitness_goals, workout_types, availability, profile_image)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [userId, name || null, age || null, gender || null, fitnessGoals || null, workoutTypes || null, availability || null, profileImage || null]
        );
      }
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

// @route   GET api/users/search?q=
// @desc    Search users/partners by name or workout type
// @access  Public (optionally authenticated for match score context)
exports.searchPartners = async (req, res) => {
  try {
    const { q = '', lat, lng } = req.query;
    const query = q.toString().trim();

    if (!query || query.length < 2) {
      return res.json({ partners: [], count: 0 });
    }

    const like = `%${query}%`;

    const [rows] = await pool.query(
      `SELECT u.id AS userId, u.email,
              p.name, p.age, p.gender,
              p.fitness_goals   AS fitnessGoals,
              p.workout_types   AS workoutTypes,
              p.availability,
              p.profile_image   AS profileImage,
              p.about_me        AS aboutMe
       FROM users u
       LEFT JOIN profiles p ON u.id = p.user_id
       WHERE u.role != 'admin'
         AND (
               p.name          LIKE ?
            OR p.workout_types LIKE ?
            OR p.fitness_goals LIKE ?
            OR u.email         LIKE ?
         )
       ORDER BY
         CASE WHEN p.name LIKE ? THEN 0 ELSE 1 END,
         p.name ASC
       LIMIT 30`,
      [like, like, like, like, like]
    );

    const partners = rows.map(r => ({
      userId:       r.userId,
      name:         r.name || r.email.split('@')[0],
      email:        r.email,
      fitnessGoals: r.fitnessGoals || '',
      workoutTypes: r.workoutTypes || '',
      workoutType:  r.workoutTypes || '',   // alias used by PartnerProfileScreen
      availability: r.availability || '',
      profileImage: r.profileImage || null,
      aboutMe:      r.aboutMe || '',
      // gym context is unknown from a global search — caller provides fallback
      gymId:        null,
      gymName:      '',
    }));

    res.json({ partners, count: partners.length });
  } catch (error) {
    console.error('[UserController.searchPartners]', error);
    res.status(500).json({ error: 'Failed to search partners.' });
  }
};

// GET /api/users/:id/profile — public partner profile
exports.getPartnerProfile = async (req, res) => {
  try {
    const partnerId = parseInt(req.params.id, 10);
    if (isNaN(partnerId)) {
      return res.status(400).json({ error: 'Invalid user id.' });
    }

    const [rows] = await pool.query(
      `SELECT u.email, p.name, p.age, p.gender, p.fitness_goals, p.workout_types,
              p.availability, p.profile_image, p.about_me
       FROM users u
       LEFT JOIN profiles p ON u.id = p.user_id
       WHERE u.id = ?`,
      [partnerId]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }

    const u = rows[0];

    // Total matches
    const [matchRows] = await pool.query(
      'SELECT COUNT(DISTINCT id) AS mc FROM chat_threads WHERE user_1 = ? OR user_2 = ?',
      [partnerId, partnerId]
    );

    res.json({
      userId: partnerId,
      name: u.name || u.email.split('@')[0],
      email: u.email,
      age: u.age || null,
      gender: u.gender || null,
      fitnessGoals: u.fitness_goals || '',
      workoutTypes: u.workout_types || '',
      availability: u.availability || '',
      profileImage: u.profile_image || null,
      aboutMe: u.about_me || '',
      totalMatches: matchRows[0].mc || 0,
    });
  } catch (error) {
    console.error('[UserController.getPartnerProfile]', error);
    res.status(500).json({ error: 'Failed to load partner profile.' });
  }
};

exports.deleteAccount = async (req, res) => {
  try {
    const userId = req.user.userId;

    const [rows] = await pool.query('SELECT id, role FROM users WHERE id = ?', [userId]);
    if (rows.length === 0) {
      return res.status(404).json({ error: 'User not found.' });
    }

    if (rows[0].role === 'admin') {
      return res.status(403).json({ error: 'Admin accounts cannot be deleted via the app.' });
    }

    await pool.query('DELETE FROM users WHERE id = ?', [userId]);

    res.json({ message: 'Account deleted successfully.' });
  } catch (error) {
    console.error('[UserController.deleteAccount]', error);
    res.status(500).json({ error: 'Failed to delete account. Please try again.' });
  }
};

// GET /api/users/nearby — find nearby users based on location
exports.getNearbyPartners = async (req, res) => {
  try {
    const { lat, lng, radius = 15 } = req.query;
    const currentUserId = req.user ? req.user.userId : null;

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Location coordinates (lat, lng) are required.' });
    }

    const parsedLat = parseFloat(lat);
    const parsedLng = parseFloat(lng);
    const radiusKm = parseFloat(radius) || 15;

    if (isNaN(parsedLat) || isNaN(parsedLng)) {
      return res.status(400).json({ error: 'Invalid coordinates provided.' });
    }

    // Find users within the radius (using users table instead of active_partners)
    const [partners] = await pool.query(
      `SELECT u.id AS userId, u.email,
              p.name, p.age, p.gender,
              p.fitness_goals   AS fitnessGoals,
              p.workout_types   AS workoutTypes,
              p.availability,
              p.profile_image   AS profileImage,
              p.about_me        AS aboutMe
       FROM users u
       LEFT JOIN profiles p ON u.id = p.user_id
       WHERE u.role != 'admin'
         AND (? IS NULL OR u.id != ?)
       ORDER BY p.name ASC
       LIMIT 50`,
      [currentUserId, currentUserId]
    );

    const enrichedPartners = partners.map(p => ({
      userId: p.userId,
      name: p.name || p.email.split('@')[0],
      email: p.email,
      fitnessGoals: p.fitnessGoals || '',
      workoutTypes: p.workoutTypes || '',
      workoutType: p.workoutTypes || '',
      availability: p.availability || '',
      profileImage: p.profileImage || null,
      aboutMe: p.aboutMe || '',
      gymId: null,
      gymName: '',
    }));

    res.json({ partners: enrichedPartners, count: enrichedPartners.length });
  } catch (error) {
    console.error('[UserController.getNearbyPartners]', error);
    res.status(500).json({ error: 'Failed to fetch nearby partners.' });
  }
};
