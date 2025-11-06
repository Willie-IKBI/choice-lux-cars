-- Test notification for user: Willie Administrator
-- User ID: edd84489-515e-408e-ac93-378dc63f0eac
-- Note: This only creates the notification in the database.
-- Push notifications are triggered automatically by the app code (NotificationService.createNotification)
-- OR you can manually invoke the push-notifications Edge Function in Supabase Dashboard

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
  'Test notification - If inserted via SQL, you need to manually invoke the push-notifications Edge Function in Supabase Dashboard with the notification payload.',
  'system_alert',
  'normal',
  false,
  false,
  NOW()
)
RETURNING *;

-- Verify the notification was created
SELECT 
  id,
  user_id,
  message,
  notification_type,
  is_read,
  is_hidden,
  created_at
FROM app_notifications
WHERE user_id = 'edd84489-515e-408e-ac93-378dc63f0eac'
ORDER BY created_at DESC
LIMIT 5;

