-- Run this in Supabase SQL Editor to verify the notification was created

-- Check if notification was created for the pending job
SELECT 
  id,
  user_id,
  job_id,
  body,
  notification_type,
  is_read,
  created_at
FROM notifications 
WHERE notification_type = 'job_assignment'
ORDER BY created_at DESC;

-- Check the job_notification_log status
SELECT 
  id,
  job_id,
  driver_id,
  is_reassignment,
  status,
  processed_at
FROM job_notification_log 
ORDER BY created_at DESC; 