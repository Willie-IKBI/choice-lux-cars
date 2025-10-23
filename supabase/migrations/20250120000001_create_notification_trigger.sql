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
  -- Note: The Edge Function will handle authentication internally
  SELECT content::jsonb INTO response
  FROM http((
    'POST',
    'https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/push-notifications',
    ARRAY[http_header('Content-Type', 'application/json')],
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
