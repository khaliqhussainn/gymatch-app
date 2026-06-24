-- Add Apple Sign In support column
ALTER TABLE users ADD COLUMN apple_id VARCHAR(255) UNIQUE NULL AFTER google_id;
