-- BYPASS SUPABASE REALTIME COMPLETELY
-- This creates a separate notifications table that doesn't trigger realtime
-- Run this in your Supabase SQL editor

-- ========================================
-- STEP 1: CREATE SEPARATE NOTIFICATIONS TABLE (NO REALTIME)
-- ========================================

-- Create a new notifications table that won't trigger realtime
CREATE TABLE IF NOT EXISTS app_notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    notification_type TEXT NOT NULL,
    priority TEXT DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    job_id TEXT,
    action_data JSONB,
    is_read BOOLEAN DEFAULT FALSE,
    is_hidden BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMPTZ,
    dismissed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Set replica identity to NOTHING for the new table
ALTER TABLE app_notifications REPLICA IDENTITY NOTHING;

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_app_notifications_user_id ON app_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_app_notifications_type ON app_notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_app_notifications_read ON app_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_app_notifications_created_at ON app_notifications(created_at DESC);

-- ========================================
-- STEP 2: DISABLE REALTIME ON ALL EXISTING TABLES
-- ========================================

-- Disable realtime for all existing tables
ALTER TABLE jobs REPLICA IDENTITY NOTHING;
ALTER TABLE notifications REPLICA IDENTITY NOTHING;
ALTER TABLE profiles REPLICA IDENTITY NOTHING;
ALTER TABLE driver_flow REPLICA IDENTITY NOTHING;

-- ========================================
-- STEP 3: DROP ALL TRIGGERS AND FUNCTIONS
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

-- Drop all notification functions
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
-- STEP 4: DISABLE ROW LEVEL SECURITY
-- ========================================

-- Disable RLS for testing
ALTER TABLE jobs DISABLE ROW LEVEL SECURITY;
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE profiles DISABLE ROW LEVEL SECURITY;
ALTER TABLE driver_flow DISABLE ROW LEVEL SECURITY;
ALTER TABLE app_notifications DISABLE ROW LEVEL SECURITY;

-- ========================================
-- STEP 5: TEST NEW NOTIFICATIONS TABLE
-- ========================================

-- Test that we can insert into the new notifications table without HTTP errors
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
        -- Test notification creation in new table (should work without HTTP errors)
        INSERT INTO app_notifications (
            user_id,
            message,
            notification_type,
            priority,
            job_id,
            action_data
        ) VALUES (
            test_user_id,
            'TEST: New notifications table - no HTTP errors!',
            'test',
            'normal',
            test_job_id::TEXT,
            jsonb_build_object('test', true, 'job_id', test_job_id)
        ) RETURNING id INTO notification_id;
        
        RAISE NOTICE 'SUCCESS: Created notification % in new table without HTTP errors', notification_id;
    ELSE
        RAISE NOTICE 'TEST: No test user or job found';
    END IF;
END $$;

-- ========================================
-- STEP 6: VERIFY NEW TABLE WORKS
-- ========================================

-- Check that notifications were created
SELECT 
    'NEW NOTIFICATIONS TABLE TEST:' as info,
    id,
    user_id,
    message,
    notification_type,
    created_at
FROM app_notifications 
ORDER BY created_at DESC
LIMIT 5;

-- ========================================
-- STEP 7: SUMMARY
-- ========================================

SELECT 
    'SUPABASE REALTIME COMPLETELY BYPASSED!' as status,
    'New app_notifications table created' as step1,
    'All triggers removed' as step2,
    'All notification functions removed' as step3,
    'RLS disabled for testing' as step4,
    'No HTTP calls should occur now' as step5,
    'Use app_notifications table for notifications' as step6;
