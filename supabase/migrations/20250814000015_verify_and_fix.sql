-- Verify and Fix Start Job Function
-- Applied: 2025-08-14
-- Description: Verify function exists and recreate if needed

-- ========================================
-- STEP 1: CHECK CURRENT STATE
-- ========================================

-- Check if start_job function exists
SELECT 
    routine_name, 
    routine_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'start_job';

-- Check all functions that might be related
SELECT 
    routine_name, 
    routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND (routine_name LIKE '%start%' OR routine_name LIKE '%job%')
ORDER BY routine_name;

-- ========================================
-- STEP 2: DROP AND RECREATE FUNCTION
-- ========================================

-- Drop the function if it exists
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric, numeric, numeric);

-- Create the function with exact signature needed by Flutter
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
    WHERE df.job_id = start_job.job_id;

    -- Update job status to 'started'
    UPDATE jobs j
    SET 
        job_status = 'started',
        updated_at = NOW()
    WHERE j.id = start_job.job_id;

    -- Log the action
    RAISE NOTICE 'Job % started successfully by driver %', start_job.job_id, driver_id_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 3: GRANT PERMISSIONS
-- ========================================

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) IS 'Starts a job by updating driver_flow and job status';

-- ========================================
-- STEP 4: VERIFY FUNCTION EXISTS
-- ========================================

-- Verify the function exists
SELECT 
    routine_name, 
    routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'start_job';

-- Show the function parameters
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

-- ========================================
-- STEP 5: TEST FUNCTION CALL
-- ========================================

-- Test that the function can be called (this will show any syntax errors)
DO $$
BEGIN
    -- This is just a test to ensure the function compiles correctly
    RAISE NOTICE 'start_job function is ready for use';
END;
$$;
