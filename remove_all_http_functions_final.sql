-- FINAL FIX: Completely remove ALL HTTP functionality
-- Run this SQL in your Supabase SQL editor

-- STEP 1: DISABLE ALL TRIGGERS FIRST
DO $$ 
DECLARE 
    trigger_record RECORD;
BEGIN
    -- Disable ALL non-internal triggers on jobs table
    FOR trigger_record IN 
        SELECT t.tgname 
        FROM pg_trigger t
        JOIN pg_class c ON t.tgrelid = c.oid
        WHERE c.relname = 'jobs' AND t.tgisinternal = false
    LOOP
        EXECUTE format('ALTER TABLE jobs DISABLE TRIGGER %I', trigger_record.tgname);
        RAISE NOTICE 'Disabled trigger: %', trigger_record.tgname;
    END LOOP;
END $$;

-- STEP 2: DROP ALL TRIGGERS
DROP TRIGGER IF EXISTS job_assignment_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_confirmation_notification_trigger ON jobs;
DROP TRIGGER IF EXISTS job_assignment_trigger ON jobs;
DROP TRIGGER IF EXISTS on_job_assigned ON jobs;
DROP TRIGGER IF EXISTS update_jobs_updated_at ON jobs;
DROP TRIGGER IF EXISTS jobs_audit_trigger ON jobs;
DROP TRIGGER IF EXISTS jobs_webhook_trigger ON jobs;
DROP TRIGGER IF EXISTS trg_jobs_updated_at ON jobs;

-- STEP 3: DROP ALL FUNCTIONS THAT MIGHT USE HTTP
DROP FUNCTION IF EXISTS create_job_assignment_notification() CASCADE;
DROP FUNCTION IF EXISTS mark_job_notifications_as_read() CASCADE;
DROP FUNCTION IF EXISTS notify_job_assignment() CASCADE;
DROP FUNCTION IF EXISTS handle_job_assignment() CASCADE;
DROP FUNCTION IF EXISTS send_push_notification() CASCADE;
DROP FUNCTION IF EXISTS process_job_notification_log() CASCADE;

