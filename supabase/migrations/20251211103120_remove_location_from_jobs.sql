-- Remove deprecated location column from jobs table
-- This migration should be run after verifying that the data migration from location to branch_id
-- (migration 20251209120700_migrate_jobs_location_to_branch_id.sql) has completed successfully.
--
-- IMPORTANT: Backup your database before running this migration!
-- The location column contains historical data that will be permanently removed.
--
-- After this migration:
-- - All branch references should use branch_id (FK to branches table)
-- - The location column will no longer exist
-- - Historical location data ('Cpt', 'Dbn', 'Jhb') has been migrated to branch_id

-- Step 1: Verify that all jobs have been migrated (optional check)
-- Uncomment the following to verify before dropping:
-- SELECT COUNT(*) FROM public.jobs WHERE location IS NOT NULL AND branch_id IS NULL;
-- If this returns 0, it's safe to proceed.

-- Step 2: Drop the location column
-- This will permanently remove the column and all its data
do $$
begin
  -- Check if column exists before dropping
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
    and table_name = 'jobs'
    and column_name = 'location'
  ) then
    alter table public.jobs drop column location;
    raise notice 'Dropped location column from jobs table.';
  else
    raise notice 'Location column does not exist in jobs table. Migration may have already been applied.';
  end if;
end$$;

-- Add comment documenting the migration
comment on table public.jobs is 'Jobs table. Branch allocation is managed via branch_id (FK to branches table). The deprecated location column has been removed.';

