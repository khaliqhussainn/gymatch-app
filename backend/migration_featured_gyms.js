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
    // 1. Add is_featured column if it doesn't exist
    console.log('Checking is_featured column on gyms table...');
    const [columns] = await connection.query(`
      SELECT COLUMN_NAME 
      FROM INFORMATION_SCHEMA.COLUMNS 
      WHERE TABLE_SCHEMA = ? AND TABLE_NAME = 'gyms' AND COLUMN_NAME = 'is_featured'
    `, [process.env.DB_NAME || 'gymatch_db']);

    if (columns.length === 0) {
      console.log('Adding is_featured column...');
      await connection.query(`
        ALTER TABLE gyms ADD COLUMN is_featured BOOLEAN DEFAULT FALSE AFTER category
      `);
      console.log('✓ is_featured column added.');
    } else {
      console.log('✓ is_featured column already exists, skipping.');
    }

    // 2. Mark some gyms as featured
    console.log('Marking featured gyms...');
    await connection.query(`
      UPDATE gyms SET is_featured = TRUE WHERE id IN (1, 2, 4)
    `);
    console.log('✓ Featured gyms updated (IDs: 1, 2, 4).');

    // 3. Verify the result
    const [rows] = await connection.query(`
      SELECT id, name, is_featured FROM gyms ORDER BY id
    `);
    console.log('\nCurrent gyms:');
    rows.forEach(row => {
      console.log(`  [${row.id}] ${row.name} — featured: ${row.is_featured ? 'YES ⭐' : 'no'}`);
    });

    console.log('\n✅ Featured gyms migration completed successfully!');
  } catch (error) {
    console.error('❌ Migration failed:', error.message);
    process.exit(1);
  } finally {
    await connection.end();
  }
}

runMigration();
