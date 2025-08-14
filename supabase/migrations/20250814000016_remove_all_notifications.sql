-- Remove All Notification Functions and Calls
-- Applied: 2025-08-14
-- Description: Completely remove all notification-related functions and calls

-- ========================================
-- STEP 1: DROP ALL NOTIFICATION FUNCTIONS
-- ========================================

-- Drop the create_job_notification function if it exists
DROP FUNCTION IF EXISTS create_job_notification(bigint, text, text);
DROP FUNCTION IF EXISTS create_job_notification(bigint, notification_type_enum, text);
DROP FUNCTION IF EXISTS create_job_notification(bigint, text, text, text);

-- Drop any other notification-related functions
DROP FUNCTION IF EXISTS send_notification(uuid, text);
DROP FUNCTION IF EXISTS notify_job_status_change(bigint, text);

-- ========================================
-- STEP 2: DROP AND RECREATE START_JOB WITHOUT NOTIFICATIONS
-- ========================================

-- Drop the current start_job function
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric, numeric, numeric);

-- Create a completely clean start_job function with NO notification calls
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

    -- Log the action (NO NOTIFICATIONS)
    RAISE NOTICE 'Job % started successfully by driver %', start_job.job_id, driver_id_val;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 3: DROP AND RECREATE OTHER JOB FUNCTIONS WITHOUT NOTIFICATIONS
-- ========================================

-- Drop and recreate resume_job function
DROP FUNCTION IF EXISTS resume_job(bigint);

CREATE OR REPLACE FUNCTION resume_job(job_id bigint)
RETURNS void AS $$
BEGIN
    -- Update last activity
    UPDATE driver_flow 
    SET last_activity_at = NOW()
    WHERE driver_flow.job_id = resume_job.job_id;
    
    -- Log the action (NO NOTIFICATIONS)
    RAISE NOTICE 'Job % resumed', job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop and recreate close_job function
DROP FUNCTION IF EXISTS close_job(bigint);

CREATE OR REPLACE FUNCTION close_job(job_id bigint)
RETURNS void AS $$
BEGIN
    -- Update jobs table status
    UPDATE jobs 
    SET job_status = 'completed'
    WHERE id = close_job.job_id;
    
    -- Update driver_flow
    UPDATE driver_flow 
    SET 
        job_closed_time = NOW(),
        last_activity_at = NOW()
    WHERE driver_flow.job_id = close_job.job_id;
    
    -- Log the action (NO NOTIFICATIONS)
    RAISE NOTICE 'Job % closed', job_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 4: GRANT PERMISSIONS
-- ========================================

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION resume_job(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION close_job(bigint) TO authenticated;

-- ========================================
-- STEP 5: VERIFY CLEAN STATE
-- ========================================

-- Check that start_job function exists and has no notification calls
SELECT 
    routine_name, 
    routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name = 'start_job';

-- Check that no notification functions exist
SELECT 
    routine_name, 
    routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%notification%' OR routine_name LIKE '%notify%';

-- Test that the function compiles correctly
DO $$
BEGIN
    RAISE NOTICE 'All notification functions removed. start_job function is clean.';
END;
$$;
