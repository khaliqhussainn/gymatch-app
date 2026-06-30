// Force load from the exact .env path on the live server
const path = require('path');
const envPath = path.join(__dirname, '..', '.env');
require('dotenv').config({ path: envPath, override: true });

const appleClientIds = (
  process.env.APPLE_CLIENT_IDS ||
  process.env.APPLE_CLIENT_ID ||
  'com.gymatch.app,com.oti.gymmatch,com.otisjones.GYMatch,com.jebcoolkids.gymmatch,com.otisjones.GYMatchProfile,com.otisjones.GYMatchTest'
)
  .split(',')
  .map((clientId) => clientId.trim())
  .filter(Boolean);

module.exports = {
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASSWORD || '',
  database: process.env.DB_NAME || 'gymatch_db',
  port: process.env.DB_PORT || 3306,
  jwtSecret: process.env.JWT_SECRET || 'your_strong_secret_here',
  googleClientId: process.env.GOOGLE_CLIENT_ID,
  googleClientSecret: process.env.GOOGLE_CLIENT_SECRET,
  appleClientId: appleClientIds[0],
  appleClientIds,
  googleMapsApiKey: process.env.GOOGLE_MAPS_API_KEY || 'AIzaSyAnat7KjNftq-ctwytsR317xVrs7BQ4OzA',
};
