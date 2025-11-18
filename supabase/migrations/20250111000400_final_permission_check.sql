-- Final permission check and verification
-- Run this to see what permissions actually exist

-- Check sequence permissions
SELECT 
  'Sequence Permissions' as check_type,
  has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE') as has_usage,
  has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'SELECT') as has_select,
  has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'UPDATE') as has_update;

-- Check table permissions
SELECT 
  'Table Permissions' as check_type,
  has_table_privilege('postgres', 'net.http_request_queue', 'INSERT') as has_insert,
  has_table_privilege('postgres', 'net.http_request_queue', 'SELECT') as has_select,
  has_table_privilege('postgres', 'net.http_request_queue', 'UPDATE') as has_update;

-- Check who owns what
SELECT 
  n.nspname as schema,
  c.relname as object_name,
  c.relkind as object_type,
  pg_get_userbyid(c.relowner) as owner
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'net' 
  AND c.relname IN ('http_request_queue', 'http_request_queue_id_seq')
ORDER BY c.relname;

-- Check if postgres role has superuser privileges
SELECT 
  rolname,
  rolsuper,
  rolcreaterole,
  rolcreatedb
FROM pg_roles
WHERE rolname = 'postgres';



