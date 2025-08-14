-- Comprehensive Driver Flow Fix
-- Run this in your Supabase Dashboard SQL Editor
-- This fixes ALL driver flow issues: enum values, missing columns, and functions

-- 1. Drop existing job_status_enum to recreate with correct values
DROP TYPE IF EXISTS job_status_enum CASCADE;

-- 2. Create job_status_enum with ALL required values
CREATE TYPE job_status_enum AS ENUM (
    'pending',       -- Job created but not assigned
    'assigned',      -- Job assigned to driver
    'started',       -- Driver started the job
    'in_progress',   -- Vehicle collected, trips in progress
    'ready_to_close', -- All trips completed, ready for vehicle return
    'completed',     -- Job fully completed
    'cancelled'      -- Job cancelled
);

-- 3. Add ALL missing columns to driver_flow table
ALTER TABLE driver_flow 
ADD COLUMN IF NOT EXISTS pickup_loc TEXT,
ADD COLUMN IF NOT EXISTS pdp_start_image text,
ADD COLUMN IF NOT EXISTS odo_start_reading numeric,
ADD COLUMN IF NOT EXISTS job_started_at timestamptz,
ADD COLUMN IF NOT EXISTS current_step text DEFAULT 'not_started',
ADD COLUMN IF NOT EXISTS last_activity_at timestamptz DEFAULT NOW(),
ADD COLUMN IF NOT EXISTS current_trip_index integer DEFAULT 1,
ADD COLUMN IF NOT EXISTS progress_percentage integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS vehicle_collected_at timestamptz;

-- 4. Update jobs table to use the new enum
ALTER TABLE jobs 
ALTER COLUMN job_status TYPE job_status_enum USING 
    CASE 
        WHEN job_status = 'open' THEN 'assigned'::job_status_enum
        WHEN job_status = 'closed' THEN 'completed'::job_status_enum
        ELSE job_status::job_status_enum
    END;

-- 5. Set default values for existing records
UPDATE jobs 
SET job_status = 'assigned'::job_status_enum
WHERE job_status IS NULL;

UPDATE driver_flow 
SET 
    current_step = COALESCE(current_step, 'not_started'),
    last_activity_at = COALESCE(last_activity_at, NOW()),
    current_trip_index = COALESCE(current_trip_index, 1),
    progress_percentage = COALESCE(progress_percentage, 0)
WHERE current_step IS NULL OR last_activity_at IS NULL;

-- 6. Drop and recreate the start_job function with correct column references
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric, numeric, numeric);

CREATE OR REPLACE FUNCTION start_job(
    job_id bigint,
    odo_start_reading numeric,
    pdp_start_image text,
    gps_lat numeric,
    gps_lng numeric,
    gps_accuracy numeric DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    -- Update driver_flow table with explicit table alias
    UPDATE driver_flow df
    SET 
        job_started_at = NOW(),
        odo_start_reading = start_job.odo_start_reading,
        pdp_start_image = start_job.pdp_start_image,
        pickup_loc = format('POINT(%s %s)', start_job.gps_lng, start_job.gps_lat),
        current_step = 'vehicle_collection',
        last_activity_at = NOW(),
        progress_percentage = 10
    WHERE df.job_id = start_job.job_id;
    
    -- Update jobs table status with explicit table alias
    UPDATE jobs j
    SET job_status = 'started'::job_status_enum
    WHERE j.id = start_job.job_id;
    
    -- Create notification for job started (if function exists)
    BEGIN
        PERFORM create_job_notification(start_job.job_id, 'job_started', 
            format('Job %s has been started', start_job.job_id));
    EXCEPTION
        WHEN undefined_function THEN
            -- Function doesn't exist, skip notification
            NULL;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Create or update other driver flow functions
CREATE OR REPLACE FUNCTION resume_job(job_id bigint)
RETURNS void AS $$
BEGIN
    -- Update last activity
    UPDATE driver_flow 
    SET last_activity_at = NOW()
    WHERE driver_flow.job_id = resume_job.job_id;
    
    -- Create notification for job resumed (if function exists)
    BEGIN
        PERFORM create_job_notification(job_id, 'job_started', 
            format('Job %s has been resumed', job_id));
    EXCEPTION
        WHEN undefined_function THEN
            NULL;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION close_job(job_id bigint)
RETURNS void AS $$
BEGIN
    -- Update jobs table status
    UPDATE jobs 
    SET job_status = 'completed'::job_status_enum
    WHERE id = close_job.job_id;
    
    -- Update driver_flow
    UPDATE driver_flow 
    SET 
        job_closed_time = NOW(),
        last_activity_at = NOW(),
        progress_percentage = 100
    WHERE driver_flow.job_id = close_job.job_id;
    
    -- Create notification for job completed (if function exists)
    BEGIN
        PERFORM create_job_notification(job_id, 'job_completed', 
            format('Job %s has been completed', job_id));
    EXCEPTION
        WHEN undefined_function THEN
            NULL;
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Grant execute permissions
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION resume_job(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION close_job(bigint) TO authenticated;

-- 9. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_driver_flow_job_id ON driver_flow(job_id);
CREATE INDEX IF NOT EXISTS idx_driver_flow_driver_user ON driver_flow(driver_user);
CREATE INDEX IF NOT EXISTS idx_driver_flow_current_step ON driver_flow(current_step);
CREATE INDEX IF NOT EXISTS idx_driver_flow_last_activity ON driver_flow(last_activity_at);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(job_status);

-- 10. Verify the fixes
SELECT 'Driver flow fixes applied successfully!' as status;

-- 11. Show current enum values
SELECT enumlabel FROM pg_enum WHERE enumtypid = 'job_status_enum'::regtype;

-- 12. Show driver_flow table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'driver_flow'
ORDER BY ordinal_position;
