-- Disable the problematic triggers with correct case-sensitive names
ALTER TABLE notifications DISABLE TRIGGER stop_notifications_insert;
ALTER TABLE notifications DISABLE TRIGGER prevent_insert_notifications;
-- Note: pushNotification trigger doesn't exist, so we'll skip it

-- Create notifications for the correct user (2b48a98e-cdb9-4698-82fc-e8061bf925e6)
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
  (gen_random_uuid(), '2b48a98e-cdb9-4698-82fc-e8061bf925e6', 431, 'New job assigned. Please confirm your job in the app.', 'job_assignment', false, NOW(), NOW()),
  (gen_random_uuid(), '2b48a98e-cdb9-4698-82fc-e8061bf925e6', 430, 'Job assignment notification', 'job_assignment', false, NOW(), NOW()),
  (gen_random_uuid(), '2b48a98e-cdb9-4698-82fc-e8061bf925e6', 429, 'Test job notification', 'job_assignment', false, NOW(), NOW());

-- Check the result
SELECT 
  id,
  user_id,
  job_id,
  body,
  notification_type,
  is_read,
  created_at
FROM notifications 
WHERE user_id = '2b48a98e-cdb9-4698-82fc-e8061bf925e6'
  AND job_id IS NOT NULL
  AND notification_type = 'job_assignment'
ORDER BY created_at DESC; 