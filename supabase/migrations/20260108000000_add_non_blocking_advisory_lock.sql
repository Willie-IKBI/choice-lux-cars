-- Migration: Add Non-Blocking Advisory Lock Function
-- Date: 2026-01-08
-- Purpose: Add pg_try_advisory_lock wrapper that doesn't block, preventing 500 errors from timeouts
--
-- Context:
-- - The blocking pg_advisory_lock can cause 500 errors if lock is held by another session
-- - pg_try_advisory_lock returns immediately (true if acquired, false if already held)
-- - This prevents Edge Function timeouts and improves reliability
--
-- Related:
-- - Migration 20260103180000_add_advisory_lock_wrappers.sql (blocking version)
-- - Edge Function: push-notifications-poller/index.ts

BEGIN;

-- Create non-blocking wrapper function for pg_try_advisory_lock
CREATE OR REPLACE FUNCTION public.pg_try_advisory_lock(p_lock_key bigint)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  RETURN pg_catalog.pg_try_advisory_lock(p_lock_key);
END;
$$;

-- Grant execute to service_role (for Edge Functions)
GRANT EXECUTE ON FUNCTION public.pg_try_advisory_lock(bigint) TO service_role;

-- Add comment
COMMENT ON FUNCTION public.pg_try_advisory_lock(bigint) IS
  'Non-blocking wrapper for pg_try_advisory_lock. Returns true if lock acquired, false if already held. Prevents Edge Function timeouts.';

COMMIT;
