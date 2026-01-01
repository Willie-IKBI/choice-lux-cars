-- Migration 4: Trip Validation Functions
-- Purpose: Validate all trips are completed for job closure
-- Prerequisites: Migrations 1, 2, and 3 must be applied

BEGIN;

CREATE OR REPLACE FUNCTION public.validate_all_trips_completed(p_job_id bigint)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    total_trips_count integer;
    progress_trips_count integer;
    completed_trips_count integer;
BEGIN
    -- Total trips are defined by transport rows for the job
    SELECT COUNT(*)
    INTO total_trips_count
    FROM public.transport
    WHERE job_id = p_job_id;

    -- If job has zero trips, allow closure
    IF total_trips_count = 0 THEN
        RETURN true;
    END IF;

    -- If there are trips but no trip_progress rows yet, do NOT allow closure
    SELECT COUNT(*)
    INTO progress_trips_count
    FROM public.trip_progress
    WHERE job_id = p_job_id;

    IF progress_trips_count = 0 THEN
        RETURN false;
    END IF;

    -- Count completed trips in trip_progress
    SELECT COUNT(*)
    INTO completed_trips_count
    FROM public.trip_progress
    WHERE job_id = p_job_id
      AND status = 'completed';

    -- Allow closure only if completed trips match total trips
    RETURN (completed_trips_count = total_trips_count);
END;
$$;

GRANT EXECUTE ON FUNCTION public.validate_all_trips_completed(bigint) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.validate_all_trips_completed(bigint) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.validate_all_trips_completed(bigint) FROM anon;

COMMENT ON FUNCTION public.validate_all_trips_completed(bigint) IS
'Returns true if a job has zero trips. If a job has trips, returns true only when trip_progress has rows and the number of completed trip_progress rows equals the number of transport trip rows. Used to prevent closing jobs before completing all trips.';

COMMIT;
