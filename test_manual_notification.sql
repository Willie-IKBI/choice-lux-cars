-- TEST MANUAL NOTIFICATION CREATION
-- This creates a test notification manually to verify the system works

-- ========================================
-- STEP 1: GET CURRENT USER ID
-- ========================================

DO $$
DECLARE
    current_user_id UUID;
BEGIN
    -- Get the first user (you can replace this with a specific user ID)
    SELECT id INTO current_user_id 
    FROM profiles 
    LIMIT 1;
    
    IF current_user_id IS NOT NULL THEN
        RAISE NOTICE 'Testing with user ID: %', current_user_id;
        
        -- Create a test notification
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
            current_user_id,
            'MANUAL TEST: This is a test notification',
            'test',
            'high',
            '999',
            jsonb_build_object('test', true, 'job_id', '999'),
            false,  -- Not read
            false   -- Not hidden
        );
        
        RAISE NOTICE 'Created test notification successfully';
        
        -- Verify it was created
        RAISE NOTICE 'Verifying notification was created:';
        DECLARE
            notification_record RECORD;
        BEGIN
            SELECT id, message, is_read, is_hidden INTO notification_record 
            FROM app_notifications 
            WHERE user_id = current_user_id AND notification_type = 'test' 
            ORDER BY created_at DESC 
            LIMIT 1;
            
            IF notification_record.id IS NOT NULL THEN
                RAISE NOTICE 'Notification ID: %, Message: %, Read: %, Hidden: %', 
                    notification_record.id, notification_record.message, 
                    notification_record.is_read, notification_record.is_hidden;
            ELSE
                RAISE NOTICE 'No test notification found';
            END IF;
        END;
        
    ELSE
        RAISE NOTICE 'No users found in profiles table';
    END IF;
END $$;

-- ========================================
-- STEP 2: VERIFY NOTIFICATION EXISTS
-- ========================================

SELECT 
    'MANUAL TEST NOTIFICATION:' as info,
    id,
    user_id,
    message,
    notification_type,
    priority,
    is_read,
    is_hidden,
    created_at
FROM app_notifications 
WHERE notification_type = 'test'
ORDER BY created_at DESC
LIMIT 5;

-- ========================================
-- STEP 3: TEST QUERY THAT FLUTTER USES
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
