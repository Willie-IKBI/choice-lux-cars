-- Migration: Admin close job support
-- Purpose: Allow administrator/super_admin to close jobs regardless of trip/vehicle status,
--          with mandatory comment and flag for reporting. Existing driver/normal close flow unchanged.

BEGIN;

-- ============================================================================
-- 1. Add columns to public.jobs for admin close
-- ============================================================================

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS closed_by uuid;

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS closed_at timestamptz;

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS closed_by_admin_ind boolean NOT NULL DEFAULT false;

ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS admin_close_comment text;

-- FK: closed_by -> profiles.id
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'jobs_closed_by_fkey' AND conrelid = 'public.jobs'::regclass
  ) THEN
    ALTER TABLE public.jobs
      ADD CONSTRAINT jobs_closed_by_fkey
      FOREIGN KEY (closed_by) REFERENCES public.profiles(id) ON DELETE SET NULL;
  END IF;
END $$;

COMMENT ON COLUMN public.jobs.closed_by IS 'User (profiles.id) who closed the job. Set when job_status is set to completed.';
COMMENT ON COLUMN public.jobs.closed_at IS 'Timestamp when the job was closed.';
COMMENT ON COLUMN public.jobs.closed_by_admin_ind IS 'True when job was closed by administrator/super_admin (overrides trip/vehicle checks). Used for reporting.';
COMMENT ON COLUMN public.jobs.admin_close_comment IS 'Mandatory comment when job is closed by admin (closed_by_admin_ind = true).';

-- CHECK: when closed_by_admin_ind is true, admin_close_comment must be non-empty
ALTER TABLE public.jobs
  DROP CONSTRAINT IF EXISTS check_admin_close_comment_required;

ALTER TABLE public.jobs
  ADD CONSTRAINT check_admin_close_comment_required
  CHECK (
    (closed_by_admin_ind = false)
    OR (admin_close_comment IS NOT NULL AND length(trim(admin_close_comment)) > 0)
  );

COMMENT ON CONSTRAINT check_admin_close_comment_required ON public.jobs IS
  'When closed_by_admin_ind is true, admin_close_comment must be non-empty.';

-- ============================================================================
-- 2. Trigger: skip trip validation when closed by admin
-- ============================================================================

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
    -- Skip validation when closed by admin (admin can close regardless of trip status)
    IF NEW.closed_by_admin_ind = true THEN
      RETURN NEW;
    END IF;

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

COMMENT ON FUNCTION public.enforce_job_closure_requires_completed_trips() IS
  'Enforces trip completion when job_status is set to completed. Skips validation when closed_by_admin_ind is true.';

-- Note: No new UPDATE policy on jobs; existing app update behavior (e.g. service_role or
-- existing policies) is unchanged. Admin close is performed by app with new columns.

COMMIT;
