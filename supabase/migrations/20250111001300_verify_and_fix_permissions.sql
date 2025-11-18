-- Migration: Verify and Fix Permissions
-- Purpose: Check current state and try alternative permission fixes
-- Created: 2025-01-11

-- ============================================
-- Step 1: Check current permissions
-- ============================================
-- Run these to see what permissions currently exist:
SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE') as postgres_usage;
SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'SELECT') as postgres_select;
SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'UPDATE') as postgres_update;

-- Check who owns the sequence
SELECT n.nspname as schema, c.relname as sequence, pg_get_userbyid(c.relowner) as owner
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'S' AND c.relname = 'http_request_queue_id_seq';

-- ============================================
-- Step 2: Try granting with explicit privileges
-- ============================================
DO $perm$
BEGIN
  -- Grant all privileges explicitly
  BEGIN
    EXECUTE 'GRANT USAGE, SELECT, UPDATE ON SEQUENCE net.http_request_queue_id_seq TO postgres';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Skipping sequence grant to postgres due to insufficient privileges';
  END;

  BEGIN
    EXECUTE 'GRANT USAGE, SELECT, UPDATE ON SEQUENCE net.http_request_queue_id_seq TO service_role';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Skipping sequence grant to service_role due to insufficient privileges';
  END;

  -- Also grant on the table
  BEGIN
    EXECUTE 'GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE net.http_request_queue TO postgres';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Skipping table grant to postgres due to insufficient privileges';
  END;

  BEGIN
    EXECUTE 'GRANT INSERT, SELECT, UPDATE, DELETE ON TABLE net.http_request_queue TO service_role';
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Skipping table grant to service_role due to insufficient privileges';
  END;

  -- ============================================
  -- Step 3: If above doesn't work, try ALTER DEFAULT PRIVILEGES
  -- ============================================
  BEGIN
    EXECUTE $stmt$ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA net
      GRANT ALL ON SEQUENCES TO postgres, service_role$stmt$;
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Skipping default privileges for sequences due to insufficient privileges';
  END;

  BEGIN
    EXECUTE $stmt$ALTER DEFAULT PRIVILEGES FOR ROLE supabase_admin IN SCHEMA net
      GRANT ALL ON TABLES TO postgres, service_role$stmt$;
  EXCEPTION
    WHEN insufficient_privilege THEN
      RAISE NOTICE 'Skipping default privileges for tables due to insufficient privileges';
  END;
END;
$perm$;

-- ============================================
-- Step 4: Verify after running
-- ============================================
-- Re-check permissions
SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE') as postgres_usage_after;
SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'UPDATE') as postgres_update_after;



