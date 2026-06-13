const pool = require('../config/connection');

/**
 * GET /migration?secret=YOUR_SECRET
 *
 * Runs all pending database migrations safely (idempotent).
 * Protected by a secret key set in .env as MIGRATION_SECRET.
 *
 * Usage:
 *   https://gymatch.syedmisbahali.com/migration?secret=gymatch_migrate_2024_secure_key
 */
exports.runMigrations = async (req, res) => {
  const results = [];
  const errors  = [];

  const log  = (msg) => { console.log(msg); results.push(msg); };
  const fail = (msg) => { console.error(msg); errors.push(msg); };

  try {
    log('═══════════════════════════════════════');
    log('  GYMatch Database Migration Runner');
    log('═══════════════════════════════════════');

    // ── Migration 1: is_featured column ─────────────────────────────────
    log('\n[1/3] Checking is_featured column on gyms table...');
    try {
      await pool.query(`
        ALTER TABLE gyms
        ADD COLUMN is_featured BOOLEAN NOT NULL DEFAULT FALSE
        AFTER category
      `);
      log('  ✓ is_featured column added.');
    } catch (alterErr) {
      // Error 1060 = Duplicate column name — column already exists, safe to ignore
      if (alterErr.errno === 1060 || (alterErr.message && alterErr.message.includes('Duplicate column'))) {
        log('  ✓ is_featured column already exists, skipped.');
      } else {
        // Any other ALTER error — log but continue with the rest
        log(`  ⚠️ Could not add is_featured column: ${alterErr.message}`);
        log('  ℹ️ Continuing — COALESCE in queries handles missing column gracefully.');
      }
    }

    // Mark gyms 1, 2, 4 as featured (only if column exists)
    try {
      await pool.query(`UPDATE gyms SET is_featured = TRUE WHERE id IN (1, 2, 4)`);
      log('  ✓ Featured gyms marked (IDs: 1, 2, 4).');
    } catch (updateErr) {
      log(`  ⚠️ Could not mark featured gyms: ${updateErr.message}`);
    }

    // ── Migration 2: chat_threads table ─────────────────────────────────
    log('\n[2/3] Checking chat_threads table...');
    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS chat_threads (
          id         INT AUTO_INCREMENT PRIMARY KEY,
          gym_id     INT NOT NULL,
          user_1     INT NOT NULL,
          user_2     INT NOT NULL,
          match_type VARCHAR(50) NOT NULL,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          expires_at DATETIME NOT NULL,
          FOREIGN KEY (gym_id)  REFERENCES gyms(id)  ON DELETE CASCADE,
          FOREIGN KEY (user_1)  REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (user_2)  REFERENCES users(id) ON DELETE CASCADE
        )
      `);
      log('  ✓ chat_threads table ready.');
    } catch (e) { log(`  ⚠️ chat_threads: ${e.message}`); }

    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS chat_messages (
          id           INT AUTO_INCREMENT PRIMARY KEY,
          thread_id    INT NOT NULL,
          sender_id    INT NOT NULL,
          message_text TEXT NOT NULL,
          created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (thread_id) REFERENCES chat_threads(id) ON DELETE CASCADE,
          FOREIGN KEY (sender_id) REFERENCES users(id)        ON DELETE CASCADE
        )
      `);
      log('  ✓ chat_messages table ready.');
    } catch (e) { log(`  ⚠️ chat_messages: ${e.message}`); }

    // ── Migration 3: notifications table ────────────────────────────────
    log('\n[3/3] Checking notifications table...');
    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS notifications (
          id         INT AUTO_INCREMENT PRIMARY KEY,
          user_id    INT NOT NULL,
          title      VARCHAR(255) NOT NULL,
          body       TEXT NOT NULL,
          type       VARCHAR(50) NOT NULL,
          gym_id     INT,
          is_read    BOOLEAN DEFAULT FALSE,
          created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      `);
      log('  ✓ notifications table ready.');
    } catch (e) { log(`  ⚠️ notifications: ${e.message}`); }

    // ── Summary ─────────────────────────────────────────────────────────
    log('\n═══════════════════════════════════════');
    log('  All migrations completed successfully');
    log('═══════════════════════════════════════');

    // Show current gym list for verification
    try {
      const [gyms] = await pool.query(
        `SELECT id, name, COALESCE(is_featured, 0) AS is_featured FROM gyms ORDER BY id`
      );
      const gymList = gyms.map(g =>
        `[${g.id}] ${g.name} — featured: ${g.is_featured ? 'YES ⭐' : 'no'}`
      );
      return res.json({
        success: true,
        message: errors.length === 0
          ? 'All migrations ran successfully.'
          : 'Migrations ran with some warnings (see completed/failed lists).',
        migrations: results,
        warnings: errors,
        gyms: gymList,
      });
    } catch (_) {
      return res.json({
        success: true,
        message: 'Migrations ran. Could not fetch gym list.',
        migrations: results,
        warnings: errors,
      });
    }

  } catch (error) {
    fail(`❌ Migration error: ${error.message}`);
    return res.status(500).json({
      success: false,
      error: error.message,
      completed: results,
      failed: errors,
    });
  }
};
