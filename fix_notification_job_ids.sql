-- Fix notifications that have job numbers instead of job IDs
-- This script will clean up any notifications that have job numbers like "2025-002" instead of actual job IDs

-- First, let's see what notifications have job numbers instead of job IDs
SELECT 
    id,
    user_id,
    job_id,
    notification_type,
    message,
    created_at
FROM app_notifications 
WHERE job_id ~ '^[A-Z]+-[0-9]+$'  -- Pattern for job numbers like "JOB-2025-002"
   OR job_id ~ '^[0-9]+-[0-9]+$'; -- Pattern for job numbers like "2025-002"

-- Update notifications to use the correct job ID by looking up the job number
-- For now, we'll set job_id to NULL for these problematic notifications
-- so they don't cause navigation errors

UPDATE app_notifications 
SET 
    job_id = NULL,
    action_data = jsonb_set(
        COALESCE(action_data, '{}'::jsonb),
        '{error}',
        '"Job ID was a job number, needs manual fix"'
    ),
    updated_at = NOW()
WHERE job_id ~ '^[A-Z]+-[0-9]+$'  -- Pattern for job numbers like "JOB-2025-002"
   OR job_id ~ '^[0-9]+-[0-9]+$'; -- Pattern for job numbers like "2025-002"

-- Verify the fix
SELECT 
    id,
    user_id,
    job_id,
    notification_type,
    message,
    action_data,
    created_at
FROM app_notifications 
WHERE job_id IS NULL 
  AND action_data->>'error' IS NOT NULL;

-- Show remaining notifications with valid job IDs
SELECT 
    id,
    user_id,
    job_id,
    notification_type,
    message,
    created_at
FROM app_notifications 
WHERE job_id IS NOT NULL
  AND job_id ~ '^[0-9]+$'  -- Only numeric job IDs
ORDER BY created_at DESC
LIMIT 10;
