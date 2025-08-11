-- Fix Driver Flow Functions Migration
-- Applied: 2025-08-11
-- Description: Ensures all driver flow API functions are properly created

-- Drop existing functions to recreate them with correct signatures
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric, numeric, numeric);
DROP FUNCTION IF EXISTS resume_job(bigint);
DROP FUNCTION IF EXISTS close_job(bigint);
DROP FUNCTION IF EXISTS get_driver_current_job(uuid);
DROP FUNCTION IF EXISTS get_job_progress(bigint);
DROP FUNCTION IF EXISTS get_trip_progress(bigint);

-- 1. Function to start a job (matches Flutter app parameters exactly)
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
    -- Update driver_flow table
    UPDATE driver_flow 
    SET 
        job_started_at = NOW(),
        odo_start_reading = odo_start_reading,
        pdp_start_image = pdp_start_image,
        pickup_loc = format('POINT(%s %s)', gps_lng, gps_lat),
        current_step = 'vehicle_collection',
        last_activity_at = NOW()
    WHERE driver_flow.job_id = start_job.job_id;
    
    -- Update jobs table status
    UPDATE jobs 
    SET job_status = 'started'::job_status_enum
    WHERE id = start_job.job_id;
    
    -- Create notification for job started
    PERFORM create_job_notification(job_id, 'job_started', 
        format('Job %s has been started', job_id));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to resume a job
CREATE OR REPLACE FUNCTION resume_job(job_id bigint)
RETURNS void AS $$
BEGIN
    -- Update last activity
    UPDATE driver_flow 
    SET last_activity_at = NOW()
    WHERE driver_flow.job_id = resume_job.job_id;
    
    -- Create notification for job resumed
    PERFORM create_job_notification(job_id, 'job_started', 
        format('Job %s has been resumed', job_id));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Function to close a job
CREATE OR REPLACE FUNCTION close_job(job_id bigint)
RETURNS void AS $$
BEGIN
    -- Update jobs table status
    UPDATE jobs 
    SET job_status = 'completed'::job_status_enum
    WHERE id = close_job.job_id;
    
    -- Update driver_flow table
    UPDATE driver_flow 
    SET 
        transport_completed_ind = true,
        last_activity_at = NOW()
    WHERE driver_flow.job_id = close_job.job_id;
    
    -- Create notification for job completed
    PERFORM create_job_notification(job_id, 'job_completed', 
        format('Job %s has been completed', job_id));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Function to get driver's current job
CREATE OR REPLACE FUNCTION get_driver_current_job(driver_uuid uuid)
RETURNS TABLE (
    job_id bigint,
    current_step text,
    progress_percentage integer,
    last_activity_at timestamptz,
    total_trips integer,
    completed_trips integer
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        df.job_id,
        df.current_step,
        df.progress_percentage,
        df.last_activity_at,
        jps.total_trips,
        jps.completed_trips
    FROM driver_flow df
    LEFT JOIN job_progress_summary jps ON df.job_id = jps.job_id
    WHERE df.driver_user = driver_uuid
    AND df.job_closed_time IS NULL
    ORDER BY df.last_activity_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Function to get job progress
CREATE OR REPLACE FUNCTION get_job_progress(job_id_param bigint)
RETURNS TABLE (
    job_id bigint,
    current_step text,
    progress_percentage integer,
    total_trips integer,
    completed_trips integer,
    current_trip_index integer,
    job_status text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        jps.job_id,
        jps.current_step,
        jps.progress_percentage,
        jps.total_trips,
        jps.completed_trips,
        jps.current_trip_index,
        j.job_status::text
    FROM job_progress_summary jps
    JOIN jobs j ON jps.job_id = j.id
    WHERE jps.job_id = job_id_param;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Function to get trip progress
CREATE OR REPLACE FUNCTION get_trip_progress(job_id_param bigint)
RETURNS TABLE (
    trip_index integer,
    status text,
    pickup_arrived_at timestamptz,
    passenger_onboard_at timestamptz,
    dropoff_arrived_at timestamptz,
    completed_at timestamptz,
    pickup_gps_lat numeric,
    pickup_gps_lng numeric,
    dropoff_gps_lat numeric,
    dropoff_gps_lng numeric
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tp.trip_index,
        tp.status,
        tp.pickup_arrived_at,
        tp.passenger_onboard_at,
        tp.dropoff_arrived_at,
        tp.completed_at,
        tp.pickup_gps_lat,
        tp.pickup_gps_lng,
        tp.dropoff_gps_lat,
        tp.dropoff_gps_lng
    FROM trip_progress tp
    WHERE tp.job_id = job_id_param
    ORDER BY tp.trip_index;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permissions on all functions
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION resume_job(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION close_job(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION get_driver_current_job(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_job_progress(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION get_trip_progress(bigint) TO authenticated;
