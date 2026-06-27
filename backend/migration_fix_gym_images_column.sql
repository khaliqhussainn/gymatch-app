-- Migration to fix gym_images table column size
-- Change image_url from VARCHAR(500) to LONGTEXT to support base64 images

USE gymatch_db;

ALTER TABLE gym_images MODIFY COLUMN image_url LONGTEXT NOT NULL;
