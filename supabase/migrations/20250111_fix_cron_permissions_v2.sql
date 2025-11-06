-- Migration: Fix Cron Job Permissions v2
-- Purpose: More comprehensive permissions for pg_net sequence access
-- Created: 2025-01-11

-- First, verify the sequence exists and check its current permissions
-- Run this to see current state:
-- SELECT schemaname, sequencename, sequenceowner 
-- FROM pg_sequences 
-- WHERE sequencename = 'http_request_queue_id_seq';

-- ============================================
-- Grant ALL permissions on sequence (more permissive)
-- ============================================
-- Some versions of PostgreSQL require ALL instead of just USAGE + SELECT
GRANT ALL ON SEQUENCE net.http_request_queue_id_seq TO postgres;
GRANT ALL ON SEQUENCE net.http_request_queue_id_seq TO service_role;

-- ============================================
-- Ensure all related permissions are granted
-- ============================================
-- Schema
GRANT USAGE ON SCHEMA net TO postgres;
GRANT USAGE ON SCHEMA net TO service_role;

-- Function
GRANT EXECUTE ON FUNCTION net.http_post(text, jsonb, jsonb, jsonb, integer) TO postgres;
GRANT EXECUTE ON FUNCTION net.http_post(text, jsonb, jsonb, jsonb, integer) TO service_role;

-- Table (needed for INSERT which uses the sequence)
GRANT ALL ON TABLE net.http_request_queue TO postgres;
GRANT ALL ON TABLE net.http_request_queue TO service_role;

-- ============================================
-- Alternative: If above doesn't work, try granting to PUBLIC
-- ============================================
-- Uncomment if needed (less secure but should work):
-- GRANT USAGE ON SEQUENCE net.http_request_queue_id_seq TO PUBLIC;
-- GRANT ALL ON SEQUENCE net.http_request_queue_id_seq TO PUBLIC;



