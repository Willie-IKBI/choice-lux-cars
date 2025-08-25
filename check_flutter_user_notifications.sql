-- CHECK FLUTTER USER NOTIFICATIONS
-- This checks notifications for the specific user that Flutter is using

-- ========================================
-- STEP 1: SHOW ALL USERS
-- ========================================

SELECT 
    'ALL USERS:' as info,
    id,
    display_name,
    role
FROM profiles 
LIMIT 10;

-- ========================================
-- STEP 2: CHECK NOTIFICATIONS FOR EACH USER
-- ========================================

-- Check notifications for each user in the system
SELECT 
    'NOTIFICATIONS BY USER:' as info,
    p.id as user_id,
    p.display_name,
    p.role,
    COUNT(an.id) as notification_count,
    COUNT(an.id) FILTER (WHERE an.is_read = false) as unread_count,
    COUNT(an.id) FILTER (WHERE an.is_hidden = false) as visible_count
FROM profiles p
LEFT JOIN app_notifications an ON p.id = an.user_id
GROUP BY p.id, p.display_name, p.role
ORDER BY notification_count DESC;

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
-- STEP 4: CREATE NOTIFICATION FOR SPECIFIC USER
-- ========================================

-- Create a notification for the first user (replace with actual user ID if needed)
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
    'FLUTTER TEST: This notification should appear in Flutter app',
    'flutter_test',
    'high',
    '999',
    jsonb_build_object('test', true, 'job_id', '999'),
    false,  -- Not read
    false   -- Not hidden
);

-- ========================================
-- STEP 5: VERIFY NEW NOTIFICATION
-- ========================================

SELECT 
    'NEW FLUTTER TEST NOTIFICATION:' as info,
    id,
    user_id,
    message,
    notification_type,
    is_read,
    is_hidden,
    created_at
FROM app_notifications 
WHERE notification_type = 'flutter_test'
ORDER BY created_at DESC
LIMIT 3;
