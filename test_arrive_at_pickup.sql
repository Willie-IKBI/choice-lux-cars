-- Test script to check arrive_at_pickup function
-- Run this in Supabase SQL Editor

-- Check if function exists
SELECT 
    routine_name, 
    routine_type,
    specific_name,
    data_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'arrive_at_pickup'
ORDER BY specific_name;

-- Check if we have any jobs to test with
SELECT 
    id,
    job_status,
    driver_id
FROM jobs 
WHERE job_status = 'started' 
LIMIT 5;

-- Check if we have any driver_flow records
SELECT 
    job_id,
    current_step,
    driver_user
FROM driver_flow 
LIMIT 5;

-- Check if we have any trip_progress records
SELECT 
    job_id,
    trip_index,
    status
FROM trip_progress 
LIMIT 5;
