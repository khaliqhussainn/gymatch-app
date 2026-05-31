-- GYMatch MVP Database Setup Script
-- Run this in phpMyAdmin or MySQL command line

CREATE DATABASE IF NOT EXISTS gymatch_mvp;

USE gymatch_mvp;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Verify tables were created
SHOW TABLES;
