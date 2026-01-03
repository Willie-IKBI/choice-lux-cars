-- Migration 13: Jobs RLS Policies
-- Purpose: Replace permissive RLS policy with role-based access control
-- Security Fix: Drivers must ONLY see jobs allocated to them
--
-- Critical Assumption: profiles.id == auth.uid() (same UUID value)
-- This assumption is used throughout all RLS policies.
--
-- Prerequisites: 
--   - profiles table exists with role column
--   - jobs table has driver_id and manager_id columns (uuid, nullable)
--   - RLS is already enabled on jobs table

BEGIN;

-- ============================================================================
-- A) Drop existing permissive SELECT policy
-- ============================================================================

DROP POLICY IF EXISTS "jobs_select_policy" ON public.jobs;

-- ============================================================================
-- B) Create granular SELECT policy with role-based access
-- ============================================================================

-- Policy: Drivers can SELECT only jobs assigned to them
-- Managers can SELECT jobs they manage
-- Administrators can SELECT all jobs
CREATE POLICY jobs_select_policy ON public.jobs
FOR SELECT
TO authenticated
USING (
    -- Administrators and super_admin see all jobs
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('administrator', 'super_admin')
    )
    OR
    -- Managers see jobs they manage
    (jobs.manager_id = auth.uid() AND EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'manager'
    ))
    OR
    -- Drivers see jobs assigned to them
    (jobs.driver_id = auth.uid() AND EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'driver'
    ))
    OR
    -- Driver managers see jobs they created or manage (NOT driver_id to prevent duplicates)
    (EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'driver_manager'
    ) AND (
        jobs.created_by = auth.uid()::text
        OR jobs.manager_id = auth.uid()
    ))
);

-- ============================================================================
-- C) Add comment to policy
-- ============================================================================

COMMENT ON POLICY jobs_select_policy ON public.jobs IS 
'Role-based SELECT access: drivers see assigned jobs, managers see managed jobs, admins see all. Assumes profiles.id == auth.uid().';

-- ============================================================================
-- D) Verify RLS is enabled (should already be enabled, but ensure)
-- ============================================================================

ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

COMMIT;

