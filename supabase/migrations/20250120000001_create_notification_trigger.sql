-- Create a function to call the Edge Function when notifications are inserted
CREATE OR REPLACE FUNCTION trigger_push_notification()
RETURNS TRIGGER AS $$
DECLARE
  payload JSONB;
  response JSONB;
BEGIN
  -- Prepare the webhook payload
  payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'app_notifications',
    'record', row_to_json(NEW),
    'schema', 'public',
    'old_record', NULL
  );

  -- Call the Edge Function
  SELECT content::jsonb INTO response
  FROM http((
    'POST',
    'https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/push-notifications',
    ARRAY[http_header('Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhncXJiZWtwaHVtZGxzaWZ1YW1xIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTcyNzUxNzY2OCwiZXhwIjoyMDQzMDkzNjY4fQ.zjNZ15cicbJpyYNyhcgc-MAhO0wbVgeE3Lb07IfWlVc')],
    'application/json',
    payload::text
  ));

  -- Log the response (optional)
  INSERT INTO notification_delivery_log (
    notification_id,
    user_id,
    fcm_token,
    fcm_response,
    sent_at,
    success
  ) VALUES (
    NEW.id,
    NEW.user_id,
    NULL, -- Will be filled by Edge Function
    response,
    NOW(),
    (response->>'success')::boolean
  );

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create the trigger
DROP TRIGGER IF EXISTS app_notifications_push_trigger ON app_notifications;
CREATE TRIGGER app_notifications_push_trigger
  AFTER INSERT ON app_notifications
  FOR EACH ROW
  EXECUTE FUNCTION trigger_push_notification();
