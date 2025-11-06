-- Comprehensive diagnostic script for push notifications
-- Run this to check the entire notification flow

-- 1. Check if notification was created
SELECT 
  id,
  user_id,
  message,
  notification_type,
  created_at,
  is_hidden
FROM app_notifications
WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac'
ORDER BY created_at DESC
LIMIT 5;

-- 2. Check notification delivery log (shows if Edge Function was called)
SELECT 
  id,
  notification_id,
  user_id,
  LEFT(fcm_token, 30) as fcm_token_preview,
  success,
  error_message,
  sent_at,
  fcm_response
FROM notification_delivery_log
WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac'
ORDER BY sent_at DESC
LIMIT 10;

-- 3. Check user's FCM tokens
SELECT 
  id,
  display_name,
  CASE 
    WHEN fcm_token IS NOT NULL THEN 'Has Android token'
    ELSE 'No Android token'
  END as android_token_status,
  CASE 
    WHEN fcm_token_web IS NOT NULL THEN 'Has Web token'
    ELSE 'No Web token'
  END as web_token_status,
  LEFT(fcm_token, 30) as android_token_preview,
  LEFT(fcm_token_web, 30) as web_token_preview
FROM profiles
WHERE id = 'edd84489-515e-408e-ac93-378dc63f0eac';

-- 4. Check webhook configuration (if you have access)
-- Note: This requires admin access to pg_webhooks table
-- SELECT * FROM pg_webhooks WHERE name LIKE '%notification%';

