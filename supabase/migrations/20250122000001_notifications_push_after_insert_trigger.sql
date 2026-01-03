-- Migration: Automatic Push Notification Trigger
-- Date: 2025-01-22
-- Purpose: Automatically invoke push-notifications edge function when rows are inserted into app_notifications
--
-- This trigger ensures that server-side and client-side notification inserts
-- automatically attempt push delivery without requiring manual edge function invocation.
--
-- Security Note: The push-notifications edge function has verify_jwt=false, so it can be
-- called without authentication. However, it uses SUPABASE_SERVICE_ROLE_KEY internally
-- from environment variables for database access.

BEGIN;

-- Ensure pg_net extension is available (should already be installed)
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Create trigger function to invoke push-notifications edge function
CREATE OR REPLACE FUNCTION public.notify_push_after_insert()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  edge_function_url TEXT;
  payload JSONB;
  request_id BIGINT;
  log_success BOOLEAN;
  log_error TEXT;
BEGIN
  -- Build edge function URL
  -- Project URL: https://hgqrbekphumdlsifuamq.supabase.co
  edge_function_url := 'https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/push-notifications';
  
  -- Build webhook payload matching edge function expectations
  -- See: supabase/functions/push-notifications/index.ts
  payload := jsonb_build_object(
    'type', 'INSERT',
    'table', 'app_notifications',
    'record', row_to_json(NEW)::jsonb,
    'schema', 'public',
    'old_record', NULL
  );
  
  -- Attempt to call edge function via wrapper function (non-blocking)
  -- Using http_post_for_cron which is SECURITY DEFINER and has proper permissions
  BEGIN
    SELECT public.http_post_for_cron(
      p_url := edge_function_url,
      p_headers := '{"Content-Type": "application/json"}'::jsonb,
      p_body := payload,
      p_timeout_milliseconds := 5000
    ) INTO request_id;
    
    -- Log successful queue attempt
    log_success := TRUE;
    log_error := NULL;
    
  EXCEPTION
    WHEN OTHERS THEN
      -- Log failure to queue (but don't fail the INSERT)
      log_success := FALSE;
      log_error := SQLERRM;
      request_id := NULL;
      
      -- Log warning for debugging (non-blocking)
      RAISE WARNING 'Failed to queue push notification for notification %: %', NEW.id, SQLERRM;
  END;
  
  -- Log delivery attempt to notification_delivery_log (using correct column names)
  BEGIN
    INSERT INTO public.notification_delivery_log (
      notification_id,
      user_id,
      sent_at,
      success,
      error_message
    ) VALUES (
      NEW.id,
      NEW.user_id,
      NOW(),
      log_success,
      log_error
    );
  EXCEPTION
    WHEN OTHERS THEN
      -- Don't fail if logging fails (non-critical)
      RAISE WARNING 'Failed to log delivery attempt for notification %: %', NEW.id, SQLERRM;
  END;
  
  RETURN NEW;
END;
$$;

-- Set function owner
ALTER FUNCTION public.notify_push_after_insert() OWNER TO postgres;

-- Revoke execute from PUBLIC and anon (security)
REVOKE EXECUTE ON FUNCTION public.notify_push_after_insert() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.notify_push_after_insert() FROM anon;

-- Grant execute to service_role (for trigger execution context)
GRANT EXECUTE ON FUNCTION public.notify_push_after_insert() TO service_role;

-- Create trigger on app_notifications table
DROP TRIGGER IF EXISTS trg_app_notifications_push_after_insert ON public.app_notifications;

CREATE TRIGGER trg_app_notifications_push_after_insert
  AFTER INSERT ON public.app_notifications
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_push_after_insert();

-- Add comment to trigger
COMMENT ON TRIGGER trg_app_notifications_push_after_insert ON public.app_notifications IS
  'Automatically invokes push-notifications edge function when a notification is inserted. Non-blocking and error-tolerant.';

-- Add comment to function
COMMENT ON FUNCTION public.notify_push_after_insert() IS
  'Trigger function that queues push notification delivery via edge function. Uses http_post_for_cron wrapper for non-blocking async calls.';

COMMIT;

