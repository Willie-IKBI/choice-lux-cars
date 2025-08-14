-- Debug script to check vehicle_collected field state
-- This will help us understand why vehicle_collected remains false

-- Check the current state of job 446
SELECT 
    j.id,
    j.job_number,
    j.job_status,
    j.driver_id,
    df.vehicle_collected,
    df.current_step,
    df.job_started_at,
    df.odo_start_reading,
    df.pdp_start_image,
    df.vehicle_time,
    df.vehicle_collected_at
FROM jobs j
LEFT JOIN driver_flow df ON j.id = df.job_id
WHERE j.id = 446;

-- Check the start_job function definition
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'start_job';

-- Test the start_job function manually
-- This should set vehicle_collected = true
SELECT start_job(446, 12345.0, 'test_image_url.jpg', -26.2041, 28.0473, 10.0);

-- Check the state again after running the function
SELECT 
    j.id,
    j.job_number,
    j.job_status,
    j.driver_id,
    df.vehicle_collected,
    df.current_step,
    df.job_started_at,
    df.odo_start_reading,
    df.pdp_start_image,
    df.vehicle_time,
    df.vehicle_collected_at
FROM jobs j
LEFT JOIN driver_flow df ON j.id = df.job_id
WHERE j.id = 446;
