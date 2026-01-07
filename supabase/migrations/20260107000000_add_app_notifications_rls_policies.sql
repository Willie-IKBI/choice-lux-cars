-- Migration: Add RLS Policies for app_notifications Table
-- Date: 2026-01-07
-- Purpose: Enable Row Level Security and add policies to allow authenticated users
--          to insert, select, and update notifications. This fixes 403 errors when
--          creating notifications from the Flutter app.

BEGIN;

-- Enable RLS on app_notifications table (if not already enabled)
ALTER TABLE public.app_notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS allow_authenticated_insert ON public.app_notifications;
DROP POLICY IF EXISTS allow_service_role_all ON public.app_notifications;
DROP POLICY IF EXISTS allow_anon_insert ON public.app_notifications;
DROP POLICY IF EXISTS allow_users_view_own ON public.app_notifications;
DROP POLICY IF EXISTS allow_users_update_own ON public.app_notifications;

-- Policy 1: Allow authenticated users to INSERT notifications
-- This allows users to create notifications for themselves or others (for system notifications)
CREATE POLICY allow_authenticated_insert ON public.app_notifications
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Policy 2: Allow service role full access (for edge functions and cron jobs)
CREATE POLICY allow_service_role_all ON public.app_notifications
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Policy 3: Allow anonymous inserts (for webhooks if needed)
-- Note: This may not be necessary if webhooks use service_role, but included for completeness
CREATE POLICY allow_anon_insert ON public.app_notifications
  FOR INSERT
  TO anon
  WITH CHECK (true);

-- Policy 4: Allow users to SELECT their own notifications
CREATE POLICY allow_users_view_own ON public.app_notifications
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Policy 5: Allow users to UPDATE their own notifications (mark as read, dismiss, etc.)
CREATE POLICY allow_users_update_own ON public.app_notifications
  FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Add comments for documentation
COMMENT ON POLICY allow_authenticated_insert ON public.app_notifications IS
  'Allows any authenticated user to insert notifications. This enables system notifications and user-created notifications.';

COMMENT ON POLICY allow_service_role_all ON public.app_notifications IS
  'Allows service_role (edge functions, cron jobs) full access to all notifications.';

COMMENT ON POLICY allow_anon_insert ON public.app_notifications IS
  'Allows anonymous users to insert notifications (for webhook compatibility if needed).';

COMMENT ON POLICY allow_users_view_own ON public.app_notifications IS
  'Allows users to view only their own notifications (user_id = auth.uid()).';

COMMENT ON POLICY allow_users_update_own ON public.app_notifications IS
  'Allows users to update only their own notifications (mark as read, dismiss, etc.).';

COMMIT;

