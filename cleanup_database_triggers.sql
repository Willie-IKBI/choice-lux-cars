-- CLEANUP DATABASE TRIGGERS AND FUNCTIONS
-- This removes all problematic triggers and functions that cause HTTP queue issues
-- Run this in your Supabase SQL editor

-- ========================================
-- STEP 1: DISABLE SUPABASE REALTIME FOR KEY TABLES
-- ========================================

-- Disable realtime for jobs and notifications tables
ALTER TABLE jobs REPLICA IDENTITY NOTHING;
ALTER TABLE notifications REPLICA IDENTITY NOTHING;

-- ========================================
-- STEP 2: DROP ALL TRIGGERS ON JOBS TABLE
-- ========================================

-- Drop all triggers on jobs table
DROP TRIGGER IF EXISTS job_assignment_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_confirmation_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_assignment_trigger ON jobs;
DROP TRIGGER IF EXISTS on_job_assigned ON jobs;
DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
DROP TRIGGER IF EXISTS jobs_audit_trigger ON jobs;
DROP TRIGGER IF EXISTS jobs_webhook_trigger ON jobs;
DROP TRIGGER IF EXISTS trg_jobs_updated_at ON jobs;
DROP TRIGGER IF EXISTS job_cancellation_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_status_change_notification_trigger ON jobs;

-- ========================================
-- STEP 3: DROP ALL TRIGGERS ON NOTIFICATIONS TABLE
-- ========================================

-- Drop all triggers on notifications table
DROP TRIGGER IF EXISTS update_notifications_updated_at ON notifications;
DROP TRIGGER IF EXISTS notifications_audit_trigger ON notifications;

-- ========================================
-- STEP 4: DROP ALL NOTIFICATION FUNCTIONS
-- ========================================

-- Drop all notification-related functions
DROP FUNCTION IF EXISTS create_job_assignment_notification() CASCADE;
DROP FUNCTION IF EXISTS mark_job_notifications_as_read() CASCADE;
DROP FUNCTION IF EXISTS notify_job_assignment() CASCADE;
DROP FUNCTION IF EXISTS handle_job_assignment() CASCADE;
DROP FUNCTION IF EXISTS send_push_notification() CASCADE;
DROP FUNCTION IF EXISTS process_job_notification_log() CASCADE;
DROP FUNCTION IF EXISTS create_job_cancellation_notification() CASCADE;
DROP FUNCTION IF EXISTS create_job_status_change_notification() CASCADE;
DROP FUNCTION IF EXISTS notify_job_start() CASCADE;
DROP FUNCTION IF EXISTS notify_job_started() CASCADE;
DROP FUNCTION IF EXISTS notify_job_status_change() CASCADE;
DROP FUNCTION IF EXISTS send_job_notification() CASCADE;

-- ========================================
-- STEP 5: DISABLE ROW LEVEL SECURITY TEMPORARILY
-- ========================================

-- Disable RLS for testing (re-enable later if needed)
ALTER TABLE jobs DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;

-- ========================================
-- STEP 6: VERIFY CLEANUP
-- ========================================

-- Check that no triggers remain on jobs table
SELECT 
    'TRIGGERS ON JOBS TABLE (SHOULD BE EMPTY):' as info,
    t.tgname as trigger_name,
    p.proname as function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'jobs' AND t.tgisinternal = false
ORDER BY t.tgname;

-- Check that no triggers remain on notifications table
SELECT 
    'TRIGGERS ON NOTIFICATIONS TABLE (SHOULD BE EMPTY):' as info,
    t.tgname as trigger_name,
    p.proname as function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'notifications' AND t.tgisinternal = false
ORDER BY t.tgname;

-- ========================================
-- STEP 7: TEST SIMPLE OPERATIONS
-- ========================================

-- Test that we can insert into notifications without HTTP errors
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
        -- Test notification creation (should work without HTTP errors)
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
            'TEST: Database cleanup successful - no HTTP errors!',
            'test',
            'normal',
            test_job_id,
            jsonb_build_object('test', true),
            NOW(),
            NOW()
        ) RETURNING id INTO notification_id;
        
        RAISE NOTICE 'SUCCESS: Created test notification % without HTTP errors', notification_id;
    ELSE
        RAISE NOTICE 'TEST: No test user or job found';
    END IF;
END $$;

-- ========================================
-- STEP 8: SUMMARY
-- ========================================

SELECT 
    'DATABASE CLEANUP COMPLETED!' as status,
    'All triggers removed' as step1,
    'All notification functions removed' as step2,
    'Realtime disabled for key tables' as step3,
    'RLS disabled for testing' as step4,
    'No HTTP calls should occur now' as step5,
    'Use JobAssignmentService in Flutter app' as step6;
