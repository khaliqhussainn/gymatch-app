require('dotenv').config();
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const adminAuthRoutes = require('./routes/adminAuthRoutes');
const adminCategoryRoutes = require('./routes/adminCategoryRoutes');
const adminLocationRoutes = require('./routes/adminLocationRoutes');
const adminUserRoutes = require('./routes/adminUserRoutes');
const adminFeatureRequestRoutes = require('./routes/adminFeatureRequestRoutes');
const adminGymRoutes = require('./routes/adminGymRoutes');
const adminDashboardRoutes = require('./routes/adminDashboardRoutes');
const gymRoutes = require('./routes/gymRoutes');
const categoryRoutes = require('./routes/categoryRoutes');
const locationRoutes = require('./routes/locationRoutes');
const userRoutes = require('./routes/userRoutes');
const chatRoutes = require('./routes/chatRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const migrationController = require('./controllers/migrationController');
const seederController    = require('./controllers/seederController');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use('/uploads', express.static('uploads'));

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/admin/auth', adminAuthRoutes);
app.use('/api/admin/categories', adminCategoryRoutes);
app.use('/api/admin/locations', adminLocationRoutes);
app.use('/api/admin/users', adminUserRoutes);
app.use('/api/feature-requests', adminFeatureRequestRoutes);
app.use('/api/admin/feature-requests', adminFeatureRequestRoutes);
app.use('/api/admin/gyms', adminGymRoutes);
app.use('/api/admin/dashboard', adminDashboardRoutes);
app.use('/api/gyms', gymRoutes);
app.use('/api/categories', categoryRoutes);
app.use('/api/locations', locationRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/notifications', notificationRoutes);

// ── Login test endpoint ────────────────────────────────────────────────────
// GET /auth-check?email=test@test.com
app.get('/auth-check', async (req, res) => {
  const { email } = req.query;
  if (!email) return res.status(400).json({ error: 'email param required' });
  const pool = require('./config/connection');
  try {
    const [rows] = await pool.query(
      `SELECT id, email,
              password IS NOT NULL as has_password,
              google_id IS NOT NULL as is_google,
              apple_id IS NOT NULL as is_apple
       FROM users WHERE email = ?`,
      [email.toLowerCase()]
    );
    if (!rows.length) return res.json({ exists: false, message: 'No account with this email' });
    res.json({
      exists: true,
      has_password: !!rows[0].has_password,
      is_google: !!rows[0].is_google,
      is_apple: !!rows[0].is_apple
    });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ── Login endpoint test (POST test via GET for quick browser check) ─────────
// GET /login-check?email=x&password=y
app.get('/login-check', async (req, res) => {
  const { email, password } = req.query;
  if (!email || !password) return res.status(400).json({ error: 'email and password required' });
  
  const User = require('./models/User');
  const bcrypt = require('bcryptjs');
  
  try {
    const user = await User.findByEmail(email.toLowerCase());
    if (!user) return res.json({ result: 'FAIL', reason: 'User not found' });
    if (!user.password) {
      const provider = user.apple_id ? 'Apple' : user.google_id ? 'Google' : 'social';
      return res.json({ result: 'FAIL', reason: `${provider}-only account` });
    }
    const match = await bcrypt.compare(password, user.password);
    res.json({ result: match ? 'OK' : 'FAIL', reason: match ? 'Password correct' : 'Wrong password' });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});
// Usage: GET https://gymatch.syedmisbahali.com/migration?secret=YOUR_SECRET
app.get('/migration', migrationController.runMigrations);

// ── Partner seeder endpoint ────────────────────────────────────────────────
// GET /api/seed-partners?secret=gymatch_migrate_2024_secure_key
// Idempotent — safe to call multiple times (skips existing emails).
// Returns JSON with created/skipped/error counts.
app.get('/api/seed-partners', seederController.runSeeder);

// ── DB diagnostic endpoint ─────────────────────────────────────────────────
app.get('/db-check', async (req, res) => {
  // Force re-read .env from disk right now
  const fs = require('fs');
  const path = require('path');

  const envPath = path.join(__dirname, '.env');
  let envFileContent = 'NOT FOUND';
  let envExists = false;

  try {
    envExists = fs.existsSync(envPath);
    if (envExists) {
      envFileContent = fs.readFileSync(envPath, 'utf8')
        .split('\n')
        .map(line => {
          if (line.match(/PASSWORD|SECRET|PASS/i)) {
            const [key] = line.split('=');
            return `${key}=***`;
          }
          return line;
        })
        .join('\n');
    }
  } catch (e) {
    envFileContent = 'Read error: ' + e.message;
  }

  // Try DB connection with current process.env
  let dbResult = { connected: false, error: null };
  try {
    const mysql = require('mysql2/promise');
    const testConn = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      database: process.env.DB_NAME,
    });
    await testConn.query('SELECT 1');
    await testConn.end();
    dbResult.connected = true;
  } catch (err) {
    dbResult.error = err.message;
  }

  res.json({
    env_path: envPath,
    env_file_exists: envExists,
    env_file_content: envFileContent,
    process_env: {
      DB_HOST: process.env.DB_HOST,
      DB_USER: process.env.DB_USER,
      DB_NAME: process.env.DB_NAME,
      DB_PASSWORD_LENGTH: process.env.DB_PASSWORD ? process.env.DB_PASSWORD.length : 0,
    },
    db_connection: dbResult,
  });
});

// Health check
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'GYMatch API Running', version: '1.0.0' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error('[Unhandled Error]', err);
  res.status(500).json({ error: 'An unexpected server error occurred.' });
});

// Start server
app.listen(PORT, () => {
  console.log(`GYMatch API running on port ${PORT}`);
});

// ── Geocoding proxy (avoids CORS issues from mobile/web clients) ────────────
// GET /geocode?q=Washington
app.get('/geocode', async (req, res) => {
  const { q } = req.query;
  if (!q) return res.status(400).json({ error: 'Query param q is required.' });

  const https = require('https');
  const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(q)}&format=json&limit=1`;

  const options = {
    headers: {
      'User-Agent': 'GYMatchApp/1.0 (contact@gymatch.com)',
      'Accept': 'application/json',
    }
  };

  https.get(url, options, (apiRes) => {
    let data = '';
    apiRes.on('data', chunk => data += chunk);
    apiRes.on('end', () => {
      try {
        const results = JSON.parse(data);
        if (!results.length) return res.json({ found: false });
        const { lat, lon } = results[0];
        res.json({ found: true, lat: parseFloat(lat), lng: parseFloat(lon) });
      } catch (e) {
        res.status(500).json({ error: 'Geocoding parse failed.' });
      }
    });
  }).on('error', (e) => {
    res.status(500).json({ error: 'Geocoding request failed: ' + e.message });
  });
});
