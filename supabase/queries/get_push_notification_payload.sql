-- Helper query to get the payload for manually invoking push-notifications Edge Function
-- Usage: After inserting a notification, run this to get the payload, then invoke the Edge Function manually in Supabase Dashboard

-- Replace this with your notification ID after inserting
WITH notification_data AS (
  SELECT 
    id,
    user_id,
    message,
    notification_type,
    priority,
    job_id,
    action_data,
    is_read,
    is_hidden,
    created_at,
    updated_at
  FROM app_notifications
  WHERE id = 'REPLACE_WITH_NOTIFICATION_ID' -- Replace with actual notification ID
)
SELECT 
  jsonb_build_object(
    'type', 'INSERT',
    'table', 'app_notifications',
    'record', to_jsonb(n.*),
    'schema', 'public',
    'old_record', NULL
  ) AS payload
FROM notification_data n;

-- Example: After inserting a notification, get its ID and use it above
-- Or use this to get the latest notification for a user:
/*
WITH latest_notification AS (
  SELECT * FROM app_notifications
  WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac'
  ORDER BY created_at DESC
  LIMIT 1
)
SELECT 
  jsonb_build_object(
    'type', 'INSERT',
    'table', 'app_notifications',
    'record', to_jsonb(n.*),
    'schema', 'public',
    'old_record', NULL
  ) AS payload
FROM latest_notification n;
*/

