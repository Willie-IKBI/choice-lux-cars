-- Migrate jobs.location text values to jobs.branch_id
-- Maps: 'Cpt' -> Cape Town branch_id, 'Dbn' -> Durban branch_id, 'Jhb' -> Johannesburg branch_id
-- Only updates rows where branch_id is NULL and location is not NULL

do $$
declare
  affected_rows integer;
  cpt_branch_id bigint;
  dbn_branch_id bigint;
  jhb_branch_id bigint;
begin
  -- Get branch IDs from branches table
  select id into cpt_branch_id from public.branches where code = 'Cpt';
  select id into dbn_branch_id from public.branches where code = 'Dbn';
  select id into jhb_branch_id from public.branches where code = 'Jhb';

  -- Log branch IDs for verification
  raise notice 'Branch IDs - Cape Town: %, Durban: %, Johannesburg: %', cpt_branch_id, dbn_branch_id, jhb_branch_id;

  -- Update jobs with location = 'Cpt' to Cape Town branch_id
  update public.jobs
  set branch_id = cpt_branch_id
  where location = 'Cpt' 
    and branch_id is null;
  
  get diagnostics affected_rows = row_count;
  raise notice 'Updated % jobs with location Cpt to branch_id %', affected_rows, cpt_branch_id;

  -- Update jobs with location = 'Dbn' to Durban branch_id
  update public.jobs
  set branch_id = dbn_branch_id
  where location = 'Dbn' 
    and branch_id is null;
  
  get diagnostics affected_rows = row_count;
  raise notice 'Updated % jobs with location Dbn to branch_id %', affected_rows, dbn_branch_id;

  -- Update jobs with location = 'Jhb' to Johannesburg branch_id
  update public.jobs
  set branch_id = jhb_branch_id
  where location = 'Jhb' 
    and branch_id is null;
  
  get diagnostics affected_rows = row_count;
  raise notice 'Updated % jobs with location Jhb to branch_id %', affected_rows, jhb_branch_id;

  -- Report any jobs with unmapped location values
  select count(*) into affected_rows
  from public.jobs
  where location is not null 
    and location not in ('Cpt', 'Dbn', 'Jhb')
    and branch_id is null;
  
  if affected_rows > 0 then
    raise notice 'Warning: % jobs have unmapped location values (not Cpt, Dbn, or Jhb)', affected_rows;
  end if;

  -- Report total jobs that still need branch_id assignment
  select count(*) into affected_rows
  from public.jobs
  where branch_id is null;
  
  if affected_rows > 0 then
    raise notice 'Info: % jobs still have NULL branch_id (location was NULL or unmapped)', affected_rows;
  else
    raise notice 'Success: All jobs with valid location values have been migrated to branch_id';
  end if;
end$$;

-- Add comment documenting the migration
comment on column public.jobs.location is 'DEPRECATED: Legacy field. Use branch_id instead. Location values (Cpt, Dbn, Jhb) have been migrated to branch_id referencing branches table. This column will be removed in a future migration.';

