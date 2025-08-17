-- Fix Missing Constraints Migration
-- Applied: 2025-08-17
-- Description: Adds missing unique constraints for ON CONFLICT clauses

-- 1. Add unique constraint to trip_progress table for (job_id, trip_index)
-- This is needed for the ON CONFLICT clause in start_job function
ALTER TABLE trip_progress 
ADD CONSTRAINT trip_progress_job_trip_unique 
UNIQUE (job_id, trip_index);

-- 2. Add unique constraint to driver_flow table for job_id
-- This ensures only one driver_flow record per job
ALTER TABLE driver_flow 
ADD CONSTRAINT driver_flow_job_unique 
UNIQUE (job_id);

-- 3. Verify the constraints were created
SELECT 
    tc.table_name, 
    tc.constraint_name, 
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name IN ('trip_progress', 'driver_flow')
    AND tc.constraint_type = 'UNIQUE'
ORDER BY tc.table_name, tc.constraint_name;
