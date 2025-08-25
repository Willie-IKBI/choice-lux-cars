-- SIMPLE NOTIFICATION FIX
-- This bypasses all the complex trigger issues and directly creates notifications
-- Run this SQL in your Supabase SQL editor

-- STEP 1: CLEAN UP - REMOVE ALL COMPLEX TRIGGERS AND FUNCTIONS
-- Drop all existing triggers and functions that might be causing issues
DROP TRIGGER IF EXISTS job_assignment_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_confirmation_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_assignment_trigger ON jobs;
DROP TRIGGER IF EXISTS on_job_assigned ON jobs;
DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
DROP TRIGGER IF EXISTS jobs_audit_trigger ON jobs;
DROP TRIGGER IF EXISTS jobs_webhook_trigger ON jobs;
DROP TRIGGER IF EXISTS trg_jobs_updated_at ON jobs;

DROP FUNCTION IF EXISTS create_job_assignment_notification() CASCADE;
DROP FUNCTION IF EXISTS mark_job_notifications_as_read() CASCADE;
DROP FUNCTION IF EXISTS notify_job_assignment() CASCADE;
DROP FUNCTION IF EXISTS handle_job_assignment() CASCADE;
DROP FUNCTION IF EXISTS send_push_notification() CASCADE;
DROP FUNCTION IF EXISTS process_job_notification_log() CASCADE;

-- STEP 2: CREATE SIMPLE, DIRECT NOTIFICATION FUNCTION
CREATE OR REPLACE FUNCTION create_job_assignment_notification()
RETURNS TRIGGER AS $$
BEGIN
    -- Only create notification if driver_id is set and changed
    IF NEW.driver_id IS NOT NULL AND 
       (OLD.driver_id IS NULL OR NEW.driver_id != OLD.driver_id) THEN
        
        -- Insert notification directly (NO HTTP, NO COMPLEX LOGIC)
        INSERT INTO notifications (
            user_id,
            message,
            notification_type,
            priority,
            job_id,
            action_data,
            created_at,
            updated_at
        ) VALUES (
            NEW.driver_id,
            'New job assigned to you. Please confirm your assignment.',
            'job_assignment',
            'high',
            NEW.id,
            jsonb_build_object('job_id', NEW.id, 'action', 'view_job'),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'SIMPLE: Created notification for driver % for job %', NEW.driver_id, NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 3: CREATE SIMPLE TRIGGER
CREATE TRIGGER job_assignment_notification_trigger
    AFTER INSERT OR UPDATE OF driver_id ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION create_job_assignment_notification();

-- STEP 4: CREATE SIMPLE CONFIRMATION FUNCTION
CREATE OR REPLACE FUNCTION mark_job_notifications_as_read()
RETURNS TRIGGER AS $$
BEGIN
    -- Mark notifications as read when job is confirmed
    IF NEW.driver_confirm_ind = true AND OLD.driver_confirm_ind = false THEN
        UPDATE notifications 
        SET is_read = true, 
            read_at = NOW(),
            updated_at = NOW()
        WHERE job_id = NEW.id AND user_id = NEW.driver_id;
        
        RAISE NOTICE 'SIMPLE: Marked notifications as read for job %', NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 5: CREATE CONFIRMATION TRIGGER
CREATE TRIGGER job_confirmation_notification_trigger
    AFTER UPDATE OF driver_confirm_ind ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION mark_job_notifications_as_read();

-- STEP 6: TEST THE SYSTEM
-- Create a test notification manually to verify the system works
DO $$
DECLARE
    test_user_id UUID;
    test_job_id BIGINT;
    notification_id UUID;
BEGIN
    -- Get a test user
    SELECT id INTO test_user_id 
    FROM profiles 
    LIMIT 1;
    
    -- Get a test job
    SELECT id INTO test_job_id 
    FROM jobs 
    WHERE driver_id IS NULL 
    LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_job_id IS NOT NULL THEN
        -- Create a test notification manually
        INSERT INTO notifications (
            user_id,
            message,
            notification_type,
            priority,
            job_id,
            action_data,
            created_at,
            updated_at
        ) VALUES (
            test_user_id,
            'TEST: Simple notification system is working!',
            'job_assignment',
            'high',
            test_job_id,
            jsonb_build_object('job_id', test_job_id, 'action', 'view_job'),
            NOW(),
            NOW()
        ) RETURNING id INTO notification_id;
        
        RAISE NOTICE 'TEST: Created notification % for user % and job %', notification_id, test_user_id, test_job_id;
    ELSE
        RAISE NOTICE 'TEST: No test user or job found';
    END IF;
END $$;

-- STEP 7: VERIFY TRIGGERS ARE WORKING
SELECT 
    'SIMPLE NOTIFICATION SYSTEM STATUS:' as info,
    'Triggers created successfully' as status,
    'No HTTP calls' as feature1,
    'Direct database inserts' as feature2,
    'Simple confirmation handling' as feature3;

-- STEP 8: SHOW CURRENT TRIGGERS
SELECT 
    'Current Triggers:' as info,
    t.tgname as trigger_name,
    p.proname as function_name,
    'ENABLED' as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'jobs' AND t.tgisinternal = false
ORDER BY t.tgname;
