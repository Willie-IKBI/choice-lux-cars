-- Simple Driver Flow Fix Migration
-- Applied: 2025-08-14
-- Description: Fixes driver flow issues without breaking view dependencies

-- 1. Drop and recreate the start_job function with correct column references
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

-- 2. Create or update other driver flow functions
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
    SET job_status = 'completed'
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

-- 3. Grant execute permissions
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION resume_job(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION close_job(bigint) TO authenticated;
