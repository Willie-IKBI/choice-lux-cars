-- Migration 2: Expenses Data Migration
-- Purpose: Backfill expense_type, enforce NOT NULL constraints, tighten CHECK constraints
-- Based on: ai/DRIVER_JOB_FLOW_DATABASE_CONTRACT.md (PATCH 1-5)
-- Prerequisites: Migration 1 must be applied

BEGIN;

-- ============================================================================
-- A) Backfill data
-- ============================================================================

-- 1. Set expense_type = 'other' for all NULL values
UPDATE public.expenses 
SET expense_type = 'other' 
WHERE expense_type IS NULL;

-- Pre-check: Verify no invalid expense_type values exist
DO $$
DECLARE
    invalid_type_count integer;
BEGIN
    SELECT COUNT(*) INTO invalid_type_count
    FROM public.expenses
    WHERE expense_type IS NOT NULL
    AND expense_type NOT IN ('fuel', 'parking', 'toll', 'other');
    
    IF invalid_type_count > 0 THEN
        RAISE EXCEPTION 'Cannot proceed: Found % rows with invalid expense_type values. All expense_type values must be one of: fuel, parking, toll, other.', invalid_type_count;
    END IF;
END $$;

-- ============================================================================
-- B) Enforce exp_amount required
-- ============================================================================

-- 2. Pre-check: Verify no NULL exp_amount values exist
DO $$
DECLARE
    null_amount_count integer;
BEGIN
    SELECT COUNT(*) INTO null_amount_count
    FROM public.expenses
    WHERE exp_amount IS NULL;
    
    IF null_amount_count > 0 THEN
        RAISE EXCEPTION 'Cannot set exp_amount to NOT NULL: Found % rows with NULL exp_amount. Please update these rows before running this migration.', null_amount_count;
    END IF;
END $$;

-- 3. Set exp_amount to NOT NULL
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'exp_amount'
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE public.expenses 
        ALTER COLUMN exp_amount SET NOT NULL;
    END IF;
END $$;

-- ============================================================================
-- C) Tighten expense_type constraints
-- ============================================================================

-- 4. Set default value for expense_type
DO $$
BEGIN
    ALTER TABLE public.expenses 
    ALTER COLUMN expense_type SET DEFAULT 'other';
END $$;

-- 5. Drop temporary CHECK constraint if it exists
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public'
        AND table_name = 'expenses'
        AND constraint_name = 'check_expense_type_temp'
    ) THEN
        ALTER TABLE public.expenses
        DROP CONSTRAINT check_expense_type_temp;
    END IF;
END $$;

-- 6. Add new CHECK constraint (no NULLs allowed)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public'
        AND table_name = 'expenses'
        AND constraint_name = 'check_expense_type'
    ) THEN
        ALTER TABLE public.expenses
        ADD CONSTRAINT check_expense_type
        CHECK (expense_type IS NOT NULL AND expense_type IN ('fuel', 'parking', 'toll', 'other'));
    END IF;
END $$;

-- 7. Set expense_type to NOT NULL
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'expense_type'
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE public.expenses 
        ALTER COLUMN expense_type SET NOT NULL;
    END IF;
END $$;

-- ============================================================================
-- D) Ensure other_description CHECK is whitespace-safe
-- ============================================================================

-- 8. Drop and recreate check_other_description_required with whitespace-safe check
DO $$
BEGIN
    -- Drop existing constraint if it exists
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public'
        AND table_name = 'expenses'
        AND constraint_name = 'check_other_description_required'
    ) THEN
        ALTER TABLE public.expenses
        DROP CONSTRAINT check_other_description_required;
    END IF;
    
    -- Recreate with whitespace-safe check
    ALTER TABLE public.expenses
    ADD CONSTRAINT check_other_description_required
    CHECK (
        (expense_type <> 'other') 
        OR (other_description IS NOT NULL AND btrim(other_description) <> '')
    );
END $$;

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

