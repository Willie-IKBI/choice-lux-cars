-- Try to grant permissions as supabase_admin
-- This might work if we can switch roles

-- First, check what role we're currently running as
SELECT current_user, session_user;

-- Try to set role to supabase_admin (might not work, but worth trying)
SET ROLE supabase_admin;

-- Now try granting as supabase_admin
GRANT USAGE, SELECT, UPDATE ON SEQUENCE net.http_request_queue_id_seq TO postgres;
GRANT USAGE, SELECT, UPDATE ON SEQUENCE net.http_request_queue_id_seq TO service_role;

-- Check if it worked
SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE') as has_usage;

-- Reset role
RESET ROLE;



