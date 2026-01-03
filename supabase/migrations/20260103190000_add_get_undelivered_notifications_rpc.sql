-- Migration: Add RPC function to efficiently query undelivered notifications
-- Date: 2026-01-03
-- Purpose: Replace two-step query (fetch 50, filter in-memory) with single SQL query
--          that returns only undelivered notifications, sorted newest first

BEGIN;

-- Create RPC function to get undelivered notifications efficiently
-- SQL: SELECT an.id, an.user_id, an.message, an.notification_type, an.priority, an.job_id, an.action_data, an.created_at,
--           COALESCE(MAX(ndl_all.retry_count), 0) as max_retry_count, MAX(ndl_all.sent_at) as last_attempt_at
--      FROM app_notifications an
--      LEFT JOIN notification_delivery_log ndl ON an.id = ndl.notification_id AND ndl.success = true
--      LEFT JOIN notification_delivery_log ndl_all ON an.id = ndl_all.notification_id
--      WHERE an.is_hidden = false AND ndl.id IS NULL
--      GROUP BY an.id, an.user_id, an.message, an.notification_type, an.priority, an.job_id, an.action_data, an.created_at
--      ORDER BY an.created_at DESC
--      LIMIT limit_count
CREATE OR REPLACE FUNCTION public.get_undelivered_notifications(limit_count integer DEFAULT 50)
RETURNS TABLE (
  id uuid,
  user_id uuid,
  message text,
  notification_type text,
  priority text,
  job_id bigint,
  action_data jsonb,
  created_at timestamptz,
  max_retry_count integer,
  last_attempt_at timestamptz
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    an.id,
    an.user_id,
    an.message,
    an.notification_type,
    an.priority,
    an.job_id,
    an.action_data,
    an.created_at,
    COALESCE(MAX(ndl_all.retry_count), 0)::integer as max_retry_count,
    MAX(ndl_all.sent_at) as last_attempt_at
  FROM app_notifications an
  LEFT JOIN notification_delivery_log ndl 
    ON an.id = ndl.notification_id 
    AND ndl.success = true
  LEFT JOIN notification_delivery_log ndl_all
    ON an.id = ndl_all.notification_id
  WHERE an.is_hidden = false 
    AND ndl.id IS NULL
  GROUP BY an.id, an.user_id, an.message, an.notification_type, an.priority, an.job_id, an.action_data, an.created_at
  ORDER BY an.created_at DESC
  LIMIT limit_count;
END;
$$;

-- Set function owner
ALTER FUNCTION public.get_undelivered_notifications(integer) OWNER TO postgres;

-- Grant execute permission to service_role (for Edge Functions)
GRANT EXECUTE ON FUNCTION public.get_undelivered_notifications(integer) TO service_role;

-- Revoke from PUBLIC and anon (security)
REVOKE EXECUTE ON FUNCTION public.get_undelivered_notifications(integer) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.get_undelivered_notifications(integer) FROM anon;

-- Add comment
COMMENT ON FUNCTION public.get_undelivered_notifications(integer) IS
  'Returns undelivered notifications (no successful delivery log entry) sorted by newest first. Used by push-notifications-poller Edge Function.';

COMMIT;

