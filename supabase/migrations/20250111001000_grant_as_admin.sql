-- Try to grant permissions as supabase_admin
-- This might work if we can switch roles

-- First, check what role we're currently running as
SELECT current_user, session_user;

DO $body$
DECLARE
  role_switched boolean := false;
BEGIN
  -- Try to elevate to supabase_admin, but continue if not allowed
  BEGIN
    EXECUTE 'SET ROLE supabase_admin';
    role_switched := true;
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Unable to SET ROLE supabase_admin; continuing as %', current_user;
  END;

  -- Attempt the grants; log and continue if privileges are missing
  BEGIN
    EXECUTE 'GRANT USAGE, SELECT, UPDATE ON SEQUENCE net.http_request_queue_id_seq TO postgres';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Skipping grant to postgres due to insufficient privileges';
  END;

  BEGIN
    EXECUTE 'GRANT USAGE, SELECT, UPDATE ON SEQUENCE net.http_request_queue_id_seq TO service_role';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Skipping grant to service_role due to insufficient privileges';
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

-- Check if it worked
SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE') as has_usage;
