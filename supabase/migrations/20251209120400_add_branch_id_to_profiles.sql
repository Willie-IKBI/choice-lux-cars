-- Add branch_id column to profiles table
-- NULL branch_id = Admin/National access (can see all branches)
-- Non-null branch_id = User is allocated to specific branch

alter table public.profiles
  add column if not exists branch_id bigint;

-- Add foreign key constraint to branches table
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'profiles_branch_id_fkey'
  ) then
    alter table public.profiles
      add constraint profiles_branch_id_fkey
      foreign key (branch_id)
      references public.branches (id)
      on update cascade
      on delete set null;
  end if;
end$$;

-- Create index for efficient queries
create index if not exists idx_profiles_branch_id
  on public.profiles (branch_id)
  where branch_id is not null;

-- Add comment for documentation
comment on column public.profiles.branch_id is 'Branch allocation for user. NULL = Admin/National access (can see all branches). Non-null = User allocated to specific Choice Lux Cars branch (Durban, Cape Town, or Johannesburg).';

