-- GYMatch Gym Owner Registration Migration
USE gymatch_db;

-- Update users table to add gym_owner role
ALTER TABLE users MODIFY COLUMN role ENUM('guest', 'user', 'admin', 'gym_owner') DEFAULT 'user';

-- Create gym_owners table
CREATE TABLE IF NOT EXISTS gym_owners (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL UNIQUE,
  gym_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

-- Add owner_id column to gyms table
ALTER TABLE gyms ADD COLUMN IF NOT EXISTS owner_id INT NULL AFTER id;
ALTER TABLE gyms ADD CONSTRAINT fk_gym_owner FOREIGN KEY (owner_id) REFERENCES users(id) ON DELETE SET NULL;

-- Add verification_status column to gyms table (for future use, though auto-verified)
ALTER TABLE gyms ADD COLUMN IF NOT EXISTS verification_status ENUM('pending', 'verified', 'rejected') DEFAULT 'verified' AFTER is_featured;

-- Add index for faster gym owner lookups
CREATE INDEX idx_gym_owners_user_id ON gym_owners(user_id);
CREATE INDEX idx_gym_owners_gym_id ON gym_owners(gym_id);
CREATE INDEX idx_gyms_owner_id ON gyms(owner_id);
