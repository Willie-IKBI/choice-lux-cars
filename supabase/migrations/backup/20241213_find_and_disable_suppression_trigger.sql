-- Find all triggers on the notifications table
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'notifications';

-- Find all functions that might be creating suppressed notifications
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_definition LIKE '%Notifications suppressed%'
AND routine_schema = 'public';

-- Check for any functions that insert into notifications
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_definition LIKE '%INSERT INTO notifications%'
AND routine_schema = 'public';

-- Disable all triggers on notifications table temporarily
ALTER TABLE notifications DISABLE TRIGGER ALL;

-- Delete the suppressed notifications
DELETE FROM notifications WHERE body = 'Notifications suppressed';

-- Create proper notifications with correct column name
INSERT INTO notifications (
  id,
  user_id,
  job_id,
  body,
  notification_type,
  notification_is_read,
  created_at,
  updated_at
) VALUES 
  (gen_random_uuid(), 'edd84489-515e-408e-ac93-378dc63f0eac', 430, 'New job assigned. Please confirm your job in the app.', 'job_assignment', false, NOW(), NOW()),
  (gen_random_uuid(), 'edd84489-515e-408e-ac93-378dc63f0eac', 429, 'Job assignment notification', 'job_assignment', false, NOW(), NOW());

-- Check the result
SELECT 
  id,
  user_id,
  job_id,
  body,
  notification_type,
  notification_is_read,
  created_at
FROM notifications 
WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac'
ORDER BY created_at DESC; 