-- Migration 6: Job Closure Validation Trigger
-- Purpose: Enforce that jobs cannot be closed until all trips are completed
-- Based on: ai/DRIVER_JOB_FLOW_DATABASE_CONTRACT.md
-- Prerequisites: Migrations 1, 2, 3, 4, and 5 must be applied

BEGIN;

-- ============================================================================
-- Create enforce_job_closure_requires_completed_trips trigger function
-- ============================================================================

CREATE OR REPLACE FUNCTION public.enforce_job_closure_requires_completed_trips()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    all_trips_completed boolean;
BEGIN
    -- Only enforce when job_status is changing to 'completed'
    IF OLD.job_status IS DISTINCT FROM NEW.job_status
       AND OLD.job_status <> 'completed'
       AND NEW.job_status = 'completed' THEN
        
        -- Allow service_role to bypass validation (for administrative overrides)
        IF current_user = 'service_role' THEN
            RETURN NEW;
        END IF;
        
        -- Validate that all trips are completed
        SELECT public.validate_all_trips_completed(NEW.id)
        INTO all_trips_completed;
        
        -- If not all trips are completed, prevent job closure
        IF NOT all_trips_completed THEN
            RAISE EXCEPTION 'Cannot close job: not all trips are completed';
        END IF;
    END IF;
    
    -- Allow the update to proceed
    RETURN NEW;
END;
$$;

-- ============================================================================
-- Create trigger
-- ============================================================================

DROP TRIGGER IF EXISTS trg_job_closure_requires_trips_completed ON public.jobs;

CREATE TRIGGER trg_job_closure_requires_trips_completed
BEFORE UPDATE OF job_status ON public.jobs
FOR EACH ROW
EXECUTE FUNCTION public.enforce_job_closure_requires_completed_trips();

-- ============================================================================
-- Ensure no PUBLIC/anon execute grants exist
-- ============================================================================

REVOKE EXECUTE ON FUNCTION public.enforce_job_closure_requires_completed_trips() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.enforce_job_closure_requires_completed_trips() FROM anon;

-- ============================================================================
-- Add function comment
-- ============================================================================

COMMENT ON FUNCTION public.enforce_job_closure_requires_completed_trips() IS 
    'Trigger function that enforces job closure validation. Prevents jobs from being closed (job_status = ''completed'') until all trips are completed. Allows service_role to bypass validation for administrative overrides.';

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

