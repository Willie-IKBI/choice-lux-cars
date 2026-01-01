BEGIN;

-- 1) Normalize existing rows:
update public.profiles
set branch_id = null
where role in ('administrator'::user_role_enum, 'super_admin'::user_role_enum);

-- If a non-admin has NULL branch_id, they must be treated as "unassigned"
-- Since role is an enum (and has no 'unassigned' value), we set:
--   role = NULL
--   status = 'unassigned'
update public.profiles
set role = null,
    status = 'unassigned'
where role is not null
  and role not in ('administrator'::user_role_enum, 'super_admin'::user_role_enum)
  and branch_id is null;

-- 2) Fix FK delete behavior (required because current FK is ON DELETE SET NULL)
alter table public.profiles
drop constraint if exists profiles_branch_id_fkey;

alter table public.profiles
add constraint profiles_branch_id_fkey
foreign key (branch_id)
references public.branches(id)
on update cascade
on delete restrict;

-- 3) Enforce rule going forward
alter table public.profiles
add constraint profiles_branch_id_by_role_chk
check (
  -- Admin/Super Admin must be national
  (role in ('administrator'::user_role_enum, 'super_admin'::user_role_enum) and branch_id is null)

  or

  -- Non-admin roles must be branch-scoped
  (role is not null and role not in ('administrator'::user_role_enum, 'super_admin'::user_role_enum) and branch_id is not null)

  or

  -- Unassigned users: role NULL, no branch, status must be 'unassigned'
  (role is null and branch_id is null and status = 'unassigned')
);

COMMIT;

