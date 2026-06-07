-- Migration to fix password field to allow NULL for Google auth users
USE gymatch_db;

-- Make password field nullable
ALTER TABLE users MODIFY password VARCHAR(255);

-- Verify the change
DESCRIBE users;
