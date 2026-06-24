// Force load from the exact .env path on the live server
const path = require('path');
const envPath = path.join(__dirname, '..', '.env');
require('dotenv').config({ path: envPath, override: true });

module.exports = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'gymatch_db',
  port: process.env.DB_PORT || 3306,
  jwtSecret: process.env.JWT_SECRET || 'your_strong_secret_here',
  googleClientId: process.env.GOOGLE_CLIENT_ID,
  googleClientSecret: process.env.GOOGLE_CLIENT_SECRET,
  appleClientId: process.env.APPLE_CLIENT_ID || 'com.gymatch.app',
  googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY || 'AIzaSyAnat7KjNftq-ctwytsR317xVrs7BQ4OzA',
};