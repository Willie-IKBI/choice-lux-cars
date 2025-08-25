-- SIMPLE CHECK PROFILES
-- This shows the basic profiles table structure and data

-- ========================================
-- STEP 1: SHOW PROFILES TABLE COLUMNS
-- ========================================

SELECT 
    'PROFILES TABLE COLUMNS:' as info,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY ordinal_position;

-- ========================================
-- STEP 2: SHOW ALL USERS
-- ========================================

SELECT 
    'ALL USERS:' as info,
    id,
    display_name,
    role
FROM profiles 
LIMIT 10;

-- ========================================
-- STEP 3: SHOW ALL NOTIFICATIONS
-- ========================================

SELECT 
    'ALL NOTIFICATIONS:' as info,
    id,
    user_id,
    message,
    notification_type,
    is_read,
    is_hidden,
    created_at
FROM app_notifications 
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- STEP 4: CREATE TEST NOTIFICATION
-- ========================================

-- Create a test notification for the first user
INSERT INTO app_notifications (
    user_id,
    message,
    notification_type,
    priority,
    job_id,
    action_data,
    is_read,
    is_hidden
) VALUES (
    (SELECT id FROM profiles LIMIT 1),
    'SIMPLE TEST: This notification should appear in Flutter app',
    'simple_test',
    'high',
    '999',
    jsonb_build_object('test', true, 'job_id', '999'),
    false,  -- Not read
    false   -- Not hidden
);

-- ========================================
-- STEP 5: VERIFY TEST NOTIFICATION
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
WHERE notification_type = 'simple_test'
ORDER BY created_at DESC
LIMIT 3;
