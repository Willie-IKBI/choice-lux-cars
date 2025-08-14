-- Test the start_job function
-- This will help us verify that the function is working correctly

-- First, let's check if we have any jobs in the system
SELECT 
    j.id,
    j.job_number,
    j.job_status,
    j.driver_id,
    df.vehicle_collected,
    df.current_step,
    df.job_started_at
FROM jobs j
LEFT JOIN driver_flow df ON j.id = df.job_id
WHERE j.driver_id IS NOT NULL
LIMIT 5;

-- Now let's test the start_job function with a sample job
-- Replace 446 with an actual job ID from your system
-- SELECT start_job(446, 12345.0, 'test_image_url.jpg', -26.2041, 28.0473, 10.0);

-- After running the function, check the results
-- SELECT 
--     j.id,
--     j.job_number,
--     j.job_status,
--     j.driver_id,
--     df.vehicle_collected,
--     df.current_step,
--     df.job_started_at,
--     df.odo_start_reading,
--     df.pdp_start_image
-- FROM jobs j
-- LEFT JOIN driver_flow df ON j.id = df.job_id
-- WHERE j.id = 446;
