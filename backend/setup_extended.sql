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
  (6, 'LADIES ONLY FITNESS', 'Women''s Health', 'Gulshan', 'Near Gulshan Chowrangi', 24.9200, 67.0900, 4.8, TRUE, '7:00 am - 9:00 pm', '+92-300-4445555', 'Women'),
  -- Seed gyms in Venice Beach, CA
  (7, 'GOLD''S GYM VENICE', 'Mecca of Bodybuilding', 'Venice Beach, CA', 'Near Venice Boardwalk', 33.9922, -118.4718, 4.9, TRUE, '5:00 am - 11:00 pm', '+1-310-392-6004', 'GYM'),
  (8, 'MUSCLE BEACH GYM', 'Venice Beach Recreation Center', 'Venice Beach, CA', 'Outdoor Gym Area', 33.9863, -118.4735, 4.8, TRUE, '8:00 am - 7:00 pm', '+1-310-399-2775', 'GYM'),
  -- Seed gyms in Copacabana, Brazil
  (9, 'BODYTECH COPACABANA', 'BT Copacabana', 'Copacabana, Brazil', 'Near Copacabana Beach', -22.9711, -43.1886, 4.7, TRUE, '6:00 am - 10:00 pm', '+55-21-2247-9000', 'GYM'),
  (10, 'SMART FIT COPACABANA', 'Smart Fit Beachfront', 'Copacabana, Brazil', 'Av. Atlântica', -22.9790, -43.1920, 4.5, TRUE, '6:00 am - 11:00 pm', '+55-21-3003-0000', 'GYM'),
  -- Seed gyms in Washington DC
  (11, 'GOLD''S GYM CAPITOL HILL', 'Capitol Hill', 'Washington DC', 'Near Capitol South Metro', 38.8893, -77.0091, 4.6, TRUE, '6:00 am - 10:00 pm', '+1-202-547-4653', 'GYM'),
  (12, 'EQUINOX SPORTS CLUB DC', 'Equinox Georgetown', 'Washington DC', 'Georgetown area', 38.9051, -77.0502, 4.9, TRUE, '5:30 am - 9:30 pm', '+1-202-974-6600', 'GYM'),
  (13, 'WASHINGTON DC CROSSFIT', 'Capitol CrossFit', 'Washington DC', 'Downtown DC', 38.9090, -77.0310, 4.8, TRUE, '6:00 am - 8:30 pm', '+1-202-555-0199', 'CrossFit'),
  -- Extra Karachi Gyms
  (14, 'SHAPE UP FITNESS', 'Karachi West', 'Karachi Central', 'Orangi Town Area', 24.9350, 66.9700, 4.4, TRUE, '6:00 am - 10:00 pm', '+92-300-9998888', 'GYM'),
  (15, 'THE GRID CROSSFIT', 'Iron Grid', 'Clifton', 'Clifton Block 2', 24.8150, 67.0250, 4.8, TRUE, '6:30 am - 9:30 pm', '+92-333-8887777', 'CrossFit'),
  -- Extra Venice Beach Gyms
  (16, 'BASECAMP FITNESS VENICE', 'Basecamp Venice', 'Venice Beach, CA', 'Lincoln Blvd', 33.9961, -118.4552, 4.7, TRUE, '5:00 am - 9:00 pm', '+1-310-555-0101', 'GYM'),
  (17, 'DEUS EX MACHINA CROSSFIT', 'Deus Gym', 'Venice Beach, CA', 'Venice Blvd', 33.9995, -118.4468, 4.6, TRUE, '6:00 am - 8:00 pm', '+1-310-555-0102', 'CrossFit'),
  -- Extra Copacabana Gyms
  (18, 'CROSSFIT COPACABANA', 'Beach CrossFit', 'Copacabana, Brazil', 'Rua Figueiredo de Magalhães', -22.9680, -43.1895, 4.8, TRUE, '6:00 am - 9:00 pm', '+55-21-99999-8888', 'CrossFit'),
  (19, 'ACADEMIA PR1ME', 'Prime Copacabana', 'Copacabana, Brazil', 'Nossa Senhora de Copacabana', -22.9735, -43.1850, 4.4, TRUE, '7:00 am - 10:00 pm', '+55-21-2222-3333', 'GYM'),
  -- Extra Washington DC Gyms
  (20, 'VIDA FITNESS CAPITOL HILL', 'Vida Capitol Hill', 'Washington DC', 'K Street SE', 38.8785, -76.9950, 4.9, TRUE, '5:00 am - 11:00 pm', '+1-202-999-0200', 'GYM'),
  (21, 'MINT GYM & STUDIO', 'Mint Adams Morgan', 'Washington DC', '18th Street NW', 38.9210, -77.0425, 4.7, TRUE, '6:00 am - 10:00 pm', '+1-202-999-0300', 'Yoga'),
  -- More Venice Beach Gyms
  (22, 'YOGA NEST VENICE', 'Venice Yoga', 'Venice Beach, CA', 'Abbot Kinney Blvd', 33.9902, -118.4650, 4.8, TRUE, '7:00 am - 8:00 pm', '+1-310-555-0103', 'Yoga'),
  (23, 'VENICE UFC GYM', 'UFC Fit Venice', 'Venice Beach, CA', 'Rose Ave', 33.9975, -118.4750, 4.6, TRUE, '6:00 am - 10:00 pm', '+1-310-555-0104', 'GYM'),
  -- More Copacabana Gyms
  (24, 'YOGA COPACABANA', 'Yoga & Meditation Copacabana', 'Copacabana, Brazil', 'Av. Atlântica', -22.9750, -43.1900, 4.7, TRUE, '7:00 am - 9:00 pm', '+55-21-2222-4444', 'Yoga'),
  (25, 'ESTRADA MMA ACADEMIA', 'Estrada combat', 'Copacabana, Brazil', 'Rua Barata Ribeiro', -22.9695, -43.1865, 4.5, TRUE, '8:00 am - 9:00 pm', '+55-21-3333-5555', 'MMA'),
  -- More Washington DC Gyms
  (26, 'BETA ACADEMY MMA', 'Beta MMA', 'Washington DC', 'Florida Ave NW', 38.9165, -77.0255, 4.8, TRUE, '6:00 am - 9:30 pm', '+1-202-999-0400', 'MMA'),
  (27, 'CROSSFIT DUPONT', 'Dupont CrossFit', 'Washington DC', 'Connecticut Ave NW', 38.9098, -77.0430, 4.7, TRUE, '6:00 am - 9:00 pm', '+1-202-999-0500', 'CrossFit'),
  -- Seed gyms in Toronto, Canada
  (28, 'GOODLIFE FITNESS TORONTO', 'Bay Street Club', 'Toronto, Canada', 'Near Bay & Bloor', 43.6695, -79.3870, 4.7, TRUE, '5:30 am - 11:00 pm', '+1-416-920-7777', 'GYM'),
  (29, 'CROSSFIT TORONTO', 'Distillery CrossFit', 'Toronto, Canada', 'Near Distillery District', 43.6503, -79.3598, 4.8, TRUE, '6:00 am - 9:00 pm', '+1-416-555-0201', 'CrossFit'),
  (30, 'EQUINOX TORONTO', 'Yorkville Club', 'Toronto, Canada', 'Bloor St West', 43.6710, -79.3930, 4.9, TRUE, '5:00 am - 11:00 pm', '+1-416-555-0202', 'GYM'),
  (31, 'YOGA TORONTO', 'Kensington Yoga', 'Toronto, Canada', 'Near Kensington Market', 43.6540, -79.4020, 4.6, TRUE, '7:00 am - 9:00 pm', '+1-416-555-0203', 'Yoga'),
  (32, 'KOMBAT ARTS MMA', 'Mississauga MMA Hub', 'Toronto, Canada', 'Near Mississauga City Centre', 43.5890, -79.6441, 4.8, TRUE, '8:00 am - 10:00 pm', '+1-905-555-0204', 'MMA');

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
  (6, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 0),
  -- Seed images for new gyms
  (7, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0),
  (7, 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800', 1),
  (8, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0),
  (9, 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800', 0),
  (9, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 1),
  (10, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 0),
  (11, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0),
  (12, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0),
  (13, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0),
  (14, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0),
  (15, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0),
  (16, 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800', 0),
  (17, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0),
  (18, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0),
  (19, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 0),
  (20, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0),
  (21, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0),
  (22, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0),
  (23, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0),
  (24, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0),
  (25, 'https://images.unsplash.com/photo-1549576490-b0b4831ef60a?w=800', 0),
  (26, 'https://images.unsplash.com/photo-1549576490-b0b4831ef60a?w=800', 0),
  (27, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0),
  -- Images for Toronto, Canada gyms
  (28, 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800', 0),
  (28, 'https://images.unsplash.com/photo-1540497077202-7c8a3999166f?w=800', 1),
  (29, 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?w=800', 0),
  (30, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0),
  (30, 'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800', 1),
  (31, 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800', 0),
  (32, 'https://images.unsplash.com/photo-1549576490-b0b4831ef60a?w=800', 0);

-- Seed amenities
INSERT IGNORE INTO gym_amenities (gym_id, name) VALUES
  (1, 'Yoga Studio'), (1, 'Parking'), (1, 'Cardio'), (1, 'Sauna'), (1, 'Shower'),
  (1, 'Free WiFi'), (1, 'Pool'), (1, 'Locker Room'), (1, 'Weights'), (1, 'Personal Training Area'),
  (2, 'Cardio'), (2, 'Weights'), (2, 'Shower'), (2, 'Locker Room'), (2, 'Parking'),
  (3, 'CrossFit Rig'), (3, 'Shower'), (3, 'Parking'), (3, 'Weights'),
  (4, 'Yoga Studio'), (4, 'Shower'), (4, 'Meditation Room'), (4, 'Free WiFi'),
  (5, 'MMA Cage'), (5, 'Boxing Bags'), (5, 'Shower'), (5, 'Lockers'),
  (6, 'Cardio'), (6, 'Weights'), (6, 'Shower'), (6, 'Locker Room'), (6, 'Free WiFi'),
  -- Seed amenities for new gyms
  (7, 'Weights'), (7, 'Cardio'), (7, 'Personal Training'), (7, 'Shower'), (7, 'Locker Room'), (7, 'Parking'),
  (8, 'Outdoor Area'), (8, 'Weights'), (8, 'Beach View'),
  (9, 'Pool'), (9, 'Sauna'), (9, 'Weights'), (9, 'Cardio'), (9, 'Shower'), (9, 'Locker Room'),
  (10, 'Cardio'), (10, 'Weights'), (10, 'Shower'), (10, 'Locker Room'),
  (11, 'Weights'), (11, 'Cardio'), (11, 'Personal Training'), (11, 'Shower'), (11, 'Locker Room'),
  (12, 'Yoga Studio'), (12, 'Spa'), (12, 'Pool'), (12, 'Weights'), (12, 'Cardio'), (12, 'Shower'), (12, 'Locker Room'),
  (13, 'CrossFit Rig'), (13, 'Weights'), (13, 'Shower'), (13, 'Parking'),
  (14, 'Weights'), (14, 'Cardio'), (14, 'Parking'),
  (15, 'CrossFit Rig'), (15, 'Weights'), (15, 'Shower'),
  (16, 'Weights'), (16, 'Cardio'), (16, 'Locker Room'),
  (17, 'CrossFit Rig'), (17, 'Shower'), (17, 'Weights'),
  (18, 'CrossFit Rig'), (18, 'Beach View'), (18, 'Shower'),
  (19, 'Weights'), (19, 'Cardio'), (19, 'Locker Room'),
  (20, 'Pool'), (20, 'Weights'), (20, 'Cardio'), (20, 'Shower'),
  (21, 'Yoga Studio'), (21, 'Weights'), (21, 'Free WiFi'),
  (22, 'Yoga Studio'), (22, 'Meditation Room'),
  (23, 'Weights'), (23, 'Cardio'), (23, 'Sauna'), (23, 'Shower'),
  (24, 'Yoga Studio'), (24, 'Meditation'), (24, 'Beach View'),
  (25, 'MMA Ring'), (25, 'Bags'), (25, 'Shower'),
  (26, 'MMA Mat'), (26, 'Bags'), (26, 'Showers'),
  (27, 'CrossFit Rig'), (27, 'Weights'), (27, 'Parking'),
  -- Amenities for Toronto, Canada gyms
  (28, 'Weights'), (28, 'Cardio'), (28, 'Pool'), (28, 'Sauna'), (28, 'Shower'), (28, 'Locker Room'), (28, 'Parking'),
  (29, 'CrossFit Rig'), (29, 'Weights'), (29, 'Shower'), (29, 'Parking'),
  (30, 'Yoga Studio'), (30, 'Spa'), (30, 'Pool'), (30, 'Weights'), (30, 'Cardio'), (30, 'Shower'), (30, 'Locker Room'),
  (31, 'Yoga Studio'), (31, 'Meditation Room'), (31, 'Free WiFi'),
  (32, 'MMA Cage'), (32, 'Boxing Bags'), (32, 'Shower'), (32, 'Locker Room');

-- Seed membership plans
INSERT IGNORE INTO gym_membership_plans (gym_id, name, price, billing_period, features, is_premium) VALUES
  (1, 'BASIC ACCESS', 30.00, 'mo', '["Basic Access","Cardio & Weights","Standard Hours","Locker & Showers","1 Free Assessment"]', FALSE),
  (1, 'ULTRA PREMIUMMATCH', 99.00, 'mo', '["Premium Access","All Basic Features","Unlimited Classes","Sauna & Spa","Multi-Branch Access","2 Guest Passes/mo","Personal training"]', TRUE),
  (2, 'BASIC ACCESS', 25.00, 'mo', '["Basic Access","Cardio & Weights","Standard Hours","Locker Room"]', FALSE),
  (2, 'PREMIUM', 75.00, 'mo', '["Premium Access","All Basic Features","Unlimited Classes","Personal Training"]', TRUE),
  -- Seed membership plans for new gyms
  (7, 'VENICE GOLD ACCESS', 45.00, 'mo', '["Basic Access","Cardio & Weights","Standard Hours","Locker & Showers"]', FALSE),
  (7, 'MECCA VIP', 120.00, 'mo', '["Premium Access","All Gym Features","Unlimited Classes","Sauna & Spa","Personal training"]', TRUE),
  (9, 'BODYTECH PLAN', 60.00, 'mo', '["Basic Copacabana Access","Cardio & Weights","Locker & Showers"]', FALSE),
  (11, 'CAPITOL BASIC', 35.00, 'mo', '["Basic Access","Cardio & Weights","Locker & Showers"]', FALSE),
  (12, 'EQUINOX SIGNATURE', 150.00, 'mo', '["All Club Access","Spa & Pool","Unlimited Yoga & Pilates"]', TRUE),
  (14, 'SHAPE BASIC', 20.00, 'mo', '["Basic Access","Weights"]', FALSE),
  (15, 'GRID CROSSFIT PLAN', 50.00, 'mo', '["CrossFit Rig Access","Coaching"]', FALSE),
  (16, 'BASECAMP MEMBERSHIP', 55.00, 'mo', '["Basecamp Access","All cardio & weights"]', FALSE),
  (17, 'DEUS RIG ACCESS', 48.00, 'mo', '["CrossFit Access","Showers"]', FALSE),
  (18, 'COPACABANA BEACH RIG', 40.00, 'mo', '["Outdoor CrossFit Access"]', FALSE),
  (19, 'PR1ME PLAN', 30.00, 'mo', '["Full Gym Access","Lockers"]', FALSE),
  (20, 'VIDA VIP', 99.00, 'mo', '["Vida Club Access","Spa & Pool","Cardio & Weights"]', TRUE),
  (21, 'MINT MEMBERSHIP', 70.00, 'mo', '["Unlimited Yoga & Gym Access"]', FALSE),
  (22, 'YOGA UNLIMITED', 65.00, 'mo', '["Unlimited Yoga Classes"]', FALSE),
  (23, 'UFC GOLD', 85.00, 'mo', '["UFC Gym Access","Cardio & Weights"]', TRUE),
  (24, 'YOGA COPACABANA VIP', 50.00, 'mo', '["Daily Beachfront Yoga"]', FALSE),
  (25, 'ESTRADA MMA PASS', 55.00, 'mo', '["MMA & Combat Training"]', FALSE),
  (26, 'BETA MMA MEMBERSHIP', 90.00, 'mo', '["Unlimited Combat Classes"]', TRUE),
  (27, 'DUPONT PASS', 60.00, 'mo', '["CrossFit Classes","Access"]', FALSE),
  -- Membership plans for Toronto, Canada gyms
  (28, 'GOODLIFE BASIC', 40.00, 'mo', '["Basic Access","Cardio & Weights","Standard Hours","Locker & Showers"]', FALSE),
  (28, 'GOODLIFE PREMIER', 110.00, 'mo', '["Premium Access","Pool & Sauna","Unlimited Classes","Personal Training","Multi-Branch Access"]', TRUE),
  (29, 'CROSSFIT TORONTO PLAN', 90.00, 'mo', '["Unlimited CrossFit Classes","Coaching","Showers"]', FALSE),
  (30, 'EQUINOX TORONTO SIGNATURE', 160.00, 'mo', '["All Club Access","Spa & Pool","Unlimited Classes","Guest Passes"]', TRUE),
  (31, 'KENSINGTON YOGA PASS', 55.00, 'mo', '["Unlimited Yoga Classes","Meditation Room","Free WiFi"]', FALSE),
  (32, 'KOMBAT ARTS MEMBERSHIP', 95.00, 'mo', '["Unlimited MMA Classes","Combat Training","Locker Room"]', TRUE);

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

