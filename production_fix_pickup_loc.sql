-- Production Fix for Driver Flow pickup_loc Column Issue
-- Run this in your Supabase Dashboard SQL Editor
-- This fixes the "column pickup_loc of relation driver_flow does not exist" error

-- 1. Add the missing pickup_loc column to driver_flow table
ALTER TABLE driver_flow 
ADD COLUMN IF NOT EXISTS pickup_loc TEXT;

-- 2. Drop and recreate the start_job function with correct column reference
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
        last_activity_at = NOW()
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

-- Grant execute permission
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;

-- 3. Verify the column exists
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'driver_flow' AND column_name = 'pickup_loc';

-- 4. Show current driver_flow table structure
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'driver_flow'
ORDER BY ordinal_position;
