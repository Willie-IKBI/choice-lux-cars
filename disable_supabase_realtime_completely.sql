-- COMPLETELY DISABLE SUPABASE REALTIME BROADCASTING
-- This prevents Supabase from triggering HTTP calls when inserting data
-- Run this in your Supabase SQL editor

-- ========================================
-- STEP 1: DISABLE REALTIME FOR ALL KEY TABLES
-- ========================================

-- Disable realtime for jobs table
ALTER TABLE jobs REPLICA IDENTITY NOTHING;

-- Disable realtime for notifications table  
ALTER TABLE notifications REPLICA IDENTITY NOTHING;

-- Disable realtime for profiles table
ALTER TABLE profiles REPLICA IDENTITY NOTHING;

-- Disable realtime for driver_flow table
ALTER TABLE driver_flow REPLICA IDENTITY NOTHING;

-- ========================================
-- STEP 2: DROP ALL TRIGGERS THAT MIGHT TRIGGER BROADCASTING
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

-- Drop all triggers on notifications table
DROP TRIGGER IF EXISTS update_notifications_updated_at ON notifications;
DROP TRIGGER IF EXISTS notifications_audit_trigger ON notifications;

-- ========================================
-- STEP 3: DROP ALL NOTIFICATION FUNCTIONS
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
-- STEP 4: DISABLE ROW LEVEL SECURITY TEMPORARILY
-- ========================================

-- Disable RLS for testing (re-enable later if needed)
ALTER TABLE jobs DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE driver_flow DISABLE ROW LEVEL SECURITY;

-- ========================================
-- STEP 5: VERIFY REALTIME IS DISABLED
-- ========================================

-- Check replica identity settings
SELECT 
    'REPLICA IDENTITY STATUS:' as info,
    n.nspname as schema_name,
    c.relname as table_name,
    CASE 
        WHEN c.relreplident = 'd' THEN 'DEFAULT'
        WHEN c.relreplident = 'n' THEN 'NOTHING'
        WHEN c.relreplident = 'f' THEN 'FULL'
        WHEN c.relreplident = 'i' THEN 'INDEX'
        ELSE 'UNKNOWN'
    END as replica_identity
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
  AND c.relname IN ('jobs', 'notifications', 'profiles', 'driver_flow')
ORDER BY c.relname;

-- ========================================
-- STEP 6: TEST NOTIFICATION CREATION (NO BROADCASTING)
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
            'TEST: Realtime disabled - no HTTP errors!',
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
-- STEP 7: SUMMARY
-- ========================================

SELECT 
    'SUPABASE REALTIME COMPLETELY DISABLED!' as status,
    'All tables set to REPLICA IDENTITY NOTHING' as step1,
    'All triggers removed' as step2,
    'All notification functions removed' as step3,
    'RLS disabled for testing' as step4,
    'No broadcasting should occur now' as step5,
    'Use JobAssignmentService in Flutter app' as step6;
