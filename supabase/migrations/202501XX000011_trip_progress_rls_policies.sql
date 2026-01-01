-- Migration 11: Trip Progress RLS Policies
-- Purpose: Enable Row Level Security on trip_progress table with granular access control
-- Based on: ai/DRIVER_JOB_FLOW.md and database contract requirements
-- Prerequisites: Migrations 1-10 must be applied
--
-- This migration:
-- 1) Enables RLS on public.trip_progress
-- 2) Drops any legacy permissive policies
-- 3) Creates granular policies for SELECT, UPDATE, INSERT, DELETE
-- 4) Ensures only drivers can update trip_progress for their assigned jobs
-- 5) Blocks direct INSERTs (must use trigger/function)
-- 6) Blocks all DELETEs

BEGIN;

-- ============================================================================
-- A) Enable RLS
-- ============================================================================

ALTER TABLE public.trip_progress ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- B) Drop legacy permissive policies (safe)
-- ============================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT pol.polname
        FROM pg_policy pol
        JOIN pg_class rel ON rel.oid = pol.polrelid
        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE nsp.nspname = 'public'
          AND rel.relname = 'trip_progress'
          AND pol.polcmd = 'all'
          AND pg_get_expr(pol.polqual, pol.polrelid) = 'true'
          AND pg_get_expr(pol.polwithcheck, pol.polrelid) = 'true'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.trip_progress', r.polname);
        RAISE NOTICE 'Dropped legacy permissive policy: %', r.polname;
    END LOOP;
END $$;

-- ============================================================================
-- C) Create granular RLS policies
-- ============================================================================

-- Policy 1: SELECT - Drivers, managers, and administrators
-- Assumes: profiles.id == auth.uid() (same UUID value)
CREATE POLICY trip_progress_select_policy ON public.trip_progress
FOR SELECT
TO authenticated
USING (
    -- Allow if user is the driver or manager of the job
    EXISTS (
        SELECT 1
        FROM public.jobs
        WHERE jobs.id = trip_progress.job_id
        AND (jobs.driver_id = auth.uid() OR jobs.manager_id = auth.uid())
    )
    OR
    -- Allow if user is an administrator
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('administrator', 'super_admin')
    )
);

COMMENT ON POLICY trip_progress_select_policy ON public.trip_progress IS 
    'Allows SELECT for job drivers, job managers, and administrators. Assumes profiles.id == auth.uid() (same UUID value).';

-- Policy 2: UPDATE - Drivers only for their assigned jobs
-- Assumes: profiles.id == auth.uid() (same UUID value)
CREATE POLICY trip_progress_update_policy ON public.trip_progress
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.jobs
        WHERE jobs.id = trip_progress.job_id
        AND jobs.driver_id = auth.uid()
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1
        FROM public.jobs
        WHERE jobs.id = trip_progress.job_id
        AND jobs.driver_id = auth.uid()
    )
);

COMMENT ON POLICY trip_progress_update_policy ON public.trip_progress IS 
    'Allows UPDATE only for drivers assigned to the job. Managers cannot update trip_progress. Assumes profiles.id == auth.uid() (same UUID value).';

-- Policy 3: INSERT - Block direct inserts
-- Rationale: Inserts are done via trigger/security definer init function (init_trip_progress_for_job)
CREATE POLICY trip_progress_insert_policy ON public.trip_progress
FOR INSERT
TO authenticated
WITH CHECK (false);

COMMENT ON POLICY trip_progress_insert_policy ON public.trip_progress IS 
    'Blocks all direct INSERTs. All inserts must go through init_trip_progress_for_job() SECURITY DEFINER function, which bypasses RLS.';

-- Policy 4: DELETE - Block all deletes
CREATE POLICY trip_progress_delete_policy ON public.trip_progress
FOR DELETE
TO authenticated
USING (false);

COMMENT ON POLICY trip_progress_delete_policy ON public.trip_progress IS 
    'Blocks all DELETE operations. Trip progress rows are immutable once created.';

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

