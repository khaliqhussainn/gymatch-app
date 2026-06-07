-- GYMatch Extended Schema for Phase 2: Gym Discovery
USE gymatch_db;

-- Add name column to users table if it doesn't exist
ALTER TABLE users ADD COLUMN IF NOT EXISTS name VARCHAR(255) AFTER email;

-- Gyms table
CREATE TABLE IF NOT EXISTS gyms (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  sub_name VARCHAR(255),
  location_name VARCHAR(255) NOT NULL,
  near_location VARCHAR(255),
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  rating DECIMAL(2,1) DEFAULT 4.5,
  is_open BOOLEAN DEFAULT TRUE,
  open_hours VARCHAR(100) DEFAULT '6:00 am - 11:00 pm',
  contact_phone VARCHAR(50),
  category VARCHAR(50) DEFAULT 'GYM',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Gym images
CREATE TABLE IF NOT EXISTS gym_images (
  id INT AUTO_INCREMENT PRIMARY KEY,
  gym_id INT NOT NULL,
  image_url VARCHAR(500) NOT NULL,
  sort_order INT DEFAULT 0,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

-- Gym amenities
CREATE TABLE IF NOT EXISTS gym_amenities (
  id INT AUTO_INCREMENT PRIMARY KEY,
  gym_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

-- Gym membership plans
CREATE TABLE IF NOT EXISTS gym_membership_plans (
  id INT AUTO_INCREMENT PRIMARY KEY,
  gym_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  price DECIMAL(10,2) NOT NULL,
  billing_period VARCHAR(50) DEFAULT 'mo',
  features TEXT NOT NULL,
  is_premium BOOLEAN DEFAULT FALSE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

-- Saved / Favorite gyms
CREATE TABLE IF NOT EXISTS saved_gyms (
  user_id INT NOT NULL,
  gym_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, gym_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

-- Active workout partners at a gym
CREATE TABLE IF NOT EXISTS active_partners (
  user_id INT NOT NULL,
  gym_id INT NOT NULL,
  status ENUM('Active Now', 'Training Now') DEFAULT 'Active Now',
  workout_type VARCHAR(100),
  experience_level ENUM('Beginner', 'Intermediate', 'Advanced') DEFAULT 'Intermediate',
  activated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id, gym_id),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (gym_id) REFERENCES gyms(id) ON DELETE CASCADE
);

-- Seed sample gyms near Karachi
INSERT IGNORE INTO gyms (id, name, sub_name, location_name, near_location, latitude, longitude, rating, is_open, open_hours, contact_phone, category)
VALUES
  (1, 'GOLD''S GYM', 'GYM ABC', 'Karachi Central', 'Near ABC Mall', 24.8607, 67.0011, 4.8, TRUE, '6:00 am - 11:00 pm', '+92-300-1234567', 'GYM'),
  (2, 'TITAN FITNESS', 'GYM XYZ', 'Karachi East', 'Near XYZ Tower', 24.8750, 67.0650, 4.7, TRUE, '5:30 am - 10:00 pm', '+92-300-7654321', 'GYM'),
  (3, 'CROSSFIT KARACHI', 'Elite Box', 'Clifton', 'Near Sea View', 24.8040, 67.0300, 4.6, TRUE, '6:00 am - 9:00 pm', '+92-333-1112222', 'CrossFit'),
  (4, 'YOGA STUDIO 5', 'Mind & Body', 'Defence', 'Near DHA Phase 5', 24.8100, 67.0600, 4.9, TRUE, '7:00 am - 8:00 pm', '+92-321-9876543', 'Yoga'),
  (5, 'MMA FIGHTERS GYM', 'Combat Zone', 'PECHS', 'Near Tariq Road', 24.8700, 67.0400, 4.5, FALSE, '9:00 am - 6:00 pm', '+92-333-5556666', 'MMA'),
  (6, 'LADIES ONLY FITNESS', 'Women''s Health', 'Gulshan', 'Near Gulshan Chowrangi', 24.9200, 67.0900, 4.8, TRUE, '7:00 am - 9:00 pm', '+92-300-4445555', 'Women');

-- Seed images
INSERT IGNORE INTO gym_images (gym_id, image_url, sort_order) VALUES
  (1, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0),
  (1, 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800', 1),
  (1, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 2),
  (2, 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800', 0),
  (2, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 1),
  (3, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0),
  (4, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0),
  (5, 'https://images.unsplash.com/photo-1549576490-b0b4831ef60a?w=800', 0),
  (6, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 0);

-- Seed amenities
INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES
  (1, 'Yoga Studio'), (1, 'Parking'), (1, 'Cardio'), (1, 'Sauna'), (1, 'Shower'),
  (1, 'Free WiFi'), (1, 'Pool'), (1, 'Locker Room'), (1, 'Weights'), (1, 'Personal Training Area'),
  (2, 'Cardio'), (2, 'Weights'), (2, 'Shower'), (2, 'Locker Room'), (2, 'Parking'),
  (3, 'CrossFit Rig'), (3, 'Shower'), (3, 'Parking'), (3, 'Weights'),
  (4, 'Yoga Studio'), (4, 'Shower'), (4, 'Meditation Room'), (4, 'Free WiFi'),
  (5, 'MMA Cage'), (5, 'Boxing Bags'), (5, 'Shower'), (5, 'Lockers'),
  (6, 'Cardio'), (6, 'Weights'), (6, 'Shower'), (6, 'Locker Room'), (6, 'Free WiFi');

-- Seed membership plans
INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES
  (1, 'BASIC ACCESS', 30.00, 'mo', '["Basic Access","Cardio & Weights","Standard Hours","Locker & Showers","1 Free Assessment"]', FALSE),
  (1, 'ULTRA PREMIUMMATCH', 99.00, 'mo', '["Premium Access","All Basic Features","Unlimited Classes","Sauna & Spa","Multi-Branch Access","2 Guest Passes/mo","Personal training"]', TRUE),
  (2, 'BASIC ACCESS', 25.00, 'mo', '["Basic Access","Cardio & Weights","Standard Hours","Locker Room"]', FALSE),
  (2, 'PREMIUM', 75.00, 'mo', '["Premium Access","All Basic Features","Unlimited Classes","Personal Training"]', TRUE);

-- Notifications table
CREATE TABLE IF NOT EXISTS notifications (
  id INT AUTO_INCREMENT PRIMARY KEY,
  user_id INT NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'chats', 'gymDetail', 'profile'
  gym_id INT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

