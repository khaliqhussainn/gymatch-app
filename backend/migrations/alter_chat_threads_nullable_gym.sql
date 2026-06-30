-- Allow gym_id to be NULL in chat_threads table
-- This enables users to connect without being at a specific gym
ALTER TABLE chat_threads MODIFY COLUMN gym_id INT NULL;
