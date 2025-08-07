-- Debug: Check what's in the notifications table
SELECT * FROM notifications;

-- Debug: Check what's in job_notification_log
SELECT * FROM job_notification_log WHERE job_id = 430;

-- Debug: Check if the user exists
SELECT * FROM auth.users WHERE id = '2b48a98e-cdb9-4698-82fc-e8061bf925e6';

-- Debug: Check if the job exists
SELECT * FROM jobs WHERE id = 430;

-- Manually create a proper notification for job 430
INSERT INTO notifications (
  id,
  user_id,
  job_id,
  body,
  notification_type,
  is_read,
  created_at,
  updated_at
) VALUES (
  gen_random_uuid(),
  '2b48a98e-cdb9-4698-82fc-e8061bf925e6',
  430,
  'New job assigned. Please confirm your job in the app.',
  'job_assignment',
  false,
  NOW(),
  NOW()
);

-- Mark job 430 as processed
UPDATE job_notification_log 
SET status = 'processed', 
    processed_at = NOW()
WHERE job_id = 430 AND status = 'pending';

-- Check the result
SELECT * FROM notifications WHERE job_id = 430; 