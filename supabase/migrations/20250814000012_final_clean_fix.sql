-- Final Clean Fix for Driver Flow
-- Applied: 2025-08-14
-- Description: Complete fix for start_job function and driver_flow table

-- 1. Add the missing driver_user column to driver_flow table
ALTER TABLE driver_flow 
ADD COLUMN IF NOT EXISTS driver_user UUID REFERENCES profiles(id);

-- 2. Drop ALL existing start_job function variations to ensure clean slate
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric, numeric, numeric);
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric, numeric);
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric);
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text);
DROP FUNCTION IF EXISTS start_job(bigint, numeric);
DROP FUNCTION IF EXISTS start_job(bigint);

-- 3. Create the clean start_job function with exact signature needed by Flutter
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
    WHERE j.id = job_id;
    
    -- First, ensure driver_flow record exists for this job
    INSERT INTO driver_flow (job_id, driver_user, current_step, last_activity_at)
    SELECT 
        job_id,
        driver_id_val,
        'vehicle_collection',
        NOW()
    WHERE NOT EXISTS (
        SELECT 1 FROM driver_flow df WHERE df.job_id = job_id
    );

    -- Update driver_flow table with all the data
    UPDATE driver_flow df
    SET 
        job_started_at = NOW(),
        odo_start_reading = start_job.odo_start_reading,
        pdp_start_image = start_job.pdp_start_image,
        pickup_loc = format('POINT(%s %s)', start_job.gps_lng, start_job.gps_lat),
        current_step = 'vehicle_collection',
        last_activity_at = NOW(),
        updated_at = NOW(),
        driver_user = driver_id_val
    WHERE df.job_id = job_id;

    -- Update job status to 'started'
    UPDATE jobs j
    SET 
        job_status = 'started',
        updated_at = NOW()
    WHERE j.id = job_id;

    -- Log the action
    RAISE NOTICE 'Job % started successfully by driver %', job_id, driver_id_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;

-- 5. Add comment for documentation
COMMENT ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) IS 'Starts a job by updating driver_flow and job status';

-- 6. Create index for better performance
CREATE INDEX IF NOT EXISTS idx_driver_flow_driver_user ON driver_flow(driver_user);
CREATE INDEX IF NOT EXISTS idx_driver_flow_job_id ON driver_flow(job_id);

-- 7. Verify the function exists and show its signature
SELECT 
    routine_name, 
    routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'start_job';

-- 8. Show the function parameters
SELECT 
    parameter_name,
    data_type,
    parameter_mode,
    parameter_default,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_schema = 'public' 
AND specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_schema = 'public' 
    AND routine_name = 'start_job'
)
ORDER BY ordinal_position;

-- 9. Show the final driver_flow table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'driver_flow'
ORDER BY ordinal_position;
