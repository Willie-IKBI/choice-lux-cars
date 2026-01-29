-- =============================================================================
-- job_progress_summary: SECURITY DEFINER → SECURITY INVOKER
-- Run in Supabase SQL Editor when implementing the fix.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1) CHECK: Current view security property
-- -----------------------------------------------------------------------------
SELECT
  c.relname AS view_name,
  CASE c.relkind
    WHEN 'v' THEN 'view'
  END AS kind,
  -- security_invoker: true = INVOKER, false = DEFINER (pg 15+)
  (SELECT option_value FROM pg_options_to_table(c.reloptions) WHERE option_name = 'security_invoker') AS security_invoker_option
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'job_progress_summary';
-- Expected before fix: security_invoker_option is NULL or 'false' (DEFINER).
-- Expected after fix: security_invoker_option = 'on' or 'true' (INVOKER).


-- -----------------------------------------------------------------------------
-- 2) FIX: Set view to SECURITY INVOKER (Postgres 15+)
-- -----------------------------------------------------------------------------
ALTER VIEW public.job_progress_summary SET (security_invoker = on);

-- If your Postgres is < 15: you must recreate the view. Get definition with:
--   SELECT pg_get_viewdef('public.job_progress_summary', true);
-- Then: DROP VIEW public.job_progress_summary; CREATE VIEW ... WITH (security_invoker = on) AS <definition>;


-- -----------------------------------------------------------------------------
-- 3) VERIFY: View still returns data (run as a role that should see rows)
-- -----------------------------------------------------------------------------
-- As service_role or an admin, you should see rows (subject to RLS on base tables).
SELECT COUNT(*) AS row_count FROM public.job_progress_summary;


-- -----------------------------------------------------------------------------
-- 4) TEST: As a driver (optional – run in a session with auth.uid() = driver)
-- -----------------------------------------------------------------------------
-- If the view uses jobs/driver_flow/trip_progress, RLS on jobs will apply.
-- Drivers should see only their assigned jobs. Example (replace with real job_id/driver_id):
-- SET request.jwt.claim.sub = '<driver_uuid>';  -- Supabase may not support this in SQL Editor.
-- So: test as driver via app or by using Supabase Auth as that user, then:
--   SELECT * FROM public.job_progress_summary LIMIT 10;
-- Expected: only rows for jobs where jobs.driver_id = auth.uid() (or admin sees all).


-- -----------------------------------------------------------------------------
-- 5) RE-CHECK: Confirm view is now INVOKER
-- -----------------------------------------------------------------------------
SELECT
  c.relname AS view_name,
  (SELECT option_value FROM pg_options_to_table(c.reloptions) WHERE option_name = 'security_invoker') AS security_invoker_option
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'job_progress_summary';
-- Expected: security_invoker_option = 'on'.
