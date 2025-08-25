-- CREATE NOTIFICATION FOR FLUTTER USER
-- This creates a test notification for the specific user ID that Flutter is using

-- ========================================
-- STEP 1: VERIFY THE FLUTTER USER EXISTS
-- ========================================

SELECT 
    'FLUTTER USER VERIFICATION:' as info,
    id,
    display_name,
    role
FROM profiles 
WHERE id = '2b48a98e-cdb9-4698-82fc-e8061bf925e6';

-- ========================================
-- STEP 2: CREATE NOTIFICATION FOR FLUTTER USER
-- ========================================

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
    '2b48a98e-cdb9-4698-82fc-e8061bf925e6',  -- Flutter user ID
    '🎉 SUCCESS! This notification should appear in Flutter app!',
    'flutter_test',
    'high',
    '999',
    jsonb_build_object('test', true, 'user_id', '2b48a98e-cdb9-4698-82fc-e8061bf925e6'),
    false,  -- Not read
    false   -- Not hidden
);

-- ========================================
-- STEP 3: VERIFY NOTIFICATION CREATED
-- ========================================

SELECT 
    'FLUTTER TEST NOTIFICATION CREATED:' as info,
    id,
    user_id,
    message,
    notification_type,
    is_read,
    is_hidden,
    created_at
FROM app_notifications 
WHERE user_id = '2b48a98e-cdb9-4698-82fc-e8061bf925e6'
  AND notification_type = 'flutter_test'
ORDER BY created_at DESC
LIMIT 3;

-- ========================================
-- STEP 4: SHOW ALL NOTIFICATIONS FOR FLUTTER USER
-- ========================================

SELECT 
    'ALL NOTIFICATIONS FOR FLUTTER USER:' as info,
    id,
    user_id,
    message,
    notification_type,
    is_read,
    is_hidden,
    created_at
FROM app_notifications 
WHERE user_id = '2b48a98e-cdb9-4698-82fc-e8061bf925e6'
ORDER BY created_at DESC
LIMIT 10;
