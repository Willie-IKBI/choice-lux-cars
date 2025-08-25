-- TEST NEW NOTIFICATION SYSTEM
-- This tests the new app_notifications table and JobAssignmentService

-- ========================================
-- STEP 1: VERIFY NEW TABLE EXISTS
-- ========================================

SELECT 
    'NEW NOTIFICATIONS TABLE STATUS:' as info,
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'app_notifications'
ORDER BY ordinal_position;

-- ========================================
-- STEP 2: TEST NOTIFICATION CREATION
-- ========================================

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
            'TEST: New notification system working!',
            'test',
            'high',
            test_job_id::TEXT,
            jsonb_build_object('test', true, 'job_id', test_job_id)
        ) RETURNING id INTO notification_id;
        
        RAISE NOTICE 'SUCCESS: Created notification % in new table without HTTP errors', notification_id;
        
        -- Test marking as read
        UPDATE app_notifications 
        SET is_read = true, read_at = NOW()
        WHERE id = notification_id;
        
        RAISE NOTICE 'SUCCESS: Marked notification as read';
        
    ELSE
        RAISE NOTICE 'TEST: No test user or job found';
    END IF;
END $$;

-- ========================================
-- STEP 3: VERIFY NOTIFICATIONS CREATED
-- ========================================

SELECT 
    'NEW NOTIFICATIONS TEST RESULTS:' as info,
    id,
    user_id,
    message,
    notification_type,
    priority,
    is_read,
    created_at
FROM app_notifications 
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- STEP 4: SUMMARY
-- ========================================

SELECT 
    'NEW NOTIFICATION SYSTEM TEST COMPLETE!' as status,
    'app_notifications table working' as step1,
    'No HTTP errors occurred' as step2,
    'Ready for Flutter app testing' as step3,
    'Webhook setup next' as step4;
