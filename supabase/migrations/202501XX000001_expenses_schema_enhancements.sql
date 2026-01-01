-- Migration 1: Expenses Schema Enhancements
-- Purpose: Add expense_type, approval columns, rename user to driver_id, add constraints and indexes
-- Based on: ai/DRIVER_JOB_FLOW_DATABASE_CONTRACT.md (PATCH 1-5)
-- Note: expense_type will be set to NOT NULL in Migration 2 after data migration

BEGIN;

-- ============================================================================
-- 1. Add expense_type column (nullable, with temporary CHECK allowing NULL)
-- ============================================================================

-- Add expense_type column as nullable
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'expense_type'
    ) THEN
        ALTER TABLE public.expenses 
        ADD COLUMN expense_type text;
        
        -- Add temporary CHECK constraint allowing NULL (will be updated in Migration 2)
        ALTER TABLE public.expenses
        ADD CONSTRAINT check_expense_type_temp 
        CHECK (expense_type IS NULL OR expense_type IN ('fuel', 'parking', 'toll', 'other'));
        
        -- Add column comment
        COMMENT ON COLUMN public.expenses.expense_type IS 
            'Type of expense: ''fuel'', ''parking'', ''toll'', or ''other''. ''other'' requires other_description. Currently nullable; will be NOT NULL after Migration 2.';
    END IF;
END $$;

-- ============================================================================
-- 2. Add approval columns (approved_by and approved_at)
-- ============================================================================

-- Add approved_by column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'approved_by'
    ) THEN
        ALTER TABLE public.expenses 
        ADD COLUMN approved_by uuid;
        
        COMMENT ON COLUMN public.expenses.approved_by IS 
            'Manager (from profiles) who approved all expenses for this job. NULL if not yet approved. FK to profiles.id.';
    END IF;
END $$;

-- Add approved_at column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'approved_at'
    ) THEN
        ALTER TABLE public.expenses 
        ADD COLUMN approved_at timestamptz;
        
        COMMENT ON COLUMN public.expenses.approved_at IS 
            'Timestamp when manager approved expenses. NULL if not yet approved.';
    END IF;
END $$;

-- ============================================================================
-- 3. Change job_id to NOT NULL (PATCH 2 requirement)
-- ============================================================================

-- Check for NULL job_id values first (should fail if found)
DO $$
DECLARE
    null_count integer;
BEGIN
    SELECT COUNT(*) INTO null_count
    FROM public.expenses
    WHERE job_id IS NULL;
    
    IF null_count > 0 THEN
        RAISE EXCEPTION 'Cannot set job_id to NOT NULL: Found % rows with NULL job_id. Please update these rows before running this migration.', null_count;
    END IF;
END $$;

-- Set job_id to NOT NULL
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'job_id'
        AND is_nullable = 'YES'
    ) THEN
        ALTER TABLE public.expenses 
        ALTER COLUMN job_id SET NOT NULL;
    END IF;
END $$;

-- ============================================================================
-- 4. Rename user column to driver_id (or create driver_id if conversion fails)
-- ============================================================================

DO $$
DECLARE
    user_col_exists boolean;
    user_col_type text;
    invalid_uuid_count integer;
    driver_id_col_exists boolean;
