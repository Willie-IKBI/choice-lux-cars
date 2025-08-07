-- Clean up the suppressed notifications
DELETE FROM notifications WHERE body = 'Notifications suppressed';

-- Create proper job assignment notifications for the current user
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
  (gen_random_uuid(), 'edd84489-515e-408e-ac93-378dc63f0eac', 429, 'Job assignment notification', 'job_assignment', false, NOW(), NOW()),
  (gen_random_uuid(), 'edd84489-515e-408e-ac93-378dc63f0eac', 428, 'Test job notification', 'job_assignment', false, NOW(), NOW());

-- Verify the notifications were created properly
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