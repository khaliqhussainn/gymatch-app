require('dotenv').config();

module.exports = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'gymatch_db',
  port: process.env.DB_PORT || 3306,
  jwtSecret: process.env.JWT_SECRET || 'your_strong_secret_here',
  googleClientId: process.env.GOOGLE_CLIENT_ID,
  googleClientSecret: process.env.GOOGLE_CLIENT_SECRET
};