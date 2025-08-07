-- Function to create notification when job is assigned
CREATE OR REPLACE FUNCTION create_job_assignment_notification()
RETURNS TRIGGER AS $$
BEGIN
  -- Only create notification if driver_id is set and changed, and job is not confirmed
  IF NEW.driver_id IS NOT NULL AND 
     (OLD.driver_id IS NULL OR NEW.driver_id != OLD.driver_id) AND 
     NOT NEW.is_confirmed THEN
    
    -- Insert into job_notification_log to trigger the Edge Function
    INSERT INTO job_notification_log (
      job_id,
      driver_id,
      is_reassignment
    ) VALUES (
      NEW.id,
      NEW.driver_id,
      OLD.driver_id IS NOT NULL -- True if driver_id changed from non-null to new value
    );
    
    -- Call the Edge Function to process the notification
    PERFORM net.http_post(
      url := 'https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/process-job-notifications',
      headers := '{"Content-Type": "application/json", "Authorization": "Bearer ' || current_setting('app.settings.service_role_key') || '"}',
      body := '{}'
    );
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for job assignment
DROP TRIGGER IF EXISTS job_assignment_notification_trigger ON jobs;
CREATE TRIGGER job_assignment_notification_trigger
  AFTER INSERT OR UPDATE OF driver_id ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION create_job_assignment_notification();

-- Function to mark notifications as read when job is confirmed
CREATE OR REPLACE FUNCTION mark_job_notifications_as_read()
RETURNS TRIGGER AS $$
BEGIN
  -- Mark all notifications for this job as read when job is confirmed
  IF NEW.is_confirmed AND NOT OLD.is_confirmed THEN
    UPDATE notifications 
    SET is_read = true, updated_at = NOW()
    WHERE job_id = NEW.id AND is_read = false;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for job confirmation
DROP TRIGGER IF EXISTS job_confirmation_notification_trigger ON jobs;
CREATE TRIGGER job_confirmation_notification_trigger
  AFTER UPDATE OF is_confirmed ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION mark_job_notifications_as_read(); 