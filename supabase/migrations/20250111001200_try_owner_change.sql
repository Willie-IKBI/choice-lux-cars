-- Try to change sequence owner or grant as superuser
-- This might work if postgres has sufficient privileges

-- First, check if we can see who owns it and what privileges postgres has
SELECT 
  n.nspname as schema,
  c.relname as sequence_name,
  pg_get_userbyid(c.relowner) as owner,
  c.relowner::regrole as owner_role
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'S' 
  AND c.relname = 'http_request_queue_id_seq';

-- Check if postgres is a superuser
SELECT 
  rolname,
  rolsuper,
  rolcreaterole,
  rolcreatedb,
  rolcanlogin
FROM pg_roles
WHERE rolname IN ('postgres', 'supabase_admin', 'service_role');

-- Try to grant permissions as if we're a superuser
-- (This should work if postgres is actually a superuser)
GRANT ALL PRIVILEGES ON SEQUENCE net.http_request_queue_id_seq TO postgres WITH GRANT OPTION;

-- Alternative: Try to change the sequence owner to postgres
-- (This might be blocked by Supabase, but worth trying)
-- ALTER SEQUENCE net.http_request_queue_id_seq OWNER TO postgres;

-- Verify after attempting
SELECT 
  has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE') as has_usage,
  has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'UPDATE') as has_update;



