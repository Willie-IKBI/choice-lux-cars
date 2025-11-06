-- Check if the webhook was triggered and what happened
-- Run this after creating a test notification

-- 1. Check if notification was created
SELECT 
  id,
  user_id,
  message,
  notification_type,
  created_at
FROM app_notifications
WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac'
ORDER BY created_at DESC
LIMIT 5;

-- 2. Check notification delivery log (if webhook was triggered)
SELECT 
  id,
  notification_id,
  user_id,
  fcm_token,
  success,
  error_message,
  fcm_response,
  sent_at
FROM notification_delivery_log
WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac'
ORDER BY sent_at DESC
LIMIT 10;

-- 3. Check Edge Function logs (in Supabase Dashboard → Edge Functions → push-notifications → Logs)

