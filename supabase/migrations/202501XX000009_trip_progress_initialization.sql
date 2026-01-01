-- Migration 9: Trip Progress Initialization
-- Purpose: Automatically initialize trip_progress rows when jobs transition to 'started' status
-- Based on: ai/DRIVER_JOB_FLOW.md Section 4 (Trip Progress Initialization)
-- Prerequisites: Migrations 1-8 must be applied
--
-- This migration:
-- 1) Creates a function to initialize trip_progress rows from transport rows
-- 2) Creates a trigger to auto-initialize when job_status changes to 'started'
-- 3) Backfills existing jobs with status 'open' or 'started'
-- 4) Ensures unique constraint on (job_id, trip_index) for data integrity

BEGIN;

-- ============================================================================
-- 1) Create initialization function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.init_trip_progress_for_job(p_job_id bigint)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_transport_count integer;
    v_existing_count integer;
    v_inserted_count integer;
BEGIN
    -- A) Check if transport rows exist for this job
    SELECT COUNT(*) INTO v_transport_count
    FROM public.transport
    WHERE job_id = p_job_id;
    
    IF v_transport_count = 0 THEN
        RETURN 0;
    END IF;
    
    -- B) Check if trip_progress rows already exist (idempotent check)
    SELECT COUNT(*) INTO v_existing_count
    FROM public.trip_progress
    WHERE job_id = p_job_id;
    
    IF v_existing_count > 0 THEN
        RETURN 0;
    END IF;
    
    -- C) Insert trip_progress rows from transport rows
    -- trip_index is assigned using ROW_NUMBER() ordered by transport.id
    INSERT INTO public.trip_progress (job_id, trip_index, status)
    SELECT 
        p_job_id AS job_id,
        ROW_NUMBER() OVER (ORDER BY t.id) AS trip_index,
        'pending' AS status
    FROM public.transport t
    WHERE t.job_id = p_job_id
    ORDER BY t.id;
    
    -- D) Return the number of rows inserted
    GET DIAGNOSTICS v_inserted_count = ROW_COUNT;
    RETURN v_inserted_count;
END;
$$;

-- Revoke execute from PUBLIC/anon
REVOKE EXECUTE ON FUNCTION public.init_trip_progress_for_job(bigint) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.init_trip_progress_for_job(bigint) FROM anon;

COMMENT ON FUNCTION public.init_trip_progress_for_job(bigint) IS 
    'Initializes trip_progress rows for a job from transport rows. Returns count of rows inserted. Idempotent: returns 0 if rows already exist or no transport rows exist.';

-- ============================================================================
-- 2) Create trigger function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.trg_init_trip_progress_on_job_start()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_inserted_count integer;
BEGIN
    -- Only fire when job_status changes to 'started'
    IF OLD.job_status IS DISTINCT FROM NEW.job_status 
       AND NEW.job_status = 'started' THEN
        
        -- Initialize trip_progress rows for this job
        SELECT public.init_trip_progress_for_job(NEW.id) INTO v_inserted_count;
        
        -- Log if rows were inserted (optional, can be removed in production)
        IF v_inserted_count > 0 THEN
            RAISE NOTICE 'Initialized % trip_progress rows for job %', v_inserted_count, NEW.id;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Revoke execute from PUBLIC/anon
REVOKE EXECUTE ON FUNCTION public.trg_init_trip_progress_on_job_start() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.trg_init_trip_progress_on_job_start() FROM anon;

COMMENT ON FUNCTION public.trg_init_trip_progress_on_job_start() IS 
    'Trigger function that automatically initializes trip_progress rows when a job status transitions to ''started''. Ensures all trips are tracked from job start.';

-- ============================================================================
-- 3) Create trigger
-- ============================================================================

DROP TRIGGER IF EXISTS trg_init_trip_progress_on_job_start ON public.jobs;

CREATE TRIGGER trg_init_trip_progress_on_job_start
BEFORE UPDATE OF job_status ON public.jobs
FOR EACH ROW
EXECUTE FUNCTION public.trg_init_trip_progress_on_job_start();

-- ============================================================================
-- 4) Backfill existing jobs
-- ============================================================================

DO $$
DECLARE
    v_job_record RECORD;
    v_inserted_count integer;
    v_total_inserted integer := 0;
BEGIN
    -- Backfill jobs with status 'open' or 'started' that have transport rows
    -- but no trip_progress rows
    FOR v_job_record IN
        SELECT DISTINCT j.id
        FROM public.jobs j
        WHERE j.job_status IN ('open', 'started')
        AND EXISTS (
            SELECT 1
            FROM public.transport t
            WHERE t.job_id = j.id
        )
        AND NOT EXISTS (
            SELECT 1
            FROM public.trip_progress tp
            WHERE tp.job_id = j.id
        )
    LOOP
        -- Initialize trip_progress for this job
        SELECT public.init_trip_progress_for_job(v_job_record.id) INTO v_inserted_count;
        
        IF v_inserted_count > 0 THEN
            v_total_inserted := v_total_inserted + v_inserted_count;
            RAISE NOTICE 'Backfilled % trip_progress rows for job %', v_inserted_count, v_job_record.id;
        END IF;
    END LOOP;
    
    IF v_total_inserted > 0 THEN
        RAISE NOTICE 'Backfill complete: % total trip_progress rows initialized', v_total_inserted;
    ELSE
        RAISE NOTICE 'Backfill complete: No jobs required initialization';
    END IF;
END $$;

-- ============================================================================
-- 5) Ensure unique constraint/index on (job_id, trip_index)
-- ============================================================================

-- Check if unique constraint or index already exists
DO $$
DECLARE
    v_constraint_exists boolean;
    v_index_exists boolean;
BEGIN
    -- Check for unique constraint
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.table_constraints tc
        JOIN information_schema.constraint_column_usage ccu
            ON tc.constraint_name = ccu.constraint_name
        WHERE tc.table_schema = 'public'
        AND tc.table_name = 'trip_progress'
        AND tc.constraint_type = 'UNIQUE'
        AND (
            SELECT COUNT(*)
            FROM information_schema.constraint_column_usage ccu2
            WHERE ccu2.constraint_name = tc.constraint_name
            AND ccu2.column_name IN ('job_id', 'trip_index')
        ) = 2
    ) INTO v_constraint_exists;
    
    -- Check for unique index
    SELECT EXISTS (
        SELECT 1
        FROM pg_indexes
        WHERE schemaname = 'public'
        AND tablename = 'trip_progress'
        AND indexname = 'ux_trip_progress_job_trip_index'
    ) INTO v_index_exists;
    
    -- Create unique index if neither exists
    IF NOT v_constraint_exists AND NOT v_index_exists THEN
        CREATE UNIQUE INDEX IF NOT EXISTS ux_trip_progress_job_trip_index
        ON public.trip_progress(job_id, trip_index);
        
        RAISE NOTICE 'Created unique index ux_trip_progress_job_trip_index on (job_id, trip_index)';
    ELSE
        RAISE NOTICE 'Unique constraint or index on (job_id, trip_index) already exists';
    END IF;
END $$;

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

