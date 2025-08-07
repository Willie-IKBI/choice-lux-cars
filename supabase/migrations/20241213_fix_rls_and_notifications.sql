-- First, let's check what's in the notifications table
SELECT * FROM notifications;

-- Check if RLS is enabled and what policies exist
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE tablename = 'notifications';

SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'notifications';

-- Temporarily disable RLS to test
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- Create a test notification for the current user
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
  'Test notification - Job assignment',
  'job_assignment',
  false,
  NOW(),
  NOW()
);

-- Check if the notification was created
SELECT * FROM notifications WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac';

-- Re-enable RLS and create proper policies
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;

-- Create proper RLS policies
CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- Test the policies work
SELECT * FROM notifications WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac'; 