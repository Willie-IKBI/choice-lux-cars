-- Migration: Create HTTP POST wrapper function
-- Purpose: Workaround for cron job permissions by using SECURITY DEFINER
-- Created: 2025-01-11
-- Note: This function runs with the privileges of the function owner (postgres/superuser)

-- Create a wrapper function that runs with SECURITY DEFINER
-- This allows the function to execute with the owner's privileges
CREATE OR REPLACE FUNCTION public.http_post_for_cron(
  p_url text,
  p_headers jsonb DEFAULT '{}'::jsonb,
  p_body jsonb DEFAULT '{}'::jsonb,
  p_timeout_milliseconds integer DEFAULT 30000
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER -- This is the key: runs with function owner's privileges
SET search_path = public, net
AS $$
DECLARE
  v_request_id bigint;
BEGIN
  -- Call the net.http_post function
  -- Since we're SECURITY DEFINER, we have the privileges needed
  SELECT net.http_post(
    url := p_url,
    headers := p_headers,
    body := p_body,
    timeout_milliseconds := p_timeout_milliseconds
  ) INTO v_request_id;
  
  RETURN v_request_id;
END;
$$;

-- Grant execute to postgres and service_role
GRANT EXECUTE ON FUNCTION public.http_post_for_cron(text, jsonb, jsonb, integer) TO postgres;
GRANT EXECUTE ON FUNCTION public.http_post_for_cron(text, jsonb, jsonb, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.http_post_for_cron(text, jsonb, jsonb, integer) TO authenticated;

-- Add comment
COMMENT ON FUNCTION public.http_post_for_cron IS 
  'Wrapper for net.http_post that runs with SECURITY DEFINER to bypass permission issues in cron jobs';



