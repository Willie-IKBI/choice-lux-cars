-- Migration 8: Expense Audit Log Table
-- Purpose: Create audit log table for tracking administrative overrides on expenses
-- Based on: ai/DRIVER_JOB_FLOW_DATABASE_CONTRACT.md (PATCH 5)
-- Prerequisites: Migrations 1, 2, 3, 4, 5, 6, and 7 must be applied
--
-- This table is REQUIRED for tracking all administrative overrides of approved expenses.
-- All admin actions (UPDATE, DELETE, INSERT after approval) must be logged here.

BEGIN;

-- ============================================================================
-- A) Create expense_audit_log table
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.expense_audit_log (
    id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    expense_id bigint NOT NULL,
    job_id bigint,
    admin_user_id uuid NOT NULL,
    action_type text NOT NULL,
    action_timestamp timestamptz NOT NULL DEFAULT now(),
    previous_values jsonb NOT NULL,
    new_values jsonb NOT NULL,
    reason text NOT NULL,
    CONSTRAINT expense_audit_log_expense_id_fkey 
        FOREIGN KEY (expense_id) 
        REFERENCES public.expenses(id) 
        ON DELETE RESTRICT,
    CONSTRAINT expense_audit_log_job_id_fkey 
        FOREIGN KEY (job_id) 
        REFERENCES public.jobs(id) 
        ON DELETE RESTRICT,
    CONSTRAINT expense_audit_log_admin_user_id_fkey 
        FOREIGN KEY (admin_user_id) 
        REFERENCES public.profiles(id) 
        ON DELETE RESTRICT
);

-- ============================================================================
-- Create indexes
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_expense_audit_log_expense_id 
ON public.expense_audit_log(expense_id);

CREATE INDEX IF NOT EXISTS idx_expense_audit_log_job_id 
ON public.expense_audit_log(job_id);

CREATE INDEX IF NOT EXISTS idx_expense_audit_log_admin_user_id 
ON public.expense_audit_log(admin_user_id);

CREATE INDEX IF NOT EXISTS idx_expense_audit_log_action_timestamp 
ON public.expense_audit_log(action_timestamp DESC);

-- ============================================================================
-- Add table and column comments
-- ============================================================================

COMMENT ON TABLE public.expense_audit_log IS 
    'Audit log for tracking all administrative overrides of approved expenses. Immutable after creation.';

COMMENT ON COLUMN public.expense_audit_log.id IS 
    'Primary key, auto-generated.';

COMMENT ON COLUMN public.expense_audit_log.expense_id IS 
    'Foreign key to expenses.id. The expense that was modified.';

COMMENT ON COLUMN public.expense_audit_log.job_id IS 
    'Foreign key to jobs.id. Optional reference to the job for easier querying.';

COMMENT ON COLUMN public.expense_audit_log.admin_user_id IS 
    'Foreign key to profiles.id. The administrator who performed the action.';

COMMENT ON COLUMN public.expense_audit_log.action_type IS 
    'Type of action: ''admin_expense_update'', ''admin_expense_delete'', ''admin_expense_insert'', ''admin_expense_approval_override''.';

COMMENT ON COLUMN public.expense_audit_log.action_timestamp IS 
    'When the action occurred. Defaults to now().';

COMMENT ON COLUMN public.expense_audit_log.previous_values IS 
    'JSONB snapshot of expense values before the change (for UPDATE/DELETE). Empty object {} for INSERT.';

COMMENT ON COLUMN public.expense_audit_log.new_values IS 
    'JSONB snapshot of expense values after the change (for UPDATE/INSERT). Empty object {} for DELETE.';

COMMENT ON COLUMN public.expense_audit_log.reason IS 
    'Text explanation of why the administrative override was necessary.';

-- ============================================================================
-- B) Immutability enforcement
-- ============================================================================

-- Create trigger function to block mutations
CREATE OR REPLACE FUNCTION public.block_audit_log_mutations()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Block all UPDATE and DELETE operations on audit log
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'Cannot update audit log entry. Audit logs are immutable.';
    END IF;
    
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Cannot delete audit log entry. Audit logs are immutable.';
    END IF;
    
    -- Return appropriate value (though exceptions prevent reaching here)
    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    ELSE
        RETURN NEW;
    END IF;
END;
$$;

-- Create trigger
DROP TRIGGER IF EXISTS trg_block_audit_log_mutations ON public.expense_audit_log;

CREATE TRIGGER trg_block_audit_log_mutations
BEFORE UPDATE OR DELETE ON public.expense_audit_log
FOR EACH ROW
EXECUTE FUNCTION public.block_audit_log_mutations();

