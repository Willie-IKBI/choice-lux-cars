-- Migration: Fix pg_net Sequence Permissions
-- Date: 2025-01-22
-- Purpose: Grant postgres role minimum required permissions on net.http_request_queue_id_seq
--          to allow pg_net HTTP requests to enqueue successfully
--
-- Context:
-- - net.http_post() is NOT SECURITY DEFINER, so it executes as caller (postgres)
-- - postgres needs USAGE permission on sequence for nextval() to work
-- - Sequence owner is supabase_admin with ACL only for supabase_admin
-- - This grants minimum permissions needed: USAGE and UPDATE on sequence, INSERT on table
--
-- NOTE: Since the sequence is owned by supabase_admin, we attempt to SET ROLE to supabase_admin
--       to grant permissions. If that fails, this migration will need to be run manually via
--       Supabase dashboard or by a user with supabase_admin privileges.

BEGIN;

-- Ensure postgres has schema USAGE (should already exist, but verify)
GRANT USAGE ON SCHEMA net TO postgres;

-- Attempt to grant permissions using DO block with role switching
DO $body$
DECLARE
  role_switched boolean := false;
BEGIN
  -- Try to elevate to supabase_admin to grant permissions
  BEGIN
    EXECUTE 'SET ROLE supabase_admin';
    role_switched := true;
    RAISE NOTICE 'Successfully switched to supabase_admin role';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE WARNING 'Unable to SET ROLE supabase_admin; grants may fail. Migration may need to be run manually.';
  END;

  -- Grant minimum required permissions on sequence for nextval() to work
  -- USAGE: Required for nextval() function calls
  -- UPDATE: Required for sequence value updates
  BEGIN
    EXECUTE 'GRANT USAGE, UPDATE ON SEQUENCE net.http_request_queue_id_seq TO postgres';
    RAISE NOTICE 'Successfully granted USAGE and UPDATE on sequence to postgres';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE WARNING 'Failed to grant sequence permissions. Migration may need to be run manually as supabase_admin.';
  END;

  -- Ensure postgres has INSERT permission on the queue table (should already exist, but verify)
  BEGIN
    EXECUTE 'GRANT INSERT ON TABLE net.http_request_queue TO postgres';
    RAISE NOTICE 'Successfully granted INSERT on table to postgres';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE WARNING 'Failed to grant table INSERT permission.';
  END;

  -- Reset the role if we successfully switched
  IF role_switched THEN
    BEGIN
      EXECUTE 'RESET ROLE';
    EXCEPTION
      WHEN others THEN
        RAISE NOTICE 'Unable to RESET ROLE, continuing';
    END;
  END IF;
END;
$body$;

-- Add comment documenting the grant
COMMENT ON SEQUENCE net.http_request_queue_id_seq IS
  'pg_net HTTP request queue sequence. postgres role has USAGE and UPDATE permissions to allow nextval() calls from non-SECURITY-DEFINER functions.';

COMMIT;

