-- Migration: Job Review and Decline Flow
-- Purpose: Add support for driver submit -> manager review -> approve/decline workflow
-- Date: 2025-01-22
--
-- Changes:
-- 1. Add approval columns (approved_by, approved_at)
-- 2. Add decline columns (declined_by, declined_at, decline_reason)
-- 3. Add CHECK constraint to enforce decline_reason when status is 'declined'
-- 4. Add indexes for performance on review queue queries
--
-- Note: jobs.job_status is TEXT (not enum), so no enum modifications needed.
-- The app will use 'review' and 'declined' as text values.

BEGIN;

-- ============================================================================
-- 1. Add approval columns to public.jobs
-- ============================================================================

-- Add approved_by column (manager who approved the job)
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS approved_by uuid;

-- Add approved_at column (timestamp when job was approved)
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS approved_at timestamptz;

-- Add foreign key: approved_by -> profiles.id
-- Using ON DELETE SET NULL to preserve audit trail if manager is deleted
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'jobs_approved_by_fkey'
    AND conrelid = 'public.jobs'::regclass
  ) THEN
    ALTER TABLE public.jobs
      ADD CONSTRAINT jobs_approved_by_fkey
      FOREIGN KEY (approved_by)
      REFERENCES public.profiles(id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- Add comments
COMMENT ON COLUMN public.jobs.approved_by IS 'Manager (from profiles) who approved the job. NULL if not yet approved.';
COMMENT ON COLUMN public.jobs.approved_at IS 'Timestamp when the job was approved by a manager. NULL if not yet approved.';

-- ============================================================================
-- 2. Add decline columns to public.jobs
-- ============================================================================

-- Add declined_by column (manager who declined the job)
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS declined_by uuid;

-- Add declined_at column (timestamp when job was declined)
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS declined_at timestamptz;

-- Add decline_reason column (required text reason for decline)
-- Initially nullable to avoid breaking existing rows, but CHECK constraint enforces when declined
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS decline_reason text;

-- Add foreign key: declined_by -> profiles.id
-- Using ON DELETE SET NULL to preserve audit trail if manager is deleted
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'jobs_declined_by_fkey'
    AND conrelid = 'public.jobs'::regclass
  ) THEN
    ALTER TABLE public.jobs
      ADD CONSTRAINT jobs_declined_by_fkey
      FOREIGN KEY (declined_by)
      REFERENCES public.profiles(id)
      ON DELETE SET NULL;
  END IF;
END $$;

-- Add comments
COMMENT ON COLUMN public.jobs.declined_by IS 'Manager (from profiles) who declined the job. NULL if not declined.';
COMMENT ON COLUMN public.jobs.declined_at IS 'Timestamp when the job was declined by a manager. NULL if not declined.';
COMMENT ON COLUMN public.jobs.decline_reason IS 'Required reason text when job_status is ''declined''. Enforced by CHECK constraint.';

-- ============================================================================
-- 3. Add CHECK constraint to enforce decline_reason when status is 'declined'
-- ============================================================================

-- Drop existing constraint if it exists (for idempotency)
ALTER TABLE public.jobs
  DROP CONSTRAINT IF EXISTS check_decline_reason_required;

-- Add CHECK constraint: if job_status = 'declined', then decline_reason must be non-empty
ALTER TABLE public.jobs
  ADD CONSTRAINT check_decline_reason_required
  CHECK (
    job_status != 'declined' 
    OR (
      decline_reason IS NOT NULL 
      AND length(trim(decline_reason)) > 0
    )
  );

COMMENT ON CONSTRAINT check_decline_reason_required ON public.jobs IS 
  'Enforces that decline_reason must be provided (non-empty) when job_status is ''declined''.';

-- ============================================================================
-- 4. Add indexes for performance
-- ============================================================================

-- Index on job_status for review queue queries (filtering by status)
-- Partial index on 'review' status for manager review queue
CREATE INDEX IF NOT EXISTS idx_jobs_status_review 
  ON public.jobs(job_status) 
  WHERE job_status = 'review';

-- Index on approved_by for queries filtering by approver
CREATE INDEX IF NOT EXISTS idx_jobs_approved_by 
  ON public.jobs(approved_by, approved_at) 
  WHERE approved_by IS NOT NULL;

-- Index on declined_by for queries filtering by decliner
CREATE INDEX IF NOT EXISTS idx_jobs_declined_by 
  ON public.jobs(declined_by, declined_at) 
  WHERE declined_by IS NOT NULL;

-- General index on job_status (if not exists) for all status-based queries
-- Check if a general index exists first
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
    AND tablename = 'jobs'
    AND indexname = 'idx_jobs_status'
  ) THEN
    CREATE INDEX idx_jobs_status ON public.jobs(job_status);
  END IF;
END $$;

-- ============================================================================
-- Migration Complete
-- ============================================================================

COMMIT;

