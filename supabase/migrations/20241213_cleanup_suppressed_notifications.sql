-- Clean up the old "Notifications suppressed" records that are causing the TypeError
DELETE FROM notifications 
WHERE body = 'Notifications suppressed' 
  AND job_id IS NULL 
  AND notification_type IS NULL;

-- Verify the cleanup
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
ORDER BY created_at DESC; 