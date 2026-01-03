-- Migration: Disable App Notifications Push Trigger
-- Date: 2026-01-03
-- Purpose: Disable the automatic push notification trigger due to pg_net sequence permission issues
--
-- Context:
-- - Trigger trg_app_notifications_push_after_insert attempts to queue HTTP requests via pg_net
-- - pg_net requires USAGE permission on net.http_request_queue_id_seq sequence
-- - Sequence is owned by supabase_admin and permissions cannot be granted via migration
-- - Trigger fails with "permission denied for sequence http_request_queue_id_seq"
-- - Push notifications will be handled via alternative mechanism (scheduled poller or manual invocation)
--
-- Note: Function notify_push_after_insert() is kept for reference but trigger is disabled.

BEGIN;

-- Drop the trigger to prevent automatic push notification attempts
DROP TRIGGER IF EXISTS trg_app_notifications_push_after_insert ON public.app_notifications;

-- Add comment to the function explaining why it's disabled
COMMENT ON FUNCTION public.notify_push_after_insert() IS
  'Trigger function for automatic push notification queuing. DISABLED: pg_net sequence permission issue prevents queueing. Sequence net.http_request_queue_id_seq is owned by supabase_admin and requires manual permission grant. Push notifications will be handled via alternative mechanism (scheduled poller or manual edge function invocation).';

COMMIT;

