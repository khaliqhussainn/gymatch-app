const User = require('../models/User'); // Import the new User model
const bcrypt = require('bcryptjs'); // Needed for password hashing
// const jwt = require('jsonwebtoken'); // Will be needed for JWT tokens

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

// You'd add more controller functions here for login, profile updates, etc.
