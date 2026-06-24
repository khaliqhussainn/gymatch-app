-- Migration: Add about_me column to profiles table
-- Run this against your gymatch_db database

ALTER TABLE profiles
  ADD COLUMN IF NOT EXISTS about_me TEXT NULL AFTER availability;
