-- Migration 5: Expense Immutability Triggers
-- Purpose: Enforce immutability of approved expenses via database triggers
-- Based on: ai/DRIVER_JOB_FLOW_DATABASE_CONTRACT.md (PATCH 1-5)
-- Prerequisites: Migrations 1, 2, 3, and 4 must be applied

BEGIN;

-- ============================================================================
-- Create enforce_expense_immutability trigger function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.enforce_expense_immutability()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- If OLD.approved_by IS NULL (not approved), always allow the operation
    -- This includes the approval transition (OLD.approved_by IS NULL -> NEW.approved_by IS NOT NULL)
    IF OLD.approved_by IS NULL THEN
        IF TG_OP = 'UPDATE' THEN
            RETURN NEW;
        ELSE
            RETURN OLD; -- DELETE
        END IF;
    END IF;
    
    -- Only enforce immutability if expense is already approved
    -- Allow service_role to bypass immutability (for administrative overrides)
    IF current_user = 'service_role' THEN
        IF TG_OP = 'UPDATE' THEN
            RETURN NEW;
        ELSE
            RETURN OLD; -- DELETE
        END IF;
    END IF;
    
    -- Block DELETE on approved expenses
    IF TG_OP = 'DELETE' THEN
        RAISE EXCEPTION 'Cannot delete approved expense. Expense ID % was approved by % on %.', 
            OLD.id, OLD.approved_by, OLD.approved_at;
    END IF;
    
    -- Block UPDATE on approved expenses
    IF TG_OP = 'UPDATE' THEN
        RAISE EXCEPTION 'Cannot update approved expense. Expense ID % was approved by % on %.', 
            OLD.id, OLD.approved_by, OLD.approved_at;
    END IF;
END;
$$;

-- ============================================================================
-- Create trigger
-- ============================================================================

DROP TRIGGER IF EXISTS trg_expense_immutability ON public.expenses;

CREATE TRIGGER trg_expense_immutability
BEFORE UPDATE OR DELETE ON public.expenses
FOR EACH ROW
EXECUTE FUNCTION public.enforce_expense_immutability();

-- ============================================================================
-- Ensure no PUBLIC execute grants exist
-- ============================================================================

REVOKE EXECUTE ON FUNCTION public.enforce_expense_immutability() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.enforce_expense_immutability() FROM anon;

-- ============================================================================
-- Add function comment
-- ============================================================================

COMMENT ON FUNCTION public.enforce_expense_immutability() IS 
    'Trigger function that enforces immutability of approved expenses. Blocks UPDATE and DELETE operations on expenses where approved_by IS NOT NULL, except for service_role. Allows operations on unapproved expenses, including the approval transition.';

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

