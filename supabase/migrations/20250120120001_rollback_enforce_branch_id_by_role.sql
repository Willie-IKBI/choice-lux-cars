BEGIN;

ALTER TABLE public.profiles
DROP CONSTRAINT IF EXISTS profiles_branch_id_by_role_chk;

ALTER TABLE public.profiles
DROP CONSTRAINT IF EXISTS profiles_branch_id_fkey;

ALTER TABLE public.profiles
ADD CONSTRAINT profiles_branch_id_fkey
FOREIGN KEY (branch_id)
REFERENCES public.branches(id)
ON UPDATE CASCADE
ON DELETE SET NULL;

COMMIT;

