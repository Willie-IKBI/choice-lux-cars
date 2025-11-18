-- Migration: Complete Fix for Cron Job Permissions
-- Purpose: Grant all necessary permissions for cron jobs to call Edge Functions via net.http_post
-- Created: 2025-01-11
-- Note: Even when cron job type is "Supabase Edge Function", it internally uses net.http_post

-- ============================================
-- Step 1: Grant permissions to postgres role
-- ============================================
-- postgres role is what cron jobs run as

-- Schema usage
GRANT USAGE ON SCHEMA net TO postgres;

-- Function execution
GRANT EXECUTE ON FUNCTION net.http_post(text, jsonb, jsonb, jsonb, integer) TO postgres;

-- Sequence permissions (CRITICAL - this is what's failing)
-- USAGE allows nextval(), currval(), setval()
GRANT USAGE, SELECT ON SEQUENCE net.http_request_queue_id_seq TO postgres;

-- Table permissions (only grant on tables that exist)
GRANT INSERT, UPDATE, SELECT ON TABLE net.http_request_queue TO postgres;

-- ============================================
-- Step 2: Also grant to service_role (backup)
-- ============================================
GRANT USAGE ON SCHEMA net TO service_role;
GRANT EXECUTE ON FUNCTION net.http_post(text, jsonb, jsonb, jsonb, integer) TO service_role;
GRANT USAGE, SELECT ON SEQUENCE net.http_request_queue_id_seq TO service_role;
GRANT INSERT, UPDATE, SELECT ON TABLE net.http_request_queue TO service_role;

-- ============================================
-- Step 3: Verify permissions (commented out - run manually to verify)
-- ============================================
-- Run these to verify permissions were granted:
-- SELECT has_schema_privilege('postgres', 'net', 'USAGE');
-- SELECT has_sequence_privilege('postgres', 'net.http_request_queue_id_seq', 'USAGE');
-- SELECT has_table_privilege('postgres', 'net.http_request_queue', 'INSERT');
-- SELECT has_function_privilege('postgres', 'net.http_post(text, jsonb, jsonb, jsonb, integer)', 'EXECUTE');

