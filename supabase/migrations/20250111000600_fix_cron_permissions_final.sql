-- Migration: Final Fix for Cron Job Permissions
-- Purpose: Grant permissions on sequence owned by supabase_admin
-- Created: 2025-01-11
-- Note: Sequence is owned by supabase_admin, so we need explicit grants

-- First, check current permissions (run this to verify):
-- SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE');
-- SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'SELECT');

-- ============================================
-- Grant ALL permissions on sequence
-- ============================================
-- Since sequence is owned by supabase_admin, we need to grant as superuser
-- This should be run by a user with superuser privileges (postgres role should work)
GRANT ALL PRIVILEGES ON SEQUENCE net.http_request_queue_id_seq TO postgres;
GRANT ALL PRIVILEGES ON SEQUENCE net.http_request_queue_id_seq TO service_role;

-- Also try granting to authenticated role (in case cron uses it)
GRANT ALL PRIVILEGES ON SEQUENCE net.http_request_queue_id_seq TO authenticated;

-- ============================================
-- Ensure all related permissions
-- ============================================
-- Schema
GRANT USAGE ON SCHEMA net TO postgres;
GRANT USAGE ON SCHEMA net TO service_role;
GRANT USAGE ON SCHEMA net TO authenticated;

-- Function
GRANT EXECUTE ON FUNCTION net.http_post(text, jsonb, jsonb, jsonb, integer) TO postgres;
GRANT EXECUTE ON FUNCTION net.http_post(text, jsonb, jsonb, jsonb, integer) TO service_role;
GRANT EXECUTE ON FUNCTION net.http_post(text, jsonb, jsonb, jsonb, integer) TO authenticated;

-- Table
GRANT ALL PRIVILEGES ON TABLE net.http_request_queue TO postgres;
GRANT ALL PRIVILEGES ON TABLE net.http_request_queue TO service_role;
GRANT ALL PRIVILEGES ON TABLE net.http_request_queue TO authenticated;

-- ============================================
-- Verify after running (check these):
-- ============================================
-- SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE');
-- SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'SELECT');
-- SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'UPDATE');



