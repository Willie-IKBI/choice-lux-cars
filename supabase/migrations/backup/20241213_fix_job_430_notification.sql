-- Manually create notification for job 430
INSERT INTO notifications (
  user_id,
  job_id,
  body,
  notification_type,
  is_read
) 
SELECT 
  driver_id,
  job_id,
  CASE 
    WHEN is_reassignment THEN 'Job reassigned to you. Please confirm your job in the app.'
    ELSE 'New job assigned. Please confirm your job in the app.'
  END,
  'job_assignment',
  false
FROM job_notification_log 
WHERE job_id = 430 AND status = 'pending';

-- Mark job 430 as processed
UPDATE job_notification_log 
SET status = 'processed', 
    processed_at = NOW()
WHERE job_id = 430 AND status = 'pending';

-- Verify the trigger exists and recreate it if needed
DROP TRIGGER IF EXISTS job_assignment_notification_trigger ON jobs;

-- Recreate the trigger function
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
    
    -- Also insert into job_notification_log for FCM processing
    INSERT INTO job_notification_log (
      job_id,
      driver_id,
      is_reassignment
    ) VALUES (
      NEW.id,
      NEW.driver_id,
      OLD.driver_id IS NOT NULL -- True if driver_id changed from non-null to new value
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
CREATE TRIGGER job_assignment_notification_trigger
  AFTER INSERT OR UPDATE OF driver_id ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION create_job_assignment_notification(); 