-- Migration: Role-based job visibility
-- Date: 2026-02-25
-- Purpose: Restrict job visibility by role:
--   - Administrator / super_admin: see all jobs
--   - Manager: see only jobs for their branch (jobs.location = profiles.branch_id)
--   - Driver / driver_manager: see only jobs where they are the driver (driver_id = auth.uid())

BEGIN;

DROP POLICY IF EXISTS jobs_select_policy ON public.jobs;

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
    -- Managers see only jobs for their branch
    EXISTS (
        SELECT 1
        FROM public.profiles p
        WHERE p.id = auth.uid()
        AND p.role = 'manager'
        AND p.branch_id IS NOT NULL
        AND jobs.location = p.branch_id
    )
    OR
    -- Drivers see only jobs assigned to them
    (jobs.driver_id = auth.uid() AND EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'driver'
    ))
    OR
    -- Driver managers see only jobs where they are the driver
    (EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role = 'driver_manager'
    ) AND jobs.driver_id = auth.uid())
);

COMMENT ON POLICY jobs_select_policy ON public.jobs IS
'Role-based SELECT: admins/super_admin see all; managers see branch jobs only (jobs.location = profiles.branch_id); drivers and driver_managers see only jobs where driver_id = auth.uid().';

COMMIT;
