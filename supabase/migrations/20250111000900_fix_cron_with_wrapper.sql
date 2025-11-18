-- Migration: Create SECURITY DEFINER wrapper for cron jobs
-- Purpose: Bypass permission issues by using function owner's privileges
-- Created: 2025-01-11
-- Note: This function must be owned by a role with sequence permissions

-- Drop existing if any
DROP FUNCTION IF EXISTS public.http_post_for_cron(text, jsonb, jsonb, integer);

-- Create wrapper function with SECURITY DEFINER
-- The function owner (whoever runs this) will need sequence permissions
CREATE FUNCTION public.http_post_for_cron(
  p_url text,
  p_headers jsonb DEFAULT '{}'::jsonb,
  p_body jsonb DEFAULT '{}'::jsonb,
  p_timeout_milliseconds integer DEFAULT 30000
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, net
AS $$
DECLARE
  v_request_id bigint;
BEGIN
  -- Call net.http_post with SECURITY DEFINER privileges
  -- This should work if the function owner has permissions
  SELECT net.http_post(
    url := p_url,
    headers := p_headers,
    body := p_body,
    timeout_milliseconds := p_timeout_milliseconds
  ) INTO v_request_id;
  
  RETURN v_request_id;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION public.http_post_for_cron(text, jsonb, jsonb, integer) TO postgres;
GRANT EXECUTE ON FUNCTION public.http_post_for_cron(text, jsonb, jsonb, integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.http_post_for_cron(text, jsonb, jsonb, integer) TO authenticated;

COMMENT ON FUNCTION public.http_post_for_cron IS 
  'Wrapper for net.http_post using SECURITY DEFINER to bypass cron permission issues';



