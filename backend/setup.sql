-- Verify tables were created
CREATE DATABASE IF NOT EXISTS gymatch_db;
USE gymatch_db;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  email VARCHAR(255) UNIQUE NOT NULL,
  password VARCHAR(255),
  google_id VARCHAR(255) UNIQUE,
  apple_id VARCHAR(255) UNIQUE,
  role ENUM('guest', 'user', 'admin') DEFAULT 'user',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE profiles (
  user_id INT PRIMARY KEY,
  name VARCHAR(255),
  age INT,
  gender ENUM('male', 'female', 'other'),
  fitness_goals TEXT,
  workout_types TEXT,
  availability TEXT,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
