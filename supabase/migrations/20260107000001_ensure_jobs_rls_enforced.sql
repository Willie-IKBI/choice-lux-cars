-- Migration: Ensure Jobs RLS Policy is Correctly Enforced
-- Date: 2026-01-07
-- Purpose: Verify and enforce that drivers can ONLY see jobs allocated to them
--          This ensures both application-level and database-level security

BEGIN;

-- Ensure RLS is enabled on jobs table
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;

-- Drop existing policy if it exists to recreate with correct logic
DROP POLICY IF EXISTS jobs_select_policy ON public.jobs;

-- Create/Recreate the SELECT policy with role-based access control
-- This ensures drivers can ONLY see jobs where driver_id matches their auth.uid()
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
    -- Managers see all jobs (full access like administrators)
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'manager'
    )
    OR
    -- Drivers see ONLY jobs assigned to them (driver_id must match auth.uid())
    (jobs.driver_id = auth.uid() AND EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'driver'
    ))
    OR
    -- Driver managers see jobs they created or jobs assigned to them
    (EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'driver_manager'
    ) AND (
        jobs.created_by = auth.uid()::text
        OR jobs.driver_id = auth.uid()
    ))
);

-- Add comment explaining the policy
COMMENT ON POLICY jobs_select_policy ON public.jobs IS 
'Role-based SELECT access: drivers see ONLY assigned jobs (driver_id = auth.uid()), managers see all jobs, admins see all jobs. This enforces security at the database level.';

COMMIT;

