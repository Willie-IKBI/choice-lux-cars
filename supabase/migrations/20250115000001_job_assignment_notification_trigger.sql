-- Job Assignment Notification Trigger Migration
-- Applied: 2025-01-15
-- Description: Creates notification trigger for new job assignments to drivers

-- ========================================
-- STEP 1: ENSURE NOTIFICATIONS TABLE EXISTS
-- ========================================

-- Create notifications table if it doesn't exist
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    job_id BIGINT REFERENCES jobs(id) ON DELETE CASCADE,
    body TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    notification_type VARCHAR(50) DEFAULT 'job_assignment',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_hidden BOOLEAN DEFAULT FALSE
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);
CREATE INDEX IF NOT EXISTS idx_notifications_job_id ON notifications(job_id);

-- Enable real-time for notifications table
ALTER TABLE notifications REPLICA IDENTITY FULL;

-- Enable RLS
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
DROP POLICY IF EXISTS "Users can view their own notifications" ON notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON notifications;
DROP POLICY IF EXISTS "System can insert notifications" ON notifications;

CREATE POLICY "Users can view their own notifications" ON notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can insert notifications" ON notifications
    FOR INSERT WITH CHECK (true);

-- ========================================
-- STEP 2: CREATE NOTIFICATION TRIGGER FUNCTION
-- ========================================

-- Function to create notification when job is created with driver assigned
CREATE OR REPLACE FUNCTION create_job_assignment_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create notification if driver_id is set and this is a new job (INSERT)
  IF NEW.driver_id IS NOT NULL THEN
    
    -- Insert notification for the assigned driver
    INSERT INTO notifications (
      user_id,
      job_id,
      body,
      notification_type,
      is_read
    ) VALUES (
      NEW.driver_id,
      NEW.id,
      'New job assigned - Job #' || COALESCE(NEW.job_number, NEW.id::text),
      'job_assignment',
      false
    );
    
    -- Log the notification creation
    RAISE NOTICE 'Notification created for driver % for job %', NEW.driver_id, NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 3: CREATE THE TRIGGER
-- ========================================

-- Create trigger for job creation with driver assignment
DROP TRIGGER IF EXISTS job_assignment_notification_trigger ON jobs;
CREATE TRIGGER job_assignment_notification_trigger
  AFTER INSERT ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION create_job_assignment_notification();

-- ========================================
-- STEP 4: CREATE FUNCTION TO MARK NOTIFICATIONS AS READ
-- ========================================

-- Function to mark notifications as read when job is confirmed
CREATE OR REPLACE FUNCTION mark_job_notifications_as_read()
RETURNS TRIGGER AS $$
BEGIN
  -- Mark all notifications for this job as read when job is confirmed
  IF NEW.driver_confirm_ind AND (OLD.driver_confirm_ind IS NULL OR NOT OLD.driver_confirm_ind) THEN
    UPDATE notifications 
    SET is_read = true, updated_at = NOW()
    WHERE job_id = NEW.id AND is_read = false AND notification_type = 'job_assignment';
    
    RAISE NOTICE 'Marked job assignment notifications as read for job %', NEW.id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for job confirmation
DROP TRIGGER IF EXISTS job_confirmation_notification_trigger ON jobs;
CREATE TRIGGER job_confirmation_notification_trigger
  AFTER UPDATE OF driver_confirm_ind ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION mark_job_notifications_as_read();

-- ========================================
-- STEP 5: CREATE CLEANUP FUNCTION
-- ========================================

-- Function to clean up old notifications after job date
CREATE OR REPLACE FUNCTION cleanup_old_notifications()
RETURNS void AS $$
BEGIN
  -- Delete notifications older than the job's start date
  DELETE FROM notifications 
  WHERE notification_type = 'job_assignment'
    AND job_id IN (
      SELECT id FROM jobs 
      WHERE job_start_date < CURRENT_DATE
    );
    
  RAISE NOTICE 'Cleaned up old job assignment notifications';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 6: GRANT PERMISSIONS
-- ========================================

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION create_job_assignment_notification() TO authenticated;
GRANT EXECUTE ON FUNCTION mark_job_notifications_as_read() TO authenticated;
GRANT EXECUTE ON FUNCTION cleanup_old_notifications() TO authenticated;

-- ========================================
-- STEP 7: ADD COMMENTS FOR DOCUMENTATION
-- ========================================

COMMENT ON FUNCTION create_job_assignment_notification() IS 'Creates notifications when jobs are created with driver assignments';
COMMENT ON FUNCTION mark_job_notifications_as_read() IS 'Marks job assignment notifications as read when job is confirmed';
COMMENT ON FUNCTION cleanup_old_notifications() IS 'Cleans up old job assignment notifications after job date';
COMMENT ON TRIGGER job_assignment_notification_trigger ON jobs IS 'Triggers notification creation when job is created with driver assignment';
COMMENT ON TRIGGER job_confirmation_notification_trigger ON jobs IS 'Triggers notification read status when job is confirmed';

-- ========================================
-- STEP 8: VERIFY SETUP
-- ========================================

-- Check if triggers were created successfully
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%notification%'
ORDER BY trigger_name;