BEGIN
    -- Check if user column exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'user'
    ) INTO user_col_exists;
    
    -- Check if driver_id column already exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'driver_id'
    ) INTO driver_id_col_exists;
    
    IF user_col_exists AND NOT driver_id_col_exists THEN
        -- Get current type of user column
        SELECT data_type INTO user_col_type
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = 'expenses'
        AND column_name = 'user';
        
        IF user_col_type = 'text' THEN
            -- Check if all values are valid UUIDs (case-insensitive)
            SELECT COUNT(*) INTO invalid_uuid_count
            FROM public.expenses
            WHERE user IS NOT NULL
            AND user !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
            
            IF invalid_uuid_count = 0 THEN
                -- All values are valid UUIDs, safe to convert and rename
                ALTER TABLE public.expenses
                ALTER COLUMN "user" TYPE uuid USING "user"::uuid;
                
                ALTER TABLE public.expenses
                RENAME COLUMN "user" TO driver_id;
                
                RAISE NOTICE 'Successfully converted and renamed user column to driver_id (uuid)';
            ELSE
                -- Invalid UUIDs found, create new driver_id column and leave user intact
                ALTER TABLE public.expenses
                ADD COLUMN driver_id uuid;
                
                COMMENT ON COLUMN public.expenses.driver_id IS 
                    'Driver who created the expense (FK to profiles.id). New column created because user column contains invalid UUIDs. Old user column preserved.';
                
                COMMENT ON COLUMN public.expenses."user" IS 
                    'DEPRECATED: Legacy user column. Contains non-UUID values. Use driver_id instead.';
                
                RAISE NOTICE 'Created new driver_id column. Found % rows with invalid UUIDs in user column. Old user column preserved.', invalid_uuid_count;
            END IF;
        ELSIF user_col_type = 'uuid' THEN
            -- Already UUID, just rename
            ALTER TABLE public.expenses
            RENAME COLUMN "user" TO driver_id;
            
            RAISE NOTICE 'Renamed user column to driver_id (already uuid type)';
        ELSE
            -- Unexpected type, create new column
            ALTER TABLE public.expenses
            ADD COLUMN driver_id uuid;
            
            COMMENT ON COLUMN public.expenses.driver_id IS 
                'Driver who created the expense (FK to profiles.id). New column created because user column has unexpected type. Old user column preserved.';
            
            RAISE NOTICE 'Created new driver_id column. User column has unexpected type: %. Old user column preserved.', user_col_type;
        END IF;
    ELSIF NOT user_col_exists AND NOT driver_id_col_exists THEN
        -- Neither column exists, create driver_id
        ALTER TABLE public.expenses
        ADD COLUMN driver_id uuid;
        
        COMMENT ON COLUMN public.expenses.driver_id IS 
            'Driver who created the expense (FK to profiles.id).';
        
        RAISE NOTICE 'Created new driver_id column (user column did not exist)';
    ELSIF driver_id_col_exists THEN
        RAISE NOTICE 'driver_id column already exists, skipping user column migration';
    END IF;
END $$;

-- ============================================================================
-- 5. Add foreign key constraints
-- ============================================================================

-- Add FK: job_id → jobs.id (ON DELETE RESTRICT)
DO $$
DECLARE
    existing_fk_name text;
    existing_fk_delete_rule text;
    referenced_table text;
BEGIN
    -- Check if FK already exists on job_id column
    SELECT 
        con.conname,
        CASE 
            WHEN con.confdeltype = 'r' THEN 'RESTRICT'
            WHEN con.confdeltype = 'c' THEN 'CASCADE'
            WHEN con.confdeltype = 'n' THEN 'SET NULL'
            WHEN con.confdeltype = 'd' THEN 'SET DEFAULT'
            ELSE 'NO ACTION'
        END,
        ref_rel.relname
    INTO existing_fk_name, existing_fk_delete_rule, referenced_table
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    JOIN pg_class ref_rel ON ref_rel.oid = con.confrelid
    WHERE nsp.nspname = 'public'
    AND rel.relname = 'expenses'
    AND con.contype = 'f'
    AND (
        SELECT attnum 
        FROM pg_attribute 
        WHERE attrelid = rel.oid 
        AND attname = 'job_id'
    ) = ANY(con.conkey)
    LIMIT 1;
    
    IF existing_fk_name IS NOT NULL THEN
        -- FK exists, check if it needs to be updated
        IF referenced_table != 'jobs' OR existing_fk_delete_rule != 'RESTRICT' THEN
            -- Drop existing FK and recreate with correct table and RESTRICT
            EXECUTE format('ALTER TABLE public.expenses DROP CONSTRAINT %I', existing_fk_name);
            ALTER TABLE public.expenses
            ADD CONSTRAINT expenses_job_id_fkey
            FOREIGN KEY (job_id) 
            REFERENCES public.jobs(id) 
            ON DELETE RESTRICT;
        END IF;
        -- If already correct (jobs table and RESTRICT), skip
    ELSE
        -- No FK exists, create new one
        ALTER TABLE public.expenses
        ADD CONSTRAINT expenses_job_id_fkey
        FOREIGN KEY (job_id) 
        REFERENCES public.jobs(id) 
        ON DELETE RESTRICT;
    END IF;
