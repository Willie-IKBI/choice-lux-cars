-- Migration: Fix cron job permissions for net.http_post
-- Purpose: Grant permissions needed for cron jobs (even when using Edge Function type)
-- Created: 2025-01-11

-- Grant permissions to postgres role (used by cron jobs)
-- Even when using Edge Function type, Supabase may internally use net.http_post

-- Grant usage on pg_net schema
GRANT USAGE ON SCHEMA net TO postgres;

-- Grant execute on http_post function  
GRANT EXECUTE ON FUNCTION net.http_post(text, jsonb, jsonb, jsonb, integer) TO postgres;

-- Grant ALL permissions on the sequence (needed for nextval())
-- Note: USAGE allows nextval(), currval(), setval()
GRANT USAGE, SELECT ON SEQUENCE net.http_request_queue_id_seq TO postgres;

-- Grant insert and update on http_request_queue table (update needed for queue processing)
GRANT INSERT, UPDATE ON TABLE net.http_request_queue TO postgres;

-- Grant select on http_response_queue table (for response processing)
GRANT SELECT ON TABLE net.http_response_queue TO postgres;

-- Also grant to authenticated role (in case cron runs with different user context)
GRANT USAGE ON SCHEMA net TO authenticated;
GRANT EXECUTE ON FUNCTION net.http_post(text, jsonb, jsonb, jsonb, integer) TO authenticated;
GRANT USAGE, SELECT ON SEQUENCE net.http_request_queue_id_seq TO authenticated;
GRANT INSERT, UPDATE ON TABLE net.http_request_queue TO authenticated;
GRANT SELECT ON TABLE net.http_response_queue TO authenticated;
