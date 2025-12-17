-- Fix jobs.branch_id foreign key constraint
-- Change from client_branches (client-specific branches) to branches (company branches)
-- This aligns jobs with Choice Lux Cars company branches, not client branches

-- Drop existing FK constraint that references client_branches
do $$
begin
  if exists (
    select 1 from pg_constraint
    where conname = 'jobs_branch_id_fkey'
  ) then
    alter table public.jobs
      drop constraint jobs_branch_id_fkey;
    raise notice 'Dropped existing jobs_branch_id_fkey constraint';
  end if;
end$$;

-- Create new FK constraint referencing company branches table
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'jobs_branch_id_fkey'
  ) then
    alter table public.jobs
      add constraint jobs_branch_id_fkey
      foreign key (branch_id)
      references public.branches (id)
      on update cascade
      on delete set null;
    raise notice 'Created new jobs_branch_id_fkey constraint referencing branches table';
  end if;
end$$;

-- Verify index exists (should already exist from previous migration)
create index if not exists idx_jobs_branch_id
  on public.jobs (branch_id)
  where branch_id is not null;

-- Add comment for documentation
comment on column public.jobs.branch_id is 'Branch allocation for job. References company branches table (Durban, Cape Town, Johannesburg), not client_branches. Used to filter jobs by Choice Lux Cars branch location.';