-- Revoke execute from PUBLIC/anon
REVOKE EXECUTE ON FUNCTION public.block_audit_log_mutations() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.block_audit_log_mutations() FROM anon;

COMMENT ON FUNCTION public.block_audit_log_mutations() IS 
    'Trigger function that blocks all UPDATE and DELETE operations on expense_audit_log. Audit logs are immutable.';

-- ============================================================================
-- C) Enable RLS and create helper function
-- ============================================================================

ALTER TABLE public.expense_audit_log ENABLE ROW LEVEL SECURITY;

-- Create SECURITY DEFINER helper function for inserting audit logs
-- This function enforces that only service_role (postgres role) can insert audit logs
CREATE OR REPLACE FUNCTION public.insert_expense_audit_log(
    p_expense_id bigint,
    p_job_id bigint,
    p_admin_user_id uuid,
    p_action_type text,
    p_previous_values jsonb,
    p_new_values jsonb,
    p_reason text
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_log_id bigint;
BEGIN
    -- Only allow postgres role (service_role key in Supabase) to call this function
    -- In Supabase, service_role key connects as postgres role
    IF current_user NOT IN ('postgres', 'service_role') THEN
        RAISE EXCEPTION 'Only service_role (postgres) can insert expense audit logs via this function';
    END IF;
    
    -- Validate admin_user_id exists and is an administrator
    IF NOT EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = p_admin_user_id
        AND profiles.role IN ('administrator', 'super_admin')
    ) THEN
        RAISE EXCEPTION 'admin_user_id must reference an administrator profile';
    END IF;
    
    -- Insert the audit log entry
    -- SECURITY DEFINER allows this to bypass RLS
    INSERT INTO public.expense_audit_log (
        expense_id,
        job_id,
        admin_user_id,
        action_type,
        previous_values,
        new_values,
        reason
    ) VALUES (
        p_expense_id,
        p_job_id,
        p_admin_user_id,
        p_action_type,
        p_previous_values,
        p_new_values,
        p_reason
    ) RETURNING id INTO v_log_id;
    
    RETURN v_log_id;
END;
$$;

-- Grant execute to service_role and postgres only
GRANT EXECUTE ON FUNCTION public.insert_expense_audit_log(bigint, bigint, uuid, text, jsonb, jsonb, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.insert_expense_audit_log(bigint, bigint, uuid, text, jsonb, jsonb, text) TO postgres;

-- Revoke from PUBLIC, anon, authenticated
REVOKE EXECUTE ON FUNCTION public.insert_expense_audit_log(bigint, bigint, uuid, text, jsonb, jsonb, text) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.insert_expense_audit_log(bigint, bigint, uuid, text, jsonb, jsonb, text) FROM anon;
REVOKE EXECUTE ON FUNCTION public.insert_expense_audit_log(bigint, bigint, uuid, text, jsonb, jsonb, text) FROM authenticated;

-- Set function owner
ALTER FUNCTION public.insert_expense_audit_log(bigint, bigint, uuid, text, jsonb, jsonb, text) OWNER TO postgres;

COMMENT ON FUNCTION public.insert_expense_audit_log(bigint, bigint, uuid, text, jsonb, jsonb, text) IS 
    'SECURITY DEFINER helper function for inserting expense audit log entries. Only service_role can call this function.';

-- Policy 1: SELECT - Administrators only
-- Assumes: profiles.id == auth.uid() (same UUID value)
CREATE POLICY expense_audit_log_select_policy ON public.expense_audit_log
FOR SELECT
TO authenticated
USING (
    EXISTS (
        SELECT 1
        FROM public.profiles
        WHERE profiles.id = auth.uid()
        AND profiles.role IN ('administrator', 'super_admin')
    )
);

-- Policy 2: INSERT - Block direct inserts (must use helper function)
-- This policy denies all direct INSERTs, forcing use of insert_expense_audit_log()
-- Note: The SECURITY DEFINER function insert_expense_audit_log() runs as the function
-- owner (postgres) and bypasses RLS, so it can insert despite this policy.
CREATE POLICY expense_audit_log_insert_policy ON public.expense_audit_log
FOR INSERT
TO authenticated
WITH CHECK (false);

-- No UPDATE/DELETE policies (blocked by trigger and RLS default deny)

-- ============================================================================
-- Add policy comments
-- ============================================================================

COMMENT ON POLICY expense_audit_log_select_policy ON public.expense_audit_log IS 
    'Allows SELECT for administrators only. Assumes profiles.id == auth.uid() (same UUID value).';

COMMENT ON POLICY expense_audit_log_insert_policy ON public.expense_audit_log IS 
    'Blocks all direct INSERTs. All inserts must go through insert_expense_audit_log() SECURITY DEFINER function, which bypasses RLS and enforces service_role-only access.';

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

