-- Create notification log table for job assignments
CREATE TABLE IF NOT EXISTS job_notification_log (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_id bigint NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  is_reassignment BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  processed_at TIMESTAMP WITH TIME ZONE,
  status TEXT DEFAULT 'pending'
);

-- Create function to handle job assignment notifications
CREATE OR REPLACE FUNCTION handle_job_assignment()
RETURNS TRIGGER AS $$
BEGIN
  -- Only trigger if driver_id is set and changed
  IF NEW.driver_id IS NOT NULL AND 
     (OLD.driver_id IS NULL OR OLD.driver_id != NEW.driver_id) THEN
    
    -- Log the job assignment for notification processing
    INSERT INTO job_notification_log (
      job_id,
      driver_id,
      is_reassignment
    ) VALUES (
      NEW.id,
      NEW.driver_id,
      OLD.driver_id IS NOT NULL
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on jobs table
DROP TRIGGER IF EXISTS job_assignment_trigger ON jobs;
CREATE TRIGGER job_assignment_trigger
  AFTER INSERT OR UPDATE ON jobs
  FOR EACH ROW
  EXECUTE FUNCTION handle_job_assignment();

-- Create RLS policies for job confirmation
-- Only assigned driver can confirm their job
DROP POLICY IF EXISTS "Driver can confirm their job only" ON jobs;
CREATE POLICY "Driver can confirm their job only" ON jobs
FOR UPDATE USING (auth.uid() = driver_id)
WITH CHECK (driver_confirm_ind = TRUE);

-- Only admins/managers can assign drivers
DROP POLICY IF EXISTS "Only admins can assign drivers" ON jobs;
CREATE POLICY "Only admins can assign drivers" ON jobs
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND role IN ('administrator', 'manager')
  )
);

-- Create index for notification processing
CREATE INDEX IF NOT EXISTS idx_job_notification_log_pending 
ON job_notification_log(status, created_at) 
WHERE status = 'pending'; 