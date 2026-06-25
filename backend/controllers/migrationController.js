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

    // ── Migration 4: Seed new testing gyms (Venice Beach CA, Copacabana Brazil, Washington DC, Toronto Canada) ────
    log('\n[4/4] Checking and seeding new test gyms (IDs 7 to 32)...');
    try {
      const [existingGyms] = await pool.query('SELECT id FROM gyms WHERE id IN (7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32)');
      const existingIds = existingGyms.map(g => g.id);

      // Seed Gym 7
      if (!existingIds.includes(7)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (7, 'GOLD''S GYM VENICE', 'Mecca of Bodybuilding', 'Venice Beach, CA', 'Near Venice Boardwalk', 33.9922, -118.4718, 4.9, TRUE, '5:00 am - 11:00 pm', '+1-310-392-6004', 'GYM', TRUE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (7, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0), (7, 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800', 1)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (7, 'Weights'), (7, 'Cardio'), (7, 'Personal Training'), (7, 'Shower'), (7, 'Locker Room'), (7, 'Parking')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (7, 'VENICE GOLD ACCESS', 45.00, 'mo', '["Basic Access","Cardio & Weights","Standard Hours","Locker & Showers"]', FALSE), (7, 'MECCA VIP', 120.00, 'mo', '["Premium Access","All Gym Features","Unlimited Classes","Sauna & Spa","Personal training"]', TRUE)`);
        log('  ✓ Gym 7 (Gold\'s Gym Venice) seeded.');
      }

      // Seed Gym 8
      if (!existingIds.includes(8)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (8, 'MUSCLE BEACH GYM', 'Venice Beach Recreation Center', 'Venice Beach, CA', 'Outdoor Gym Area', 33.9863, -118.4735, 4.8, TRUE, '8:00 am - 7:00 pm', '+1-310-399-2775', 'GYM', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (8, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (8, 'Outdoor Area'), (8, 'Weights'), (8, 'Beach View')`);
        log('  ✓ Gym 8 (Muscle Beach Gym) seeded.');
      }

      // Seed Gym 9
      if (!existingIds.includes(9)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (9, 'BODYTECH COPACABANA', 'BT Copacabana', 'Copacabana, Brazil', 'Near Copacabana Beach', -22.9711, -43.1886, 4.7, TRUE, '6:00 am - 10:00 pm', '+55-21-2247-9000', 'GYM', TRUE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (9, 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800', 0), (9, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 1)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (9, 'Pool'), (9, 'Sauna'), (9, 'Weights'), (9, 'Cardio'), (9, 'Shower'), (9, 'Locker Room')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (9, 'BODYTECH PLAN', 60.00, 'mo', '["Basic Copacabana Access","Cardio & Weights","Locker & Showers"]', FALSE)`);
        log('  ✓ Gym 9 (Bodytech Copacabana) seeded.');
      }

      // Seed Gym 10
      if (!existingIds.includes(10)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (10, 'SMART FIT COPACABANA', 'Smart Fit Beachfront', 'Copacabana, Brazil', 'Av. Atlântica', -22.9790, -43.1920, 4.5, TRUE, '6:00 am - 11:00 pm', '+55-21-3003-0000', 'GYM', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (10, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (10, 'Cardio'), (10, 'Weights'), (10, 'Shower'), (10, 'Locker Room')`);
        log('  ✓ Gym 10 (Smart Fit Copacabana) seeded.');
      }

      // Seed Gym 11
      if (!existingIds.includes(11)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (11, 'GOLD''S GYM CAPITOL HILL', 'Capitol Hill', 'Washington DC', 'Near Capitol South Metro', 38.8893, -77.0091, 4.6, TRUE, '6:00 am - 10:00 pm', '+1-202-547-4653', 'GYM', TRUE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (11, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (11, 'Weights'), (11, 'Cardio'), (11, 'Personal Training'), (11, 'Shower'), (11, 'Locker Room')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (11, 'CAPITOL BASIC', 35.00, 'mo', '["Basic Access","Cardio & Weights","Locker & Showers"]', FALSE)`);
        log('  ✓ Gym 11 (Gold\'s Gym Capitol Hill) seeded.');
      }

      // Seed Gym 12
      if (!existingIds.includes(12)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (12, 'EQUINOX SPORTS CLUB DC', 'Equinox Georgetown', 'Washington DC', 'Georgetown area', 38.9051, -77.0502, 4.9, TRUE, '5:30 am - 9:30 pm', '+1-202-974-6600', 'GYM', TRUE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (12, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (12, 'Yoga Studio'), (12, 'Spa'), (12, 'Pool'), (12, 'Weights'), (12, 'Cardio'), (12, 'Shower'), (12, 'Locker Room')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (12, 'EQUINOX SIGNATURE', 150.00, 'mo', '["All Club Access","Spa & Pool","Unlimited Yoga & Pilates"]', TRUE)`);
        log('  ✓ Gym 12 (Equinox Sports Club DC) seeded.');
      }

      // Seed Gym 13
      if (!existingIds.includes(13)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (13, 'WASHINGTON DC CROSSFIT', 'Capitol CrossFit', 'Washington DC', 'Downtown DC', 38.9090, -77.0310, 4.8, TRUE, '6:00 am - 8:30 pm', '+1-202-555-0199', 'CrossFit', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (13, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (13, 'CrossFit Rig'), (13, 'Weights'), (13, 'Shower'), (13, 'Parking')`);
        log('  ✓ Gym 13 (Washington DC CrossFit) seeded.');
      }

      // Seed Gym 14 (Karachi)
      if (!existingIds.includes(14)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (14, 'SHAPE UP FITNESS', 'Karachi West', 'Karachi Central', 'Orangi Town Area', 24.9350, 66.9700, 4.4, TRUE, '6:00 am - 10:00 pm', '+92-300-9998888', 'GYM', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (14, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (14, 'Weights'), (14, 'Cardio'), (14, 'Parking')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (14, 'SHAPE BASIC', 20.00, 'mo', '["Basic Access","Weights"]', FALSE)`);
        log('  ✓ Gym 14 (Shape Up Fitness) seeded.');
      }

      // Seed Gym 15 (Karachi)
      if (!existingIds.includes(15)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (15, 'THE GRID CROSSFIT', 'Iron Grid', 'Clifton', 'Clifton Block 2', 24.8150, 67.0250, 4.8, TRUE, '6:30 am - 9:30 pm', '+92-333-8887777', 'CrossFit', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (15, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (15, 'CrossFit Rig'), (15, 'Weights'), (15, 'Shower')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (15, 'GRID CROSSFIT PLAN', 50.00, 'mo', '["CrossFit Rig Access","Coaching"]', FALSE)`);
        log('  ✓ Gym 15 (The Grid CrossFit) seeded.');
      }

      // Seed Gym 16 (Venice Beach, CA)
      if (!existingIds.includes(16)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (16, 'BASECAMP FITNESS VENICE', 'Basecamp Venice', 'Venice Beach, CA', 'Lincoln Blvd', 33.9961, -118.4552, 4.7, TRUE, '5:00 am - 9:00 pm', '+1-310-555-0101', 'GYM', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (16, 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (16, 'Weights'), (16, 'Cardio'), (16, 'Locker Room')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (16, 'BASECAMP MEMBERSHIP', 55.00, 'mo', '["Basecamp Access","All cardio & weights"]', FALSE)`);
        log('  ✓ Gym 16 (Basecamp Fitness Venice) seeded.');
      }

      // Seed Gym 17 (Venice Beach, CA)
      if (!existingIds.includes(17)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (17, 'DEUS EX MACHINA CROSSFIT', 'Deus Gym', 'Venice Beach, CA', 'Venice Blvd', 33.9995, -118.4468, 4.6, TRUE, '6:00 am - 8:00 pm', '+1-310-555-0102', 'CrossFit', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (17, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (17, 'CrossFit Rig'), (17, 'Shower'), (17, 'Weights')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (17, 'DEUS RIG ACCESS', 48.00, 'mo', '["CrossFit Access","Showers"]', FALSE)`);
        log('  ✓ Gym 17 (Deus Ex Machina CrossFit) seeded.');
      }

      // Seed Gym 18 (Copacabana, Brazil)
      if (!existingIds.includes(18)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (18, 'CROSSFIT COPACABANA', 'Beach CrossFit', 'Copacabana, Brazil', 'Rua Figueiredo de Magalhães', -22.9680, -43.1895, 4.8, TRUE, '6:00 am - 9:00 pm', '+55-21-99999-8888', 'CrossFit', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (18, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (18, 'CrossFit Rig'), (18, 'Beach View'), (18, 'Shower')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (18, 'COPACABANA BEACH RIG', 40.00, 'mo', '["Outdoor CrossFit Access"]', FALSE)`);
        log('  ✓ Gym 18 (CrossFit Copacabana) seeded.');
      }

      // Seed Gym 19 (Copacabana, Brazil)
      if (!existingIds.includes(19)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (19, 'ACADEMIA PR1ME', 'Prime Copacabana', 'Copacabana, Brazil', 'Nossa Senhora de Copacabana', -22.9735, -43.1850, 4.4, TRUE, '7:00 am - 10:00 pm', '+55-21-2222-3333', 'GYM', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (19, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (19, 'Weights'), (19, 'Cardio'), (19, 'Locker Room')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (19, 'PR1ME PLAN', 30.00, 'mo', '["Full Gym Access","Lockers"]', FALSE)`);
        log('  ✓ Gym 19 (Academia Pr1me) seeded.');
      }

      // Seed Gym 20 (Washington DC)
      if (!existingIds.includes(20)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (20, 'VIDA FITNESS CAPITOL HILL', 'Vida Capitol Hill', 'Washington DC', 'K Street SE', 38.8785, -76.9950, 4.9, TRUE, '5:00 am - 11:00 pm', '+1-202-999-0200', 'GYM', TRUE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (20, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (20, 'Pool'), (20, 'Weights'), (20, 'Cardio'), (20, 'Shower')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (20, 'VIDA VIP', 99.00, 'mo', '["Vida Club Access","Spa & Pool","Cardio & Weights"]', TRUE)`);
        log('  ✓ Gym 20 (Vida Fitness Capitol Hill) seeded.');
      }

      // Seed Gym 21 (Washington DC)
      if (!existingIds.includes(21)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (21, 'MINT GYM & STUDIO', 'Mint Adams Morgan', 'Washington DC', '18th Street NW', 38.9210, -77.0425, 4.7, TRUE, '6:00 am - 10:00 pm', '+1-202-999-0300', 'Yoga', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (21, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (21, 'Yoga Studio'), (21, 'Weights'), (21, 'Free WiFi')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (21, 'MINT MEMBERSHIP', 70.00, 'mo', '["Unlimited Yoga & Gym Access"]', FALSE)`);
        log('  ✓ Gym 21 (Mint Gym & Studio) seeded.');
      }

      // Seed Gym 22 (Venice Beach, CA)
      if (!existingIds.includes(22)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (22, 'YOGA NEST VENICE', 'Venice Yoga', 'Venice Beach, CA', 'Abbot Kinney Blvd', 33.9902, -118.4650, 4.8, TRUE, '7:00 am - 8:00 pm', '+1-310-555-0103', 'Yoga', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (22, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (22, 'Yoga Studio'), (22, 'Meditation Room')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (22, 'YOGA UNLIMITED', 65.00, 'mo', '["Unlimited Yoga Classes"]', FALSE)`);
        log('  ✓ Gym 22 (Yoga Nest Venice) seeded.');
      }

      // Seed Gym 23 (Venice Beach, CA)
      if (!existingIds.includes(23)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (23, 'VENICE UFC GYM', 'UFC Fit Venice', 'Venice Beach, CA', 'Rose Ave', 33.9975, -118.4750, 4.6, TRUE, '6:00 am - 10:00 pm', '+1-310-555-0104', 'GYM', TRUE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (23, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (23, 'Weights'), (23, 'Cardio'), (23, 'Sauna'), (23, 'Shower')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (23, 'UFC GOLD', 85.00, 'mo', '["UFC Gym Access","Cardio & Weights"]', TRUE)`);
        log('  ✓ Gym 23 (Venice UFC Gym) seeded.');
      }

      // Seed Gym 24 (Copacabana, Brazil)
      if (!existingIds.includes(24)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (24, 'YOGA COPACABANA', 'Yoga & Meditation Copacabana', 'Copacabana, Brazil', 'Av. Atlântica', -22.9750, -43.1900, 4.7, TRUE, '7:00 am - 9:00 pm', '+55-21-2222-4444', 'Yoga', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (24, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (24, 'Yoga Studio'), (24, 'Meditation'), (24, 'Beach View')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (24, 'YOGA COPACABANA VIP', 50.00, 'mo', '["Daily Beachfront Yoga"]', FALSE)`);
        log('  ✓ Gym 24 (Yoga Copacabana) seeded.');
      }

      // Seed Gym 25 (Copacabana, Brazil)
      if (!existingIds.includes(25)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (25, 'ESTRADA MMA ACADEMIA', 'Estrada combat', 'Copacabana, Brazil', 'Rua Barata Ribeiro', -22.9695, -43.1865, 4.5, TRUE, '8:00 am - 9:00 pm', '+55-21-3333-5555', 'MMA', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (25, 'https://images.unsplash.com/photo-1549576490-b0b4831ef60a?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (25, 'MMA Ring'), (25, 'Bags'), (25, 'Shower')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (25, 'ESTRADA MMA PASS', 55.00, 'mo', '["MMA & Combat Training"]', FALSE)`);
        log('  ✓ Gym 25 (Estrada MMA Academia) seeded.');
      }

      // Seed Gym 26 (Washington DC)
      if (!existingIds.includes(26)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (26, 'BETA ACADEMY MMA', 'Beta MMA', 'Washington DC', 'Florida Ave NW', 38.9165, -77.0255, 4.8, TRUE, '6:00 am - 9:30 pm', '+1-202-999-0400', 'MMA', TRUE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (26, 'https://images.unsplash.com/photo-1549576490-b0b4831ef60a?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (26, 'MMA Mat'), (26, 'Bags'), (26, 'Showers')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (26, 'BETA MMA MEMBERSHIP', 90.00, 'mo', '["Unlimited Combat Classes"]', TRUE)`);
        log('  ✓ Gym 26 (Beta Academy MMA) seeded.');
      }

      // Seed Gym 27 (Washington DC)
      if (!existingIds.includes(27)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (27, 'CROSSFIT DUPONT', 'Dupont CrossFit', 'Washington DC', 'Connecticut Ave NW', 38.9098, -77.0430, 4.7, TRUE, '6:00 am - 9:00 pm', '+1-202-999-0500', 'CrossFit', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (27, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (27, 'CrossFit Rig'), (27, 'Weights'), (27, 'Parking')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (27, 'DUPONT PASS', 60.00, 'mo', '["CrossFit Classes","Access"]', FALSE)`);
        log('  ✓ Gym 27 (CrossFit Dupont) seeded.');
      }

      // Seed Gym 28 (Toronto, Canada)
      if (!existingIds.includes(28)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (28, 'GOODLIFE FITNESS TORONTO', 'Bay Street Club', 'Toronto, Canada', 'Near Bay & Bloor', 43.6695, -79.3870, 4.7, TRUE, '5:30 am - 11:00 pm', '+1-416-920-7777', 'GYM', TRUE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (28, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0), (28, 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800', 1)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (28, 'Weights'), (28, 'Cardio'), (28, 'Pool'), (28, 'Sauna'), (28, 'Shower'), (28, 'Locker Room'), (28, 'Parking')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (28, 'GOODLIFE BASIC', 40.00, 'mo', '["Basic Access","Cardio & Weights","Standard Hours","Locker & Showers"]', FALSE), (28, 'GOODLIFE PREMIER', 110.00, 'mo', '["Premium Access","Pool & Sauna","Unlimited Classes","Personal Training","Multi-Branch Access"]', TRUE)`);
        log('  ✓ Gym 28 (GoodLife Fitness Toronto) seeded.');
      }

      // Seed Gym 29 (Toronto, Canada)
      if (!existingIds.includes(29)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (29, 'CROSSFIT TORONTO', 'Distillery CrossFit', 'Toronto, Canada', 'Near Distillery District', 43.6503, -79.3598, 4.8, TRUE, '6:00 am - 9:00 pm', '+1-416-555-0201', 'CrossFit', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (29, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (29, 'CrossFit Rig'), (29, 'Weights'), (29, 'Shower'), (29, 'Parking')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (29, 'CROSSFIT TORONTO PLAN', 90.00, 'mo', '["Unlimited CrossFit Classes","Coaching","Showers"]', FALSE)`);
        log('  ✓ Gym 29 (CrossFit Toronto) seeded.');
      }

      // Seed Gym 30 (Toronto, Canada)
      if (!existingIds.includes(30)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (30, 'EQUINOX TORONTO', 'Yorkville Club', 'Toronto, Canada', 'Bloor St West', 43.6710, -79.3930, 4.9, TRUE, '5:00 am - 11:00 pm', '+1-416-555-0202', 'GYM', TRUE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (30, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0), (30, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 1)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (30, 'Yoga Studio'), (30, 'Spa'), (30, 'Pool'), (30, 'Weights'), (30, 'Cardio'), (30, 'Shower'), (30, 'Locker Room')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (30, 'EQUINOX TORONTO SIGNATURE', 160.00, 'mo', '["All Club Access","Spa & Pool","Unlimited Classes","Guest Passes"]', TRUE)`);
        log('  ✓ Gym 30 (Equinox Toronto) seeded.');
      }

      // Seed Gym 31 (Toronto, Canada)
      if (!existingIds.includes(31)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (31, 'YOGA TORONTO', 'Kensington Yoga', 'Toronto, Canada', 'Near Kensington Market', 43.6540, -79.4020, 4.6, TRUE, '7:00 am - 9:00 pm', '+1-416-555-0203', 'Yoga', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (31, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (31, 'Yoga Studio'), (31, 'Meditation Room'), (31, 'Free WiFi')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (31, 'KENSINGTON YOGA PASS', 55.00, 'mo', '["Unlimited Yoga Classes","Meditation Room","Free WiFi"]', FALSE)`);
        log('  ✓ Gym 31 (Yoga Toronto) seeded.');
      }

      // Seed Gym 32 (Toronto, Canada)
      if (!existingIds.includes(32)) {
        await pool.query(`
          INSERT INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category, is_featured)
          VALUES (32, 'KOMBAT ARTS MMA', 'Mississauga MMA Hub', 'Toronto, Canada', 'Near Mississauga City Centre', 43.5890, -79.6441, 4.8, TRUE, '8:00 am - 10:00 pm', '+1-905-555-0204', 'MMA', FALSE)
        `);
        await pool.query(`INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES (32, 'https://images.unsplash.com/photo-1549576490-b0b4831ef60a?w=800', 0)`);
        await pool.query(`INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES (32, 'MMA Cage'), (32, 'Boxing Bags'), (32, 'Shower'), (32, 'Locker Room')`);
        await pool.query(`INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES (32, 'KOMBAT ARTS MEMBERSHIP', 95.00, 'mo', '["Unlimited MMA Classes","Combat Training","Locker Room"]', TRUE)`);
        log('  ✓ Gym 32 (Kombat Arts MMA) seeded.');
      }
    } catch (seedErr) {
      fail(`  ⚠️ Seeding CA/Brazil/DC/Canada gyms failed: ${seedErr.message}`);
    }

    // ── Migration 5: Add profile_image column to profiles ───────────────
    log('\n[5/7] Checking profile_image column on profiles table...');
    try {
      await pool.query(`ALTER TABLE profiles ADD COLUMN profile_image LONGTEXT NULL AFTER availability`);
      log('  ✓ profile_image column added to profiles.');
    } catch (e) {
      if (e.errno === 1060 || (e.message && e.message.includes('Duplicate column'))) {
        log('  ✓ profile_image column already exists, skipped.');
      } else {
        log(`  ⚠️ Could not add profile_image column: ${e.message}`);
      }
    }

    // ── Migration 6: Fix gym categories — remove 'Women', remap to new list ─
    log('\n[6/7] Updating gym categories (removing legacy "Women" category)...');
    try {
      const [womenGyms] = await pool.query(`SELECT id, name FROM gyms WHERE category = 'Women'`);
      if (womenGyms.length > 0) {
        await pool.query(`UPDATE gyms SET category = 'Functional Fitness' WHERE category = 'Women'`);
        await pool.query(`UPDATE gyms SET sub_name = 'Functional Fitness Hub' WHERE id = 6`);
        log(`  ✓ Updated ${womenGyms.length} gym(s) from category "Women" → "Functional Fitness".`);
      } else {
        log('  ✓ No gyms with "Women" category found — already up to date.');
      }
    } catch (catErr) {
      fail(`  ⚠️ Category update failed: ${catErr.message}`);
    }

    // ── Migration 7: Add about_me column to profiles ─────────────────────
    log('\n[7/8] Checking about_me column on profiles table...');
    try {
      await pool.query(`ALTER TABLE profiles ADD COLUMN about_me TEXT NULL AFTER availability`);
      log('  ✓ about_me column added to profiles.');
    } catch (e) {
      if (e.errno === 1060 || (e.message && e.message.includes('Duplicate column'))) {
        log('  ✓ about_me column already exists, skipped.');
      } else {
        log(`  ⚠️ Could not add about_me column: ${e.message}`);
      }
    }

    // ── Migration 8: Add google_place_id column to gyms ──────────────────
    log('\n[8/8] Checking google_place_id column on gyms table...');
    try {
      await pool.query(`ALTER TABLE gyms ADD COLUMN google_place_id VARCHAR(255) UNIQUE NULL AFTER is_featured`);
      log('  ✓ google_place_id column added to gyms.');
    } catch (e) {
      if (e.errno === 1060 || (e.message && e.message.includes('Duplicate column'))) {
        log('  ✓ google_place_id column already exists, skipped.');
      } else {
        log(`  ⚠️ Could not add google_place_id column: ${e.message}`);
      }
    }

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
