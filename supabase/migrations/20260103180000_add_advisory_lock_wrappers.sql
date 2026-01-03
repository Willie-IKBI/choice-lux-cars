-- Migration: Add Advisory Lock Wrapper Functions
-- Date: 2026-01-03
-- Purpose: Create wrapper functions for pg_advisory_lock/unlock to allow Edge Functions to use them
--
-- Context:
-- - Edge Functions need to call pg_advisory_lock for concurrency safety
-- - Built-in pg_advisory_lock functions are not directly callable via RPC
-- - Wrapper functions with SECURITY DEFINER allow service_role to use them

BEGIN;

-- Create wrapper function for pg_advisory_lock
CREATE OR REPLACE FUNCTION public.pg_advisory_lock(p_lock_key bigint)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  PERFORM pg_catalog.pg_advisory_lock(p_lock_key);
  RETURN true;
END;
$$;

-- Create wrapper function for pg_advisory_unlock
CREATE OR REPLACE FUNCTION public.pg_advisory_unlock(p_lock_key bigint)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
BEGIN
  PERFORM pg_catalog.pg_advisory_unlock(p_lock_key);
  RETURN true;
END;
$$;

-- Grant execute to service_role (for Edge Functions)
GRANT EXECUTE ON FUNCTION public.pg_advisory_lock(bigint) TO service_role;
GRANT EXECUTE ON FUNCTION public.pg_advisory_unlock(bigint) TO service_role;

-- Add comments
COMMENT ON FUNCTION public.pg_advisory_lock(bigint) IS
  'Wrapper for pg_advisory_lock to allow Edge Functions to acquire advisory locks for concurrency control.';

COMMENT ON FUNCTION public.pg_advisory_unlock(bigint) IS
  'Wrapper for pg_advisory_unlock to allow Edge Functions to release advisory locks.';

COMMIT;

