const pool = require('./config/connection');

async function runMigration() {
  try {
    console.log('Running migration to fix gym_images column...');
    await pool.query('ALTER TABLE gym_images MODIFY COLUMN image_url LONGTEXT NOT NULL');
    console.log('✓ Migration completed successfully!');
    console.log('image_url column is now LONGTEXT instead of VARCHAR(500)');
    process.exit(0);
  } catch (error) {
    console.error('✗ Migration failed:', error.message);
    process.exit(1);
  }
}

runMigration();
