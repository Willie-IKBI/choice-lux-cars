-- Add branch_id column to vehicles table
-- Initially nullable to allow manual assignment of existing vehicles
-- After all vehicles are assigned, this can be made NOT NULL

alter table public.vehicles
  add column if not exists branch_id bigint;

-- Add foreign key constraint to branches table
-- Using RESTRICT to prevent deletion of branches that have vehicles assigned
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'vehicles_branch_id_fkey'
  ) then
    alter table public.vehicles
      add constraint vehicles_branch_id_fkey
      foreign key (branch_id)
      references public.branches (id)
      on update cascade
      on delete restrict;
  end if;
end$$;

-- Create index for efficient queries
create index if not exists idx_vehicles_branch_id
  on public.vehicles (branch_id)
  where branch_id is not null;

-- Add comment for documentation
comment on column public.vehicles.branch_id is 'Branch allocation for vehicle. Each vehicle must be allocated to a specific Choice Lux Cars branch (Durban, Cape Town, or Johannesburg). NULL temporarily allowed for existing vehicles until manually assigned.';

