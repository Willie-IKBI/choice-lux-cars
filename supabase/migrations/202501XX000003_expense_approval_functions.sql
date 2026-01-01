-- Migration 3: Expense Approval Functions
-- Purpose: Create RPC function for expense approval workflow
-- Based on: ai/DRIVER_JOB_FLOW_DATABASE_CONTRACT.md (PATCH 1-5)
-- Prerequisites: Migrations 1 and 2 must be applied

BEGIN;

-- ============================================================================
-- Create approve_job_expenses function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.approve_job_expenses(p_job_id bigint)
RETURNS TABLE(approved_count integer, approved_total numeric)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    actor_id uuid;
    actor_role text;
    job_status_value text;
    job_manager_id uuid;
    v_approved_count integer;
    v_approved_total numeric;
BEGIN
    -- Get actor ID from auth context
    actor_id := auth.uid();
    
    -- Verify actor exists in profiles
    IF actor_id IS NULL THEN
        RAISE EXCEPTION 'Not authorized: No authenticated user';
    END IF;
    
    SELECT role INTO actor_role
    FROM public.profiles
    WHERE id = actor_id;
    
    IF actor_role IS NULL THEN
        RAISE EXCEPTION 'Not authorized: User profile not found';
    END IF;
    
    -- Verify job exists and get job details
    SELECT 
        job_status,
        manager_id
    INTO 
        job_status_value,
        job_manager_id
    FROM public.jobs
    WHERE id = p_job_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Job not found: Job ID % does not exist', p_job_id;
    END IF;
    
    -- Verify job is in completed state
    IF job_status_value != 'completed' THEN
        RAISE EXCEPTION 'Job not completed: Job ID % has status ''%''. Expenses can only be approved for completed jobs.', p_job_id, job_status_value;
    END IF;
    
    -- Authorization check: actor must be manager of the job OR have admin privileges
    IF actor_id != job_manager_id AND actor_role NOT IN ('administrator', 'super_admin') THEN
        RAISE EXCEPTION 'Not authorized: User % is not the manager of job % and does not have administrator privileges', actor_id, p_job_id;
    END IF;
    
    -- Update expenses: approve all unapproved expenses for this job
    WITH updated_expenses AS (
        UPDATE public.expenses
        SET 
            approved_by = actor_id,
            approved_at = now(),
            updated_at = now()
        WHERE 
            job_id = p_job_id
            AND approved_by IS NULL
        RETURNING exp_amount
    )
    SELECT 
        COUNT(*)::integer,
        COALESCE(SUM(exp_amount), 0)
    INTO 
        v_approved_count,
        v_approved_total
    FROM updated_expenses;
    
    -- Return results
    RETURN QUERY SELECT v_approved_count, v_approved_total;
END;
$$;

-- ============================================================================
-- Grant permissions
-- ============================================================================

GRANT EXECUTE ON FUNCTION public.approve_job_expenses(bigint) TO authenticated;

-- ============================================================================
-- Add function comment
-- ============================================================================

COMMENT ON FUNCTION public.approve_job_expenses(bigint) IS 
    'Approves all unapproved expenses for a completed job. Requires caller to be the job manager or an administrator. Returns count and total of approved expenses.';

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

