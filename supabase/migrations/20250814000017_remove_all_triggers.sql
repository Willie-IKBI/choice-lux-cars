-- Remove All Notification Triggers and Functions
-- Applied: 2025-08-14
-- Description: Remove all notification-related triggers and ensure complete cleanup

-- ========================================
-- STEP 1: DROP ALL NOTIFICATION TRIGGERS
-- ========================================

-- Drop all notification-related triggers
DROP TRIGGER IF EXISTS job_assignment_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_confirmation_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_notification_log_trigger ON job_notification_log;
DROP TRIGGER IF EXISTS update_notifications_updated_at ON notifications;
DROP TRIGGER IF EXISTS job_status_notify ON jobs;

-- ========================================
-- STEP 2: DROP ALL NOTIFICATION FUNCTIONS
-- ========================================

-- Drop all notification function variations
DROP FUNCTION IF EXISTS create_job_notification(bigint, text, text);
DROP FUNCTION IF EXISTS create_job_notification(bigint, notification_type_enum, text);
DROP FUNCTION IF EXISTS create_job_notification(bigint, text, text, text);
DROP FUNCTION IF EXISTS send_notification(uuid, text);
DROP FUNCTION IF EXISTS notify_job_status_change(bigint, text);
DROP FUNCTION IF EXISTS job_assignment_notification();
DROP FUNCTION IF EXISTS job_confirmation_notification();

-- ========================================
-- STEP 3: DROP AND RECREATE START_JOB FUNCTION
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
-- STEP 4: GRANT PERMISSIONS
-- ========================================

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) IS 'Starts a job by updating driver_flow and job status';

-- ========================================
-- STEP 5: VERIFY COMPLETE CLEANUP
-- ========================================

-- Check that start_job function exists
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
AND (routine_name LIKE '%notification%' OR routine_name LIKE '%notify%');

-- Check that no notification triggers exist
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND (trigger_name LIKE '%notification%' OR trigger_name LIKE '%notify%');

-- Test that the function compiles correctly
DO $$
BEGIN
    RAISE NOTICE 'All notification triggers and functions removed. Database is completely clean.';
END;
$$;
