-- CREATE NOTIFICATIONS FOR ALL USERS
-- This creates test notifications for all users to see which one Flutter picks up

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
-- STEP 2: CREATE NOTIFICATIONS FOR ALL USERS
-- ========================================

-- Create a test notification for each user
INSERT INTO app_notifications (
    user_id,
    message,
    notification_type,
    priority,
    job_id,
    action_data,
    is_read,
    is_hidden
)
SELECT 
    p.id,
    'TEST FOR USER: ' || p.display_name || ' (ID: ' || p.id || ')',
    'user_test',
    'high',
    '999',
    jsonb_build_object('test', true, 'user_id', p.id, 'user_name', p.display_name),
    false,  -- Not read
    false   -- Not hidden
FROM profiles p
LIMIT 5;  -- Limit to first 5 users

-- ========================================
-- STEP 3: VERIFY NOTIFICATIONS CREATED
-- ========================================

SELECT 
    'ALL TEST NOTIFICATIONS:' as info,
    id,
    user_id,
    message,
    notification_type,
    is_read,
    is_hidden,
    created_at
FROM app_notifications 
WHERE notification_type = 'user_test'
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- STEP 4: SHOW NOTIFICATIONS BY USER
-- ========================================

SELECT 
    'NOTIFICATIONS BY USER:' as info,
    p.id as user_id,
    p.display_name,
    p.role,
    COUNT(an.id) as total_notifications,
    COUNT(an.id) FILTER (WHERE an.is_read = false) as unread_count,
    COUNT(an.id) FILTER (WHERE an.is_hidden = false) as visible_count
FROM profiles p
LEFT JOIN app_notifications an ON p.id = an.user_id
GROUP BY p.id, p.display_name, p.role
ORDER BY total_notifications DESC;
