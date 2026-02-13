-- Add SET search_path = public to functions flagged by security advisors
-- See plan: Phase 3 - Function Search Path (Security)

-- 1. cleanup_old_notifications
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS TABLE(deleted_count bigint)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  deleted_rows bigint;
BEGIN
  DELETE FROM public.app_notifications
  WHERE created_at < NOW() - INTERVAL '15 days';

  GET DIAGNOSTICS deleted_rows = ROW_COUNT;
  RAISE NOTICE 'Cleaned up % notifications older than 15 days', deleted_rows;
  RETURN QUERY SELECT deleted_rows;
END;
$$;

-- 2. log_notification_created
CREATE OR REPLACE FUNCTION public.log_notification_created()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RAISE NOTICE 'Notification created: % for user: %', NEW.id, NEW.user_id;

  INSERT INTO public.notification_delivery_log (
    notification_id,
    user_id,
    fcm_token,
    fcm_response,
    sent_at,
    success,
    error_message,
    retry_count
  ) VALUES (
    NEW.id,
    NEW.user_id,
    NULL,
    NULL,
    NULL,
    false,
    'Created - will be sent via Edge Function',
    0
  );

  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'Logging failed (non-critical): %', SQLERRM;
    RETURN NEW;
END;
$$;

-- 3. update_job_total (uuid overload - bigint overload already has search_path)
CREATE OR REPLACE FUNCTION public.update_job_total(job_to_update uuid)
RETURNS void
LANGUAGE plpgsql
SET search_path = public
AS $$
declare
  total_amount numeric;
begin
  select coalesce(sum(amount), 0)
  into total_amount
  from transport
  where job_id = job_to_update;

  update jobs
  set amount = total_amount
  where id = job_to_update;
end;
$$;
