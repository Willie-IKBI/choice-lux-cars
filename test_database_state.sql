-- Test the current database state
-- This will help us understand if the start_job function is actually updating the database

-- 1. Check if start_job function exists
SELECT 
    routine_name, 
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'start_job';

-- 2. Check the driver_flow table structure
SELECT 
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'driver_flow' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. Check if there are any existing jobs
SELECT 
    id,
    job_number,
    job_status,
    driver_id
FROM jobs 
LIMIT 5;

-- 4. Check if there are any existing driver_flow records
SELECT 
    job_id,
    driver_user,
    current_step,
    vehicle_collected,
    job_started_at,
    last_activity_at
FROM driver_flow 
LIMIT 5;

-- 5. Test the start_job function with a sample job (if any exist)
-- First, let's see if we have any jobs to test with
SELECT 
    'Available jobs for testing:' as info,
    COUNT(*) as job_count
FROM jobs;

-- If there are jobs, we can test the function
-- (This will be commented out to avoid accidental execution)
/*
-- Test with job ID 1 (if it exists)
SELECT start_job(1, 1000.0, 'test_image.jpg', -26.20227, 28.04363, 5.0);

-- Check the result
SELECT 
    job_id,
    driver_user,
    current_step,
    vehicle_collected,
    job_started_at,
    last_activity_at
FROM driver_flow 
WHERE job_id = 1;
*/
