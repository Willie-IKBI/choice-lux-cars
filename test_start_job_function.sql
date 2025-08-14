-- Test the start_job function to verify it sets vehicle_collected = true
-- This will help us debug why vehicle_collected remains false

-- First, let's check the current state of job 446
SELECT 
    j.id,
    j.job_number,
    j.job_status,
    j.driver_id,
    df.vehicle_collected,
    df.current_step,
    df.job_started_at,
    df.odo_start_reading,
    df.pdp_start_image
FROM jobs j
LEFT JOIN driver_flow df ON j.id = df.job_id
WHERE j.id = 446;

-- Now let's test the start_job function with job 446
-- This should set vehicle_collected = true and current_step = 'vehicle_collection'
SELECT start_job(446, 12345.0, 'test_image_url.jpg', -26.2041, 28.0473, 10.0);

-- After running the function, check the results again
SELECT 
    j.id,
    j.job_number,
    j.job_status,
    j.driver_id,
    df.vehicle_collected,
    df.current_step,
    df.job_started_at,
    df.odo_start_reading,
    df.pdp_start_image
FROM jobs j
LEFT JOIN driver_flow df ON j.id = df.job_id
WHERE j.id = 446;

-- Let's also check the function definition to make sure it's correct
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'start_job';
