-- Migration: Add Job Closure Validation Function and Trigger
-- Date: 2026-01-09
-- Purpose: Create database-level validation to ensure all trips are completed
--          before allowing a job to be closed. This provides an additional
--          safety layer beyond application-level validation.

BEGIN;

-- Step 1: Create function to validate all trips are completed for a job
CREATE OR REPLACE FUNCTION public.validate_all_trips_completed(p_job_id bigint)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_total_trips integer;
  v_completed_trips integer;
BEGIN
  -- Count total trips for this job
  SELECT COUNT(*) INTO v_total_trips
  FROM public.trip_progress
  WHERE job_id = p_job_id;

  -- If no trips exist, return true (job can be closed)
  IF v_total_trips = 0 THEN
    RETURN true;
  END IF;

  -- Count completed trips
  SELECT COUNT(*) INTO v_completed_trips
  FROM public.trip_progress
  WHERE job_id = p_job_id
  AND status = 'completed';

  -- Return true only if all trips are completed
  RETURN v_completed_trips = v_total_trips;
END;
$$;

-- Step 2: Create function to enforce job closure validation
CREATE OR REPLACE FUNCTION public.enforce_job_closure_requires_completed_trips()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = pg_catalog, public
AS $$
DECLARE
  v_all_trips_completed boolean;
BEGIN
  -- Only check when job_status is being set to 'completed'
  IF NEW.job_status = 'completed' AND (OLD.job_status IS NULL OR OLD.job_status != 'completed') THEN
    -- Validate all trips are completed
    v_all_trips_completed := public.validate_all_trips_completed(NEW.id);

    IF NOT v_all_trips_completed THEN
      RAISE EXCEPTION 'Cannot close job: not all trips are completed'
        USING ERRCODE = 'P0001',
              HINT = 'Please ensure all trips are marked as completed before closing the job.';
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Step 3: Create trigger on jobs table to enforce validation
DROP TRIGGER IF EXISTS trg_job_closure_requires_trips_completed ON public.jobs;

CREATE TRIGGER trg_job_closure_requires_trips_completed
  BEFORE UPDATE OF job_status ON public.jobs
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_job_closure_requires_completed_trips();

-- Step 4: Grant execute permissions
GRANT EXECUTE ON FUNCTION public.validate_all_trips_completed(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.validate_all_trips_completed(bigint) TO service_role;

-- Step 5: Add comments
COMMENT ON FUNCTION public.validate_all_trips_completed(bigint) IS 
  'Validates that all trips for a job are completed. Returns true if all trips have status = ''completed'', or if no trips exist.';

COMMENT ON FUNCTION public.enforce_job_closure_requires_completed_trips() IS 
  'Trigger function that enforces trip completion validation before allowing job_status to be set to ''completed''.';

COMMENT ON TRIGGER trg_job_closure_requires_trips_completed ON public.jobs IS 
  'Validates all trips are completed before allowing job_status to be set to ''completed''.';

COMMIT;
