-- SIMPLE DEBUG NOTIFICATIONS
-- Check what's happening with notifications (no complex PL/pgSQL)

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
-- STEP 3: CREATE TEST NOTIFICATION
-- ========================================

-- Create a test notification in new table
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
    'SIMPLE TEST: This is a test notification',
    'simple_test',
    'high',
    '999',
    jsonb_build_object('test', true, 'job_id', '999'),
    false,  -- Not read
    false   -- Not hidden
);

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
WHERE notification_type = 'simple_test'
ORDER BY created_at DESC
LIMIT 3;

-- ========================================
-- STEP 5: TEST FLUTTER QUERY
-- ========================================

-- This simulates the exact query that Flutter uses
SELECT 
    'FLUTTER QUERY SIMULATION:' as info,
    id,
    user_id,
    message,
    notification_type,
    is_read,
    is_hidden,
    created_at
FROM app_notifications 
WHERE user_id = (SELECT id FROM profiles LIMIT 1)
  AND is_hidden = false
ORDER BY created_at DESC
LIMIT 10;
