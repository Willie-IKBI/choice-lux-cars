-- Fix Driver Flow Consistency Migration
-- Applied: 2025-08-15
-- Description: Fixes inconsistencies in driver_flow table and ensures proper step progression

-- 1. Standardize current_step default value
ALTER TABLE driver_flow ALTER COLUMN current_step SET DEFAULT 'vehicle_collection';

-- 2. Update any existing records with 'not_started' to 'vehicle_collection'
UPDATE driver_flow 
SET current_step = 'vehicle_collection' 
WHERE current_step = 'not_started' OR current_step IS NULL;

-- 3. Ensure job status defaults are consistent
ALTER TABLE jobs ALTER COLUMN job_status SET DEFAULT 'assigned';

-- 4. Update any jobs with inconsistent status values
UPDATE jobs 
SET job_status = 'assigned' 
WHERE job_status = 'open' OR job_status = 'pending';

-- 5. Create a function to ensure driver_flow record exists when job starts
CREATE OR REPLACE FUNCTION ensure_driver_flow_record(p_job_id bigint, p_driver_id uuid)
RETURNS void AS $$
BEGIN
    INSERT INTO driver_flow (job_id, driver_user, current_step, current_trip_index, progress_percentage)
    VALUES (p_job_id, p_driver_id, 'vehicle_collection', 1, 0)
    ON CONFLICT (job_id) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 6. Update start_job function to ensure proper step progression
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
    -- Get the driver for this job
    SELECT driver_id INTO driver_uuid FROM jobs WHERE id = job_id;
    
    IF driver_uuid IS NULL THEN
        RAISE EXCEPTION 'No driver assigned to job %', job_id;
    END IF;
    
    -- Ensure driver_flow record exists
    PERFORM ensure_driver_flow_record(job_id, driver_uuid);
    
    -- Update job status to started
    UPDATE jobs 
    SET job_status = 'started'
    WHERE id = job_id;
    
    -- Update driver_flow with start details
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
    
    -- Create initial trip_progress record if none exists
    INSERT INTO trip_progress (job_id, trip_index, status)
    VALUES (job_id, 1, 'pending')
    ON CONFLICT (job_id, trip_index) DO NOTHING;
    
END;
$$ LANGUAGE plpgsql;
