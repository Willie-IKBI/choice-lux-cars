-- Create a test notification manually to verify the system works
INSERT INTO notifications (
  user_id,
  job_id,
  body,
  notification_type,
  is_read
) VALUES (
  '2b48a98e-cdb9-4698-82fc-e8061bf925e6', -- Your user ID
  432, -- The job ID from your log
  'Test notification - Manual creation',
  'job_assignment',
  false
);

-- Verify it was created
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