-- Run this in Supabase SQL Editor to verify the current state

-- Check notifications table
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

-- Check job_notification_log table
SELECT 
  id,
  job_id,
  driver_id,
  is_reassignment,
  status,
  processed_at,
  created_at
FROM job_notification_log 
ORDER BY created_at DESC;

-- Check if triggers are properly set up
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers 
WHERE event_object_table IN ('jobs', 'job_notification_log')
ORDER BY trigger_name; 