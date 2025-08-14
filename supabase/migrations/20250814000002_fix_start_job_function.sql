-- Fix Start Job Function Migration
-- Applied: 2025-08-14
-- Description: Fixes start_job function without problematic notification calls

-- Drop and recreate the start_job function without notification calls
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
    SET job_status = 'started'
    WHERE j.id = start_job.job_id;
    
    -- No notification call to avoid the supabase_functions.http_request error
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;
