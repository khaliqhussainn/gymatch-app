-- ============================================================
-- GYMatch Live Database Migration
-- Run this in phpMyAdmin or cPanel MySQL on the live server
-- Database: craftcreation_gymatch_db (or your live DB name)
-- ============================================================

-- [1] Add is_featured column to gyms table
ALTER TABLE gyms ADD COLUMN IF NOT EXISTS is_featured BOOLEAN NOT NULL DEFAULT FALSE AFTER category;

-- [2] Mark featured gyms (IDs 1, 2, 4)
UPDATE gyms SET is_featured = TRUE WHERE id IN (1, 2, 4);

-- [3] Create chat_threads table
CREATE TABLE IF NOT EXISTS chat_threads (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  gym_id     INT NOT NULL,
  user_1     INT NOT NULL,
  user_2     INT NOT NULL,
  match_type VARCHAR(50) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME NOT NULL,
  FOREIGN KEY (gym_id) REFERENCES gyms(id)  ON DELETE CASCADE,
  FOREIGN KEY (user_1) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (user_2) REFERENCES users(id) ON DELETE CASCADE
);

-- [4] Create chat_messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  thread_id    INT NOT NULL,
  sender_id    INT NOT NULL,
  message_text TEXT NOT NULL,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (thread_id) REFERENCES chat_threads(id) ON DELETE CASCADE,
  FOREIGN KEY (sender_id) REFERENCES users(id)        ON DELETE CASCADE
);

-- [5] Create notifications table
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
);

-- [6] Verify
SELECT id, name, is_featured FROM gyms ORDER BY id;

-- [7] Update gym categories — remove 'Women' category, remap to new category list
UPDATE gyms SET category = 'Functional Fitness' WHERE category = 'Women';
UPDATE gyms SET sub_name = 'Functional Fitness Hub' WHERE id = 6;

-- [8] Verify category update
SELECT id, name, category FROM gyms ORDER BY id;
