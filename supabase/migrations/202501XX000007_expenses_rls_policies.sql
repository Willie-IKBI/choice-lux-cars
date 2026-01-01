-- Migration 7: Expenses RLS Policies
-- Purpose: Enable Row Level Security and create policies for expenses table
-- Based on: ai/DRIVER_JOB_FLOW_DATABASE_CONTRACT.md (PATCH 1-5)
-- Prerequisites: Migrations 1, 2, 3, 4, 5, and 6 must be applied
--
-- Critical Assumption: profiles.id == auth.uid() (same UUID value)
-- This assumption is used throughout all RLS policies.

BEGIN;

-- ============================================================================
-- A) Enable RLS
-- ============================================================================

ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- B) Create RLS Policies for public.expenses
-- ============================================================================

-- Policy 1: SELECT - Allow drivers, managers, and administrators
-- Assumes: profiles.id == auth.uid() (same UUID value)
CREATE POLICY expenses_select_policy ON public.expenses
FOR SELECT
TO authenticated
USING (
    -- Allow if user is the driver or manager of the job
    EXISTS (
        SELECT 1
        FROM public.jobs
        WHERE jobs.id = expenses.job_id
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

-- Policy 2: INSERT - Drivers only (for their assigned jobs)
-- Assumes: profiles.id == auth.uid() (same UUID value)
CREATE POLICY expenses_insert_policy ON public.expenses
FOR INSERT
TO authenticated
WITH CHECK (
    -- Expense creator must be the authenticated user
    expenses.driver_id = auth.uid()
    AND
    -- User must be the driver assigned to the job
    EXISTS (
        SELECT 1
        FROM public.jobs
        WHERE jobs.id = expenses.job_id
        AND jobs.driver_id = auth.uid()
    )
);

-- Policy 3: UPDATE - Drivers only, pre-approval only
-- Assumes: profiles.id == auth.uid() (same UUID value)
CREATE POLICY expenses_update_policy ON public.expenses
FOR UPDATE
TO authenticated
USING (
    -- Expense creator must be the authenticated user
    expenses.driver_id = auth.uid()
    AND
    -- Expense must not be approved yet
    expenses.approved_by IS NULL
    AND
    -- User must be the driver assigned to the job
    EXISTS (
        SELECT 1
        FROM public.jobs
        WHERE jobs.id = expenses.job_id
        AND jobs.driver_id = auth.uid()
    )
)
WITH CHECK (
    -- Same conditions for the new row
    expenses.driver_id = auth.uid()
    AND
    expenses.approved_by IS NULL
    AND
    EXISTS (
        SELECT 1
        FROM public.jobs
        WHERE jobs.id = expenses.job_id
        AND jobs.driver_id = auth.uid()
    )
);

-- Policy 4: DELETE - Drivers only, pre-approval only
-- Assumes: profiles.id == auth.uid() (same UUID value)
CREATE POLICY expenses_delete_policy ON public.expenses
FOR DELETE
TO authenticated
USING (
    -- Expense creator must be the authenticated user
    expenses.driver_id = auth.uid()
    AND
    -- Expense must not be approved yet
    expenses.approved_by IS NULL
    AND
    -- User must be the driver assigned to the job
    EXISTS (
        SELECT 1
        FROM public.jobs
        WHERE jobs.id = expenses.job_id
        AND jobs.driver_id = auth.uid()
    )
);

-- ============================================================================
-- C) Approval RPC tightening
-- ============================================================================

-- Ensure approve_job_expenses is only callable by authenticated users
REVOKE EXECUTE ON FUNCTION public.approve_job_expenses(bigint) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.approve_job_expenses(bigint) FROM anon;
GRANT EXECUTE ON FUNCTION public.approve_job_expenses(bigint) TO authenticated;

-- ============================================================================
-- Add policy comments
-- ============================================================================

COMMENT ON POLICY expenses_select_policy ON public.expenses IS 
    'Allows SELECT for drivers and managers of the job, or administrators. Assumes profiles.id == auth.uid() (same UUID value).';

COMMENT ON POLICY expenses_insert_policy ON public.expenses IS 
    'Allows INSERT for drivers creating expenses for their assigned jobs. Assumes profiles.id == auth.uid() (same UUID value).';

COMMENT ON POLICY expenses_update_policy ON public.expenses IS 
    'Allows UPDATE for drivers on unapproved expenses for their assigned jobs. Assumes profiles.id == auth.uid() (same UUID value).';

COMMENT ON POLICY expenses_delete_policy ON public.expenses IS 
    'Allows DELETE for drivers on unapproved expenses for their assigned jobs. Assumes profiles.id == auth.uid() (same UUID value).';

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

