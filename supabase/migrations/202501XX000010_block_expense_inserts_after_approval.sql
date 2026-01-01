-- Migration 10: Block Expense Inserts After Approval
-- Purpose: Prevent new expenses from being added to jobs that have approved expenses
-- Based on: ai/DRIVER_JOB_FLOW_DATABASE_CONTRACT.md (PATCH 4)
-- Prerequisites: Migrations 1-9 must be applied
--
-- Business Rule: Once a job has any approved expenses, no new expenses can be added.
-- This enforces the immutability of expense data after manager approval.
-- Exception: service_role can bypass this restriction for administrative purposes.

BEGIN;

-- ============================================================================
-- 1) Create trigger function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.block_expense_inserts_after_approval()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Exception: service_role can bypass this restriction
    IF current_user = 'service_role' THEN
        RETURN NEW;
    END IF;
    
    -- Check if job has any approved expenses
    IF EXISTS (
        SELECT 1
        FROM public.expenses
        WHERE job_id = NEW.job_id
        AND approved_by IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Cannot add expenses to job with approved expenses. Approval is final.';
    END IF;
    
    RETURN NEW;
END;
$$;

-- Revoke execute from PUBLIC/anon
REVOKE EXECUTE ON FUNCTION public.block_expense_inserts_after_approval() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.block_expense_inserts_after_approval() FROM anon;

COMMENT ON FUNCTION public.block_expense_inserts_after_approval() IS 
    'Trigger function that blocks INSERT of new expenses for jobs that already have approved expenses. Service role can bypass. Enforces immutability after approval.';

-- ============================================================================
-- 2) Create trigger
-- ============================================================================

DROP TRIGGER IF EXISTS trg_block_expense_inserts_after_approval ON public.expenses;

CREATE TRIGGER trg_block_expense_inserts_after_approval
BEFORE INSERT ON public.expenses
FOR EACH ROW
EXECUTE FUNCTION public.block_expense_inserts_after_approval();

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

