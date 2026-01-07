-- Migration: Auto-cleanup notifications older than 15 days
-- Date: 2026-01-08
-- Purpose: Keep only the last 15 days of notifications to prevent table bloat

BEGIN;

-- Step 1: Create function to delete old notifications
CREATE OR REPLACE FUNCTION public.cleanup_old_notifications()
RETURNS TABLE(deleted_count bigint) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  deleted_rows bigint;
BEGIN
  -- Delete notifications older than 15 days
  DELETE FROM public.app_notifications
  WHERE created_at < NOW() - INTERVAL '15 days';
  
  GET DIAGNOSTICS deleted_rows = ROW_COUNT;
  
  -- Log the cleanup
  RAISE NOTICE 'Cleaned up % notifications older than 15 days', deleted_rows;
  
  RETURN QUERY SELECT deleted_rows;
END;
$$;

-- Step 2: Grant execute permission
GRANT EXECUTE ON FUNCTION public.cleanup_old_notifications() TO service_role;
GRANT EXECUTE ON FUNCTION public.cleanup_old_notifications() TO authenticated;

-- Step 3: Set up pg_cron job to run daily at 2 AM UTC
-- Note: pg_cron must be enabled in your Supabase project
-- This will fail gracefully if pg_cron is not enabled
DO $$
BEGIN
  -- Check if pg_cron extension exists and schedule the job
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    PERFORM cron.schedule(
      'cleanup-old-notifications-daily',
      '0 2 * * *', -- Daily at 2:00 AM UTC
      'SELECT public.cleanup_old_notifications();'
    );
    RAISE NOTICE 'Cron job scheduled: cleanup-old-notifications-daily';
  ELSE
    RAISE NOTICE 'pg_cron extension not enabled. Please enable it in Supabase Dashboard -> Database -> Extensions, then run: SELECT cron.schedule(''cleanup-old-notifications-daily'', ''0 2 * * *'', ''SELECT public.cleanup_old_notifications();'');';
  END IF;
END;
$$;

-- Step 4: Run cleanup once immediately to clean existing old data
SELECT public.cleanup_old_notifications();

-- Add comments for documentation
COMMENT ON FUNCTION public.cleanup_old_notifications() IS 
  'Deletes notifications older than 15 days. Called automatically by pg_cron daily at 2 AM UTC.';

COMMIT;

