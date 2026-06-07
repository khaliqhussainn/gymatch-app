const mysql = require('mysql2/promise');
require('dotenv').config();

async function runMigration() {
  const connection = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'gymatch_db',
  });

  try {
    console.log('Creating chat_threads table...');
    await connection.query(`
      CREATE TABLE IF NOT EXISTS chat_threads (
        id INT AUTO_INCREMENT PRIMARY KEY,
        gym_id INT NOT NULL,
        user_1 INT NOT NULL,
        user_2 INT NOT NULL,
        match_type VARCHAR(50) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        expires_at DATETIME NOT NULL,
        FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE,
        FOREIGN KEY (user_1) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (user_2) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    console.log('Creating chat_messages table...');
    await connection.query(`
      CREATE TABLE IF NOT EXISTS chat_messages (
        id INT AUTO_INCREMENT PRIMARY KEY,
        thread_id INT NOT NULL,
        sender_id INT NOT NULL,
        message_text TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (thread_id) REFERENCES chat_threads(id) ON DELETE CASCADE,
        FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);

    console.log('Chat tables migration completed successfully!');
  } catch (error) {
    console.error('Migration failed:', error);
  } finally {
    await connection.end();
  }
}

runMigration();
