-- Create notification for the current user (edd84489-515e-408e-ac93-378dc63f0eac)
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
  'edd84489-515e-408e-ac93-378dc63f0eac',
  430,
  'New job assigned. Please confirm your job in the app.',
  'job_assignment',
  false,
  NOW(),
  NOW()
);

-- Also create a test notification
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
  'edd84489-515e-408e-ac93-378dc63f0eac',
  429,
  'Test notification - Job assignment',
  'job_assignment',
  false,
  NOW(),
  NOW()
);

-- Check the result
SELECT * FROM notifications WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac'; 