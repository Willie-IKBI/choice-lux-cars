-- Migration: Normalize branch data for jobs table
-- Date: 2026-03-02
-- Purpose: Add numeric branch_id column to jobs table and migrate existing location data
--          This fixes the type mismatch between jobs.location (text) and profiles.branch_id (bigint)

BEGIN;

-- Add branch_id column to jobs table if not exists
-- Note: jobs already has a branch_id column (bigint), but it may not be populated
-- Let's verify and populate it from the location column

-- Populate branch_id from location for existing jobs
-- Mapping: 'Jhb' -> 3, 'Cpt' -> 2, 'Dbn' -> 1
UPDATE public.jobs
SET branch_id = CASE location
    WHEN 'Jhb' THEN 3
    WHEN 'Cpt' THEN 2
    WHEN 'Dbn' THEN 1
    ELSE NULL
END
WHERE branch_id IS NULL AND location IS NOT NULL;

-- Add comment explaining the column
COMMENT ON COLUMN public.jobs.branch_id IS 'Branch ID (1=Durban, 2=Cape Town, 3=Johannesburg). Used for RLS branch-based access control.';

-- Create index for branch_id to improve RLS query performance
CREATE INDEX IF NOT EXISTS idx_jobs_branch_id ON public.jobs(branch_id);

-- Create a function to auto-populate branch_id from location on insert/update
CREATE OR REPLACE FUNCTION public.sync_job_branch_id()
RETURNS TRIGGER AS $$
BEGIN
    -- If branch_id is not set but location is, derive branch_id from location
    IF NEW.branch_id IS NULL AND NEW.location IS NOT NULL THEN
        NEW.branch_id := CASE NEW.location
            WHEN 'Jhb' THEN 3
            WHEN 'Cpt' THEN 2
            WHEN 'Dbn' THEN 1
            ELSE NULL
        END;
    END IF;
    
    -- If location is not set but branch_id is, derive location from branch_id
    IF NEW.location IS NULL AND NEW.branch_id IS NOT NULL THEN
        NEW.location := CASE NEW.branch_id
            WHEN 3 THEN 'Jhb'
            WHEN 2 THEN 'Cpt'
            WHEN 1 THEN 'Dbn'
            ELSE NULL
        END;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to sync branch_id and location
DROP TRIGGER IF EXISTS trg_sync_job_branch_id ON public.jobs;
CREATE TRIGGER trg_sync_job_branch_id
    BEFORE INSERT OR UPDATE ON public.jobs
    FOR EACH ROW
    EXECUTE FUNCTION public.sync_job_branch_id();

COMMIT;
