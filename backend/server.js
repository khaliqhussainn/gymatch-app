require('dotenv').config();
const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/authRoutes');
const gymRoutes = require('./routes/gymRoutes');
const userRoutes = require('./routes/userRoutes');
const chatRoutes = require('./routes/chatRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const migrationController = require('./controllers/migrationController');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/gyms', gymRoutes);
app.use('/api/users', userRoutes);
app.use('/api/chats', chatRoutes);
app.use('/api/notifications', notificationRoutes);

// ── Migration endpoint (protected by secret key) ──────────────────────────
// Usage: GET https://gymatch.syedmisbahali.com/migration?secret=YOUR_SECRET
app.get('/migration', migrationController.runMigrations);

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