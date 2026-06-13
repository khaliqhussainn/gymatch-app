-- Add featured field to gyms table
USE gymatch_db;

-- Add is_featured column to gyms table
ALTER TABLE gyms 
ADD COLUMN IF NOT EXISTS is_featured BOOLEAN DEFAULT FALSE AFTER category;

-- Mark some gyms as featured for demonstration
UPDATE gyms SET is_featured = TRUE WHERE id IN (1, 2, 4);

-- Add index for better performance when filtering by featured
CREATE INDEX IF NOT EXISTS idx_gyms_featured ON gyms(is_featured);