END $$;

-- Add FK: driver_id → profiles.id (ON DELETE RESTRICT)
DO $$
DECLARE
    existing_fk_name text;
    existing_fk_delete_rule text;
    referenced_table text;
BEGIN
    -- Check if driver_id column exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'driver_id'
    ) THEN
        -- Check if FK already exists on driver_id column
        SELECT 
            con.conname,
            CASE 
                WHEN con.confdeltype = 'r' THEN 'RESTRICT'
                WHEN con.confdeltype = 'c' THEN 'CASCADE'
                WHEN con.confdeltype = 'n' THEN 'SET NULL'
                WHEN con.confdeltype = 'd' THEN 'SET DEFAULT'
                ELSE 'NO ACTION'
            END,
            ref_rel.relname
        INTO existing_fk_name, existing_fk_delete_rule, referenced_table
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        JOIN pg_class ref_rel ON ref_rel.oid = con.confrelid
        WHERE nsp.nspname = 'public'
        AND rel.relname = 'expenses'
        AND con.contype = 'f'
        AND (
            SELECT attnum 
            FROM pg_attribute 
            WHERE attrelid = rel.oid 
            AND attname = 'driver_id'
        ) = ANY(con.conkey)
        LIMIT 1;
        
        IF existing_fk_name IS NOT NULL THEN
            -- FK exists, check if it needs to be updated
            IF referenced_table != 'profiles' OR existing_fk_delete_rule != 'RESTRICT' THEN
                -- Drop existing FK and recreate with correct table and RESTRICT
                EXECUTE format('ALTER TABLE public.expenses DROP CONSTRAINT %I', existing_fk_name);
                ALTER TABLE public.expenses
                ADD CONSTRAINT expenses_driver_id_fkey
                FOREIGN KEY (driver_id) 
                REFERENCES public.profiles(id) 
                ON DELETE RESTRICT;
            END IF;
            -- If already correct (profiles table and RESTRICT), skip
        ELSE
            -- No FK exists, create new one
            ALTER TABLE public.expenses
            ADD CONSTRAINT expenses_driver_id_fkey
            FOREIGN KEY (driver_id) 
            REFERENCES public.profiles(id) 
            ON DELETE RESTRICT;
        END IF;
    END IF;
END $$;

-- Add FK: approved_by → profiles.id (ON DELETE SET NULL)
DO $$
DECLARE
    existing_fk_name text;
    existing_fk_delete_rule text;
    referenced_table text;
BEGIN
    -- Check if FK already exists on approved_by column
    SELECT 
        con.conname,
        CASE 
            WHEN con.confdeltype = 'r' THEN 'RESTRICT'
            WHEN con.confdeltype = 'c' THEN 'CASCADE'
            WHEN con.confdeltype = 'n' THEN 'SET NULL'
            WHEN con.confdeltype = 'd' THEN 'SET DEFAULT'
            ELSE 'NO ACTION'
        END,
        ref_rel.relname
    INTO existing_fk_name, existing_fk_delete_rule, referenced_table
    FROM pg_constraint con
    JOIN pg_class rel ON rel.oid = con.conrelid
    JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
    JOIN pg_class ref_rel ON ref_rel.oid = con.confrelid
    WHERE nsp.nspname = 'public'
    AND rel.relname = 'expenses'
    AND con.contype = 'f'
    AND (
        SELECT attnum 
        FROM pg_attribute 
        WHERE attrelid = rel.oid 
        AND attname = 'approved_by'
    ) = ANY(con.conkey)
    LIMIT 1;
    
    IF existing_fk_name IS NOT NULL THEN
        -- FK exists, check if it needs to be updated
        IF referenced_table != 'profiles' OR existing_fk_delete_rule != 'SET NULL' THEN
            -- Drop existing FK and recreate with correct table and SET NULL
            EXECUTE format('ALTER TABLE public.expenses DROP CONSTRAINT %I', existing_fk_name);
            ALTER TABLE public.expenses
            ADD CONSTRAINT expenses_approved_by_fkey
            FOREIGN KEY (approved_by) 
            REFERENCES public.profiles(id) 
            ON DELETE SET NULL;
        END IF;
        -- If already correct (profiles table and SET NULL), skip
    ELSE
        -- No FK exists, create new one
        ALTER TABLE public.expenses
        ADD CONSTRAINT expenses_approved_by_fkey
        FOREIGN KEY (approved_by) 
        REFERENCES public.profiles(id) 
        ON DELETE SET NULL;
    END IF;
