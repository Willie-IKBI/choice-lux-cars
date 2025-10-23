-- Add index on driver_id field for better performance on driver role filtering
-- This will improve query performance when filtering jobs by driver_id

-- Create index on driver_id field
CREATE INDEX IF NOT EXISTS idx_jobs_driver_id 
ON public.jobs 
USING btree (driver_id) 
TABLESPACE pg_default;

-- Add comment to document the purpose
COMMENT ON INDEX idx_jobs_driver_id IS 'Index on driver_id field for efficient driver role-based filtering';

-- Optional: Create a partial index for non-null driver_id values only
-- This can be more efficient if most queries only need jobs with assigned drivers
CREATE INDEX IF NOT EXISTS idx_jobs_driver_id_not_null 
ON public.jobs 
USING btree (driver_id) 
TABLESPACE pg_default
WHERE driver_id IS NOT NULL;

-- Add comment for the partial index
COMMENT ON INDEX idx_jobs_driver_id_not_null IS 'Partial index on non-null driver_id values for driver role filtering';
