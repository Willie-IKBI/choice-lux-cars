-- Test job assignment notification flow
-- This script will test the complete flow from job assignment to notification creation

-- Step 1: Check current notifications for the driver
SELECT 
    id,
    user_id,
    job_id,
    notification_type,
    message,
    priority,
    is_read,
    created_at
FROM app_notifications 
WHERE user_id = '2b48a98e-cdb9-4698-82fc-e8061bf925e6'
ORDER BY created_at DESC;

-- Step 2: Check the latest job (504) to see if it has a driver assigned
SELECT 
    id,
    job_number,
    passenger_name,
    driver_id,
    job_status,
    driver_confirm_ind,
    created_at
FROM jobs 
WHERE id = 504;

-- Step 3: Manually assign job 504 to the driver and create notification
-- This simulates what should happen automatically when a job is created with a driver

-- First, update the job to ensure it has the driver assigned
UPDATE jobs 
SET 
    driver_id = '2b48a98e-cdb9-4698-82fc-e8061bf925e6',
    updated_at = NOW()
WHERE id = 504;

-- Then create the notification
INSERT INTO app_notifications (
    user_id,
    message,
    notification_type,
    priority,
    job_id,
    action_data,
    created_at,
    updated_at
) VALUES (
    '2b48a98e-cdb9-4698-82fc-e8061bf925e6',
    '🚗 New job JOB-2025-504 has been assigned to you. Please confirm your assignment.',
    'job_assignment',
    'high',
    504,
    '{
        "job_id": 504,
        "job_number": "JOB-2025-504",
        "passenger_name": "Test passaner",
        "action": "view_job",
        "route": "/jobs/504/summary"
    }'::jsonb,
    NOW(),
    NOW()
);

-- Step 4: Verify the notification was created
SELECT 
    id,
    user_id,
    job_id,
    notification_type,
    message,
    priority,
    is_read,
    created_at
FROM app_notifications 
WHERE user_id = '2b48a98e-cdb9-4698-82fc-e8061bf925e6'
ORDER BY created_at DESC;

-- Step 5: Check all notifications for the driver
SELECT 
    COUNT(*) as total_notifications,
    COUNT(CASE WHEN is_read = false THEN 1 END) as unread_notifications,
    COUNT(CASE WHEN priority = 'high' THEN 1 END) as high_priority_notifications
FROM app_notifications 
WHERE user_id = '2b48a98e-cdb9-4698-82fc-e8061bf925e6';
