-- Fix Job ID Ambiguity Migration
-- Applied: 2025-08-17
-- Description: Fixes ambiguous job_id references in start_job function

-- Fix the start_job function to resolve job_id ambiguity
CREATE OR REPLACE FUNCTION start_job(
    job_id bigint,
    odo_start_reading numeric DEFAULT NULL,
    pdp_start_image text DEFAULT NULL,
    gps_lat numeric DEFAULT NULL,
    gps_lng numeric DEFAULT NULL,
    gps_accuracy numeric DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    driver_uuid uuid;
BEGIN
    -- Get the driver for this job (fix: qualify job_id with function name)
    SELECT driver_id INTO driver_uuid FROM jobs WHERE id = start_job.job_id;
    
    IF driver_uuid IS NULL THEN
        RAISE EXCEPTION 'No driver assigned to job %', start_job.job_id;
    END IF;
    
    -- Ensure driver_flow record exists (fix: qualify job_id with function name)
    PERFORM ensure_driver_flow_record(start_job.job_id, driver_uuid);
    
    -- Update job status to started (fix: qualify job_id with function name)
    UPDATE jobs 
    SET job_status = 'started'
    WHERE id = start_job.job_id;
    
    -- Update driver_flow with start details (this one was already correct)
    UPDATE driver_flow 
    SET 
        job_started_at = NOW(),
        odo_start_reading = COALESCE(start_job.odo_start_reading, odo_start_reading),
        pdp_start_image = COALESCE(start_job.pdp_start_image, pdp_start_image),
        pickup_loc = CASE 
            WHEN start_job.gps_lat IS NOT NULL AND start_job.gps_lng IS NOT NULL 
            THEN format('POINT(%s %s)', start_job.gps_lng, start_job.gps_lat)
            ELSE pickup_loc 
        END,
        vehicle_collected = true,
        vehicle_collected_at = NOW(),
        current_step = 'pickup_arrival',
        progress_percentage = 20,
        last_activity_at = NOW()
    WHERE job_id = start_job.job_id;
    
    -- Create initial trip_progress record if none exists (fix: qualify job_id with function name)
    INSERT INTO trip_progress (job_id, trip_index, status)
    VALUES (start_job.job_id, 1, 'pending')
    ON CONFLICT (job_id, trip_index) DO NOTHING;
    
END;
$$ LANGUAGE plpgsql;
