-- Migration: Add location column to jobs table
-- Date: 2026-01-04
-- Purpose: Add location column for branch-based filtering in insights
--          Location values: 'Jhb', 'Cpt', 'Dbn', or NULL

BEGIN;

-- Add location column to jobs table
ALTER TABLE public.jobs
ADD COLUMN IF NOT EXISTS location text;

-- Add comment
COMMENT ON COLUMN public.jobs.location IS 'Branch location for the job (Jhb, Cpt, Dbn). Used for location-based filtering in insights.';

COMMIT;

