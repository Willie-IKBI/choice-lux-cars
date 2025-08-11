-- Add Missing Driver Flow Columns
-- Applied: 2025-08-11
-- Description: Adds missing columns to driver_flow table for start_job function

-- Add missing columns to driver_flow table
ALTER TABLE driver_flow 
ADD COLUMN IF NOT EXISTS pdp_start_image text,
ADD COLUMN IF NOT EXISTS odo_start_reading numeric,
ADD COLUMN IF NOT EXISTS job_started_at timestamptz,
ADD COLUMN IF NOT EXISTS current_step text DEFAULT 'not_started',
ADD COLUMN IF NOT EXISTS last_activity_at timestamptz DEFAULT NOW();

-- Add missing columns to jobs table if they don't exist
ALTER TABLE jobs 
ADD COLUMN IF NOT EXISTS job_status job_status_enum DEFAULT 'pending';

-- Create job_status_enum if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_status_enum') THEN
        CREATE TYPE job_status_enum AS ENUM ('pending', 'started', 'in_progress', 'completed', 'cancelled');
    END IF;
END $$;

-- Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_driver_flow_job_id ON driver_flow(job_id);
CREATE INDEX IF NOT EXISTS idx_driver_flow_driver_user ON driver_flow(driver_user);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(job_status);

-- Update existing records to have default values
UPDATE driver_flow 
SET 
    current_step = COALESCE(current_step, 'not_started'),
    last_activity_at = COALESCE(last_activity_at, NOW())
WHERE current_step IS NULL OR last_activity_at IS NULL;

UPDATE jobs 
SET job_status = COALESCE(job_status, 'pending')
WHERE job_status IS NULL;
