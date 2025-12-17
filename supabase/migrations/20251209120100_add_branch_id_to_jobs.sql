-- Add branch_id column to jobs table
alter table public.jobs
  add column if not exists branch_id bigint;

-- Add foreign key constraint to client_branches
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'jobs_branch_id_fkey'
  ) then
    alter table public.jobs
      add constraint jobs_branch_id_fkey
      foreign key (branch_id)
      references public.client_branches (id)
      on update cascade
      on delete set null;
  end if;
end$$;

-- Create index for efficient queries
create index if not exists idx_jobs_branch_id
  on public.jobs (branch_id)
  where branch_id is not null;