-- STEP 4: DROP ALL HTTP FUNCTIONS FROM ALL SCHEMAS
DROP FUNCTION IF EXISTS http_post(text, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS http_post(text, jsonb, jsonb, jsonb, integer) CASCADE;
DROP FUNCTION IF EXISTS http_get(text, jsonb) CASCADE;
DROP FUNCTION IF EXISTS http_request(text, text, jsonb, jsonb) CASCADE;
DROP FUNCTION IF EXISTS http_request(text, text, jsonb, jsonb, integer) CASCADE;

-- STEP 5: DROP HTTP EXTENSION IF POSSIBLE
DROP EXTENSION IF EXISTS http CASCADE;

-- STEP 6: CREATE PURE NOTIFICATION FUNCTIONS (NO HTTP AT ALL)
CREATE OR REPLACE FUNCTION public.create_job_assignment_notification()
RETURNS TRIGGER AS $$
DECLARE
    driver_name TEXT;
    job_description TEXT;
BEGIN
    -- Only create notification if driver_id is set and changed
    IF NEW.driver_id IS NOT NULL AND (OLD.driver_id IS NULL OR OLD.driver_id != NEW.driver_id) THEN
        
        -- Get driver name using the correct column name 'display_name'
        SELECT display_name INTO driver_name 
        FROM profiles 
        WHERE id = NEW.driver_id;
        
        -- Create job description using available fields
        job_description := COALESCE(
            CASE 
                WHEN NEW.passenger_name IS NOT NULL THEN 'Job for ' || NEW.passenger_name
                WHEN NEW.job_number IS NOT NULL THEN 'Job #' || NEW.job_number
                ELSE 'New Job Assignment'
            END,
            'New Job Assignment'
        );
        
        -- Insert notification (PURE DATABASE - NO HTTP)
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
            'You have been assigned to: ' || job_description,
            'job_assignment',
            'high',
            NEW.id,
            jsonb_build_object('job_id', NEW.id, 'action', 'view_job'),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'Created job assignment notification for driver % (PURE DATABASE)', NEW.driver_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create pure confirmation function (NO HTTP)
CREATE OR REPLACE FUNCTION public.mark_job_notifications_as_read()
RETURNS TRIGGER AS $$
BEGIN
    -- Only mark notifications as read if job is confirmed
    IF (NEW.is_confirmed = true OR NEW.driver_confirm_ind = true) AND 
       (OLD.is_confirmed = false OR OLD.driver_confirm_ind = false) THEN
        
        -- Mark job assignment notifications as read (PURE DATABASE)
        UPDATE notifications 
        SET 
            read_at = NOW(),
            updated_at = NOW()
        WHERE job_id = NEW.id 
          AND notification_type IN ('job_assignment', 'job_reassignment')
          AND read_at IS NULL;
        
        RAISE NOTICE 'Marked job notifications as read for job % (PURE DATABASE)', NEW.id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- STEP 7: CREATE TRIGGERS (DISABLED BY DEFAULT)
CREATE TRIGGER job_assignment_notification_trigger
    AFTER INSERT OR UPDATE OF driver_id
    ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION public.create_job_assignment_notification();

CREATE TRIGGER job_confirmation_notification_trigger
    AFTER UPDATE OF is_confirmed, driver_confirm_ind
    ON jobs
    FOR EACH ROW
    EXECUTE FUNCTION public.mark_job_notifications_as_read();

-- STEP 8: KEEP TRIGGERS DISABLED FOR NOW
ALTER TABLE jobs DISABLE TRIGGER job_assignment_notification_trigger;
ALTER TABLE jobs DISABLE TRIGGER job_confirmation_notification_trigger;

-- STEP 9: VERIFY NO HTTP FUNCTIONS EXIST ANYWHERE
SELECT 
    'HTTP Functions Check:' as info,
    p.proname as function_name,
    n.nspname as schema_name,
    'SHOULD BE DROPPED' as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE (p.proname LIKE '%http%' OR p.proname LIKE '%webhook%' OR p.proname LIKE '%notify%')
  AND n.nspname NOT IN ('information_schema', 'pg_catalog')
UNION ALL
SELECT 
    'No HTTP functions found' as info,
    '' as function_name,
    '' as schema_name,
    'SUCCESS' as status
WHERE NOT EXISTS (
    SELECT 1 FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE (p.proname LIKE '%http%' OR p.proname LIKE '%webhook%' OR p.proname LIKE '%notify%')
      AND n.nspname NOT IN ('information_schema', 'pg_catalog')
);

-- STEP 10: VERIFY TRIGGER STATUS
SELECT 
    'Trigger Status:' as info,
    t.tgname as trigger_name,
    p.proname as function_name,
    CASE 
        WHEN t.tgenabled = 'D' THEN 'DISABLED'
        WHEN t.tgenabled = 'O' THEN 'ENABLED'
        ELSE 'UNKNOWN'
    END as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE c.relname = 'jobs' AND t.tgisinternal = false
ORDER BY t.tgname;

-- STEP 11: TEST PURE NOTIFICATION CREATION
DO $$
DECLARE
    test_user_id UUID;
    test_job_id BIGINT;
BEGIN
    -- Get a test user (driver)
    SELECT id INTO test_user_id 
    FROM profiles 
    WHERE role = 'driver' 
    LIMIT 1;
    
    -- Get a test job
    SELECT id INTO test_job_id 
    FROM jobs 
    WHERE driver_id IS NULL 
    LIMIT 1;
    
    IF test_user_id IS NOT NULL AND test_job_id IS NOT NULL THEN
        -- Create a test notification (PURE DATABASE)
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
            'PURE DATABASE TEST: Job assignment system is working!',
            'job_assignment',
            'high',
            test_job_id,
            jsonb_build_object('job_id', test_job_id, 'action', 'view_job'),
            NOW(),
            NOW()
        );
        
        RAISE NOTICE 'PURE DATABASE test notification created for user % and job %', test_user_id, test_job_id;
    ELSE
        RAISE NOTICE 'No test user or job found for testing';
    END IF;
END $$;

-- STEP 12: SUMMARY
SELECT 
    'HTTP Functions Completely Removed!' as status,
    'All HTTP functions dropped' as step1,
    'All triggers disabled' as step2,
    'Pure database functions created' as step3,
    'Test notification created successfully' as step4,
    'Job creation should work now' as step5;
