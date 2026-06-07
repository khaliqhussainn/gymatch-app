const mysql = require('mysql2/promise');
require('dotenv').config();

async function testConnection() {
  console.log('Connecting to database...');
  console.log('Host:', process.env.DB_HOST || 'localhost');
  console.log('User:', process.env.DB_USER || 'root');
  console.log('Database:', process.env.DB_NAME || 'gymatch_db');

  try {
    const connection = await mysql.createConnection({
      host: process.env.DB_HOST || 'localhost',
      user: process.env.DB_USER || 'root',
      password: process.env.DB_PASSWORD || '',
      database: process.env.DB_NAME || 'gymatch_db',
    });

    console.log('Successfully connected to MySQL database!');
    const [rows] = await connection.query('SHOW TABLES');
    console.log('Tables in database:', rows.map(r => Object.values(r)[0]));
    await connection.end();
  } catch (error) {
    console.error('Database connection failed:', error.message);
  }
}

testConnection();