END $$;

-- ============================================================================
-- 6. Add CHECK constraints
-- ============================================================================

-- Add CHECK: exp_amount > 0 (with pre-check for safety)
DO $$
DECLARE
    invalid_amount_count integer;
BEGIN
    -- Pre-check: Count rows with NULL or <= 0 exp_amount
    SELECT COUNT(*) INTO invalid_amount_count
    FROM public.expenses
    WHERE exp_amount IS NULL OR exp_amount <= 0;
    
    IF invalid_amount_count > 0 THEN
        RAISE EXCEPTION 'Cannot add exp_amount constraint: Found % rows with NULL or <= 0 exp_amount. Please update these rows before running this migration.', invalid_amount_count;
    END IF;
    
    -- Add CHECK constraint if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public'
        AND table_name = 'expenses'
        AND constraint_name = 'check_exp_amount_positive'
    ) THEN
        ALTER TABLE public.expenses
        ADD CONSTRAINT check_exp_amount_positive
        CHECK (exp_amount IS NOT NULL AND exp_amount > 0);
    END IF;
END $$;

-- Add CHECK: other_description required when expense_type = 'other'
-- Note: This allows NULL expense_type temporarily (will be updated in Migration 2)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_schema = 'public'
        AND table_name = 'expenses'
        AND constraint_name = 'check_other_description_required'
    ) THEN
        ALTER TABLE public.expenses
        ADD CONSTRAINT check_other_description_required
        CHECK (
            (expense_type = 'other' AND other_description IS NOT NULL AND btrim(other_description) != '') 
            OR (expense_type IS NULL OR expense_type != 'other')
        );
    END IF;
END $$;

-- ============================================================================
-- 7. Create indexes
-- ============================================================================

-- Index: idx_expenses_job_id
CREATE INDEX IF NOT EXISTS idx_expenses_job_id 
ON public.expenses(job_id);

-- Index: idx_expenses_approved (partial index for approved expenses)
CREATE INDEX IF NOT EXISTS idx_expenses_approved 
ON public.expenses(approved_by, approved_at) 
WHERE approved_by IS NOT NULL;

-- Index: idx_expenses_driver_id (renamed from user)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'expenses' 
        AND column_name = 'driver_id'
    ) THEN
        -- Drop old user index if it exists
        DROP INDEX IF EXISTS public.idx_expenses_user;
        
        -- Create new driver_id index
        CREATE INDEX IF NOT EXISTS idx_expenses_driver_id 
        ON public.expenses(driver_id);
    END IF;
END $$;

-- Index: idx_expenses_job_approval (partial index for pending approvals)
CREATE INDEX IF NOT EXISTS idx_expenses_job_approval 
ON public.expenses(job_id, approved_by) 
WHERE approved_by IS NULL;

-- ============================================================================
-- 8. Add column comments
-- ============================================================================

-- Comment on other_description (if not already set)
COMMENT ON COLUMN public.expenses.other_description IS 
    'Required description when expense_type is ''other''. Optional for other types.';

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

