-- Migration: Manager Job Update Rights
-- Date: 2026-03-02
-- Purpose: Enable managers to update/edit jobs, driver_flow, and trip_progress
--          within their allocated branch. Previously, managers could see jobs
--          but RLS blocked their updates.

BEGIN;

-- ============================================
-- JOBS TABLE UPDATE POLICY
-- ============================================

-- Drop existing jobs_update_policy
DROP POLICY IF EXISTS jobs_update_policy ON public.jobs;

-- Create new jobs_update_policy with manager branch-scoped access
CREATE POLICY jobs_update_policy ON public.jobs
FOR UPDATE TO authenticated
USING (
    -- Admin/super_admin: update all jobs
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('administrator', 'super_admin')
    )
    OR
    -- Manager: update jobs in their branch only
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role = 'manager' 
        AND p.branch_id IS NOT NULL 
        AND jobs.branch_id = p.branch_id
    )
    OR
    -- Driver: update their assigned job
    driver_id = auth.uid()
)
WITH CHECK (
    -- Same conditions for WITH CHECK
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('administrator', 'super_admin')
    )
    OR
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role = 'manager' 
        AND p.branch_id IS NOT NULL 
        AND jobs.branch_id = p.branch_id
    )
    OR
    driver_id = auth.uid()
);

COMMENT ON POLICY jobs_update_policy ON public.jobs IS
'UPDATE policy: admins update all; managers update branch jobs; drivers update assigned jobs.';

-- ============================================
-- DRIVER_FLOW TABLE UPDATE POLICY
-- ============================================

-- Drop existing admin update policy
DROP POLICY IF EXISTS driver_flow_admin_update ON public.driver_flow;

-- Create new policy with manager branch-scoped access
CREATE POLICY driver_flow_admin_manager_update ON public.driver_flow
FOR UPDATE TO authenticated
USING (
    -- Admin/super_admin: update all driver_flow records
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('administrator', 'super_admin')
    )
    OR
    -- Manager: update driver_flow for jobs in their branch
    EXISTS (
        SELECT 1 FROM public.profiles p
        INNER JOIN public.jobs j ON j.branch_id = p.branch_id
        WHERE p.id = auth.uid() 
        AND p.role = 'manager' 
        AND j.id = driver_flow.job_id
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('administrator', 'super_admin')
    )
    OR
    EXISTS (
        SELECT 1 FROM public.profiles p
        INNER JOIN public.jobs j ON j.branch_id = p.branch_id
        WHERE p.id = auth.uid() 
        AND p.role = 'manager' 
        AND j.id = driver_flow.job_id
    )
);

COMMENT ON POLICY driver_flow_admin_manager_update ON public.driver_flow IS
'UPDATE policy for admin/manager: admins update all; managers update driver_flow for jobs in their branch.';

-- ============================================
-- TRIP_PROGRESS TABLE UPDATE POLICY
-- ============================================

-- Drop existing trip_progress_update_policy
DROP POLICY IF EXISTS trip_progress_update_policy ON public.trip_progress;

-- Create new policy with manager branch-scoped access
CREATE POLICY trip_progress_update_policy ON public.trip_progress
FOR UPDATE TO authenticated
USING (
    -- Driver: update their job's trips
    EXISTS (
        SELECT 1 FROM public.jobs 
        WHERE jobs.id = trip_progress.job_id 
        AND jobs.driver_id = auth.uid()
    )
    OR
    -- Admin/super_admin: update all trips
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('administrator', 'super_admin')
    )
    OR
    -- Manager: update trips for jobs in their branch
    EXISTS (
        SELECT 1 FROM public.profiles p
        INNER JOIN public.jobs j ON j.branch_id = p.branch_id
        WHERE p.id = auth.uid() 
        AND p.role = 'manager' 
        AND j.id = trip_progress.job_id
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.jobs 
        WHERE jobs.id = trip_progress.job_id 
        AND jobs.driver_id = auth.uid()
    )
    OR
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('administrator', 'super_admin')
    )
    OR
    EXISTS (
        SELECT 1 FROM public.profiles p
        INNER JOIN public.jobs j ON j.branch_id = p.branch_id
        WHERE p.id = auth.uid() 
        AND p.role = 'manager' 
        AND j.id = trip_progress.job_id
    )
);

COMMENT ON POLICY trip_progress_update_policy ON public.trip_progress IS
'UPDATE policy: drivers update their trips; admins update all; managers update trips for jobs in their branch.';

COMMIT;
