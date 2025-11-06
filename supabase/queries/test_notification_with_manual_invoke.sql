-- Complete test notification workflow
-- Step 1: Insert notification
-- Step 2: Get payload for manual Edge Function invocation
-- Step 3: Copy payload and invoke Edge Function in Supabase Dashboard

-- STEP 1: Insert the notification
INSERT INTO app_notifications (
  user_id,
  message,
  notification_type,
  priority,
  is_read,
  is_hidden,
  created_at
) VALUES (
  'edd84489-515e-408e-ac93-378dc63f0eac',
  'Test notification - Manual Edge Function invocation required. Copy the payload below and invoke push-notifications Edge Function in Supabase Dashboard.',
  'system_alert',
  'normal',
  false,
  false,
  NOW()
)
RETURNING id, user_id, message, notification_type, created_at;

-- STEP 2: Get the payload for the latest notification (run this after step 1)
-- Copy the JSON payload and use it in Supabase Dashboard > Edge Functions > push-notifications > Invoke
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
  ) AS payload_for_edge_function
FROM latest_notification n;

