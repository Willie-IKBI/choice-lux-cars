-- Fix Driver Flow updated_at Column
-- Applied: 2025-08-14
-- Description: Adds missing updated_at column to driver_flow table and fixes start_job function

-- 1. Add missing updated_at column to driver_flow table
ALTER TABLE driver_flow 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. Drop and recreate the start_job function without updated_at references
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
    -- Update driver_flow table (without updated_at for now)
    UPDATE driver_flow df
    SET 
        job_started_at = NOW(),
        odo_start_reading = start_job.odo_start_reading,
        pdp_start_image = start_job.pdp_start_image,
        pickup_loc = format('POINT(%s %s)', start_job.gps_lng, start_job.gps_lat)
    WHERE df.job_id = start_job.job_id;

    -- Update job status to 'started'
    UPDATE jobs j
    SET 
        job_status = 'started',
        updated_at = NOW()
    WHERE j.id = start_job.job_id;

    -- Log the action (optional)
    RAISE NOTICE 'Job % started successfully', job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) IS 'Starts a job by updating driver_flow and job status';
