-- Fix start_job function to properly progress to next step after vehicle collection
-- Applied: 2025-08-14
-- Description: Fix the start_job function to set current_step to 'pickup_arrival' after vehicle collection is completed

-- Drop and recreate the start_job function
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
DECLARE
    driver_id_val UUID;
BEGIN
    -- Get the driver_id from the jobs table
    SELECT j.driver_id INTO driver_id_val
    FROM jobs j
    WHERE j.id = start_job.job_id;
    
    -- First, ensure driver_flow record exists for this job
    INSERT INTO driver_flow (job_id, driver_user, current_step, last_activity_at)
    SELECT 
        start_job.job_id,
        driver_id_val,
        'vehicle_collection',
        NOW()
    WHERE NOT EXISTS (
        SELECT 1 FROM driver_flow df WHERE df.job_id = start_job.job_id
    );

    -- Update driver_flow table with vehicle collection data
    -- Since vehicle collection is now completed, move to next step
    UPDATE driver_flow df
    SET 
        job_started_at = NOW(),
        odo_start_reading = start_job.odo_start_reading,
        pdp_start_image = start_job.pdp_start_image,
        pickup_loc = format('POINT(%s %s)', start_job.gps_lng, start_job.gps_lat),
        vehicle_collected = true,
        vehicle_time = NOW(),
        current_step = 'pickup_arrival', -- Move to next step since vehicle collection is complete
        last_activity_at = NOW(),
        updated_at = NOW(),
        driver_user = driver_id_val
    WHERE df.job_id = start_job.job_id;

    -- Update job status to 'started'
    UPDATE jobs j
    SET 
        job_status = 'started',
        updated_at = NOW()
    WHERE j.id = start_job.job_id;

    -- Log the action
    RAISE NOTICE 'Job % started successfully by driver %. Vehicle collected: true, Current step: pickup_arrival', 
        start_job.job_id, driver_id_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) IS 'Starts a job by completing vehicle collection and moving to pickup arrival step';

-- Verify the function was created successfully
SELECT 
    routine_name, 
    routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'start_job';

DO $$
BEGIN
    RAISE NOTICE 'start_job function updated successfully. Vehicle collection completed, moving to pickup arrival step.';
END;
$$;
