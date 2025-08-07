-- Fix the notification trigger to directly create notifications
-- This bypasses the Edge Function dependency

-- Drop the existing trigger and function
DROP TRIGGER IF EXISTS job_assignment_notification_trigger ON jobs;
DROP FUNCTION IF EXISTS create_job_assignment_notification();

-- Create a new function that directly creates notifications
CREATE OR REPLACE FUNCTION create_job_assignment_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create notification if driver_id is set and changed, and job is not confirmed
  IF NEW.driver_id IS NOT NULL AND 
     (OLD.driver_id IS NULL OR NEW.driver_id != OLD.driver_id) AND 
     NOT NEW.is_confirmed THEN
    
    -- Insert directly into notifications table
    INSERT INTO notifications (
      user_id,
      job_id,
      body,
      notification_type,
      is_read
    ) VALUES (
      NEW.driver_id,
      NEW.id,
      CASE 
        WHEN OLD.driver_id IS NOT NULL THEN 'Job reassigned to you. Please confirm your job in the app.'
        ELSE 'New job assigned. Please confirm your job in the app.'
      END,
      'job_assignment',
      false
    );
    
    -- Also insert into job_notification_log for FCM processing (optional)
    INSERT INTO job_notification_log (
      job_id,
      driver_id,
      is_reassignment,
      status
    ) VALUES (
      NEW.id,
      NEW.driver_id,
      OLD.driver_id IS NOT NULL, -- True if driver_id changed from non-null to new value
      'pending'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for job assignment (both INSERT and UPDATE)
CREATE TRIGGER job_assignment_notification_trigger
  AFTER INSERT OR UPDATE OF driver_id ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION create_job_assignment_notification();

-- Process existing pending notifications manually
INSERT INTO notifications (
  user_id,
  job_id,
  body,
  notification_type,
  is_read
)
SELECT 
  jnl.driver_id,
  jnl.job_id,
  CASE 
    WHEN jnl.is_reassignment THEN 'Job reassigned to you. Please confirm your job in the app.'
    ELSE 'New job assigned. Please confirm your job in the app.'
  END,
  'job_assignment',
  false
FROM job_notification_log jnl
WHERE jnl.status = 'pending'
  AND jnl.processed_at IS NULL
  AND NOT EXISTS (
    SELECT 1 FROM notifications n 
    WHERE n.job_id = jnl.job_id 
    AND n.user_id = jnl.driver_id
    AND n.notification_type = 'job_assignment'
  );

-- Mark the processed notifications as processed
UPDATE job_notification_log 
SET status = 'processed', processed_at = NOW()
WHERE status = 'pending' AND processed_at IS NULL; 