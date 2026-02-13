-- Index jobs.closed_by (FK to profiles.id) for performance
-- Recommended by Supabase linter for unindexed foreign keys
CREATE INDEX IF NOT EXISTS idx_jobs_closed_by ON jobs(closed_by);
