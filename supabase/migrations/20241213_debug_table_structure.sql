-- Check the actual table structure
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'notifications' 
ORDER BY ordinal_position;

-- Check what's actually in the table
SELECT * FROM notifications WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac';

-- Force delete the suppressed notifications by ID
DELETE FROM notifications 
WHERE id IN (
  '58ec699c-2f4a-4347-a818-ed807d254618',
  '4e9d403a-2abd-43c2-bef5-a40ca7ea0025',
  '001d44da-66e7-4ee9-8d03-6055c3e283fd'
);

-- Create proper notifications with correct column names
INSERT INTO notifications (
  id,
  user_id,
  job_id,
  body,
  notification_type,
  is_read,
  created_at,
  updated_at
) VALUES 
  (gen_random_uuid(), 'edd84489-515e-408e-ac93-378dc63f0eac', 430, 'New job assigned. Please confirm your job in the app.', 'job_assignment', false, NOW(), NOW()),
  (gen_random_uuid(), 'edd84489-515e-408e-ac93-378dc63f0eac', 429, 'Job assignment notification', 'job_assignment', false, NOW(), NOW());

-- Check the final result
SELECT 
  id,
  user_id,
  job_id,
  body,
  notification_type,
  is_read,
  created_at
FROM notifications 
WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac'
ORDER BY created_at DESC; 