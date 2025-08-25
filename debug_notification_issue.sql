-- DEBUG NOTIFICATION ISSUE
-- Check what's happening with notifications

-- ========================================
-- STEP 1: CHECK OLD NOTIFICATIONS TABLE
-- ========================================

SELECT 
    'OLD NOTIFICATIONS TABLE:' as info,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE is_read = false) as unread_count,
    COUNT(*) FILTER (WHERE is_read = true) as read_count,
    COUNT(*) FILTER (WHERE is_hidden = true) as dismissed_count
FROM notifications;

-- Show sample from old table
SELECT 
    'OLD NOTIFICATIONS SAMPLE:' as info,
    id,
    user_id,
    message,
    notification_type,
    is_read,
    is_hidden,
    created_at
FROM notifications 
ORDER BY created_at DESC
LIMIT 5;

-- ========================================
-- STEP 2: CHECK NEW NOTIFICATIONS TABLE
-- ========================================

SELECT 
    'NEW NOTIFICATIONS TABLE:' as info,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE is_read = false) as unread_count,
    COUNT(*) FILTER (WHERE is_read = true) as read_count,
    COUNT(*) FILTER (WHERE is_hidden = true) as dismissed_count
FROM app_notifications;

-- Show sample from new table
SELECT 
    'NEW NOTIFICATIONS SAMPLE:' as info,
    id,
    user_id,
    message,
    notification_type,
    is_read,
    is_hidden,
    created_at
FROM app_notifications 
ORDER BY created_at DESC
LIMIT 5;

-- ========================================
-- STEP 3: CHECK SPECIFIC USER NOTIFICATIONS
-- ========================================

-- Get a test user
DO $$
DECLARE
    test_user_id UUID;
BEGIN
    SELECT id INTO test_user_id 
    FROM profiles 
    LIMIT 1;
    
    IF test_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing notifications for user: %', test_user_id;
        
        -- Check old table for this user
        RAISE NOTICE 'Old table notifications for user:';
        DECLARE
            old_count INTEGER;
        BEGIN
            SELECT COUNT(*) INTO old_count FROM notifications WHERE user_id = test_user_id;
            RAISE NOTICE 'Old table count: %', old_count;
        END;
        
        -- Check new table for this user
        RAISE NOTICE 'New table notifications for user:';
        DECLARE
            new_count INTEGER;
        BEGIN
            SELECT COUNT(*) INTO new_count FROM app_notifications WHERE user_id = test_user_id;
            RAISE NOTICE 'New table count: %', new_count;
        END;
        
        -- Create a test notification in new table
        INSERT INTO app_notifications (
            user_id,
            message,
            notification_type,
            priority,
            job_id,
            action_data
        ) VALUES (
            test_user_id,
            'DEBUG: Test notification for debugging',
            'debug',
            'high',
            '123',
            jsonb_build_object('debug', true)
        );
        
        RAISE NOTICE 'Created test notification in new table';
    END IF;
END $$;

-- ========================================
-- STEP 4: VERIFY TEST NOTIFICATION
-- ========================================

SELECT 
    'TEST NOTIFICATION CREATED:' as info,
    id,
    user_id,
    message,
    notification_type,
    is_read,
    is_hidden,
    created_at
FROM app_notifications 
WHERE notification_type = 'debug'
ORDER BY created_at DESC
LIMIT 3;
