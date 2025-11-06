-- Debug: Check what's actually happening with permissions
-- Run this to see the full picture

-- 1. Check sequence owner and current grants
SELECT 
  n.nspname as schema,
  c.relname as sequence_name,
  pg_get_userbyid(c.relowner) as owner,
  c.relacl as access_privileges  -- This shows actual ACL (Access Control List)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'S' 
  AND c.relname = 'http_request_queue_id_seq';

-- 2. Check if postgres role exists and its privileges
SELECT 
  rolname,
  rolsuper,
  rolcreaterole,
  rolcreatedb,
  rolcanlogin,
  oid
FROM pg_roles
WHERE rolname IN ('postgres', 'supabase_admin', 'service_role')
ORDER BY rolname;

-- 3. Try to see what grants actually exist (if any)
SELECT 
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_usage_grants
WHERE object_schema = 'net' 
  AND object_name = 'http_request_queue_id_seq';

-- 4. Try granting again, but this time check for errors
DO $$
BEGIN
  -- Try to grant and catch any errors
  BEGIN
    GRANT ALL PRIVILEGES ON SEQUENCE net.http_request_queue_id_seq TO postgres;
    RAISE NOTICE 'GRANT succeeded';
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'GRANT failed: %', SQLERRM;
  END;
END $$;

-- 5. Immediately check if it worked
SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE') as has_usage_after;



