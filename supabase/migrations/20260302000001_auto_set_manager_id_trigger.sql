-- Auto-populate manager_id on jobs based on creator role or branch manager.
-- The 90-min deadline notification requires manager_id to be set, but
-- the Flutter app never sets it. This trigger fills the gap.

CREATE OR REPLACE FUNCTION public.auto_set_manager_id()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_creator_role text;
  v_branch_manager_id uuid;
BEGIN
  IF NEW.manager_id IS NOT NULL THEN
    RETURN NEW;
  END IF;

  -- If creator is a manager, assign them directly
  IF NEW.created_by IS NOT NULL THEN
    SELECT role INTO v_creator_role
    FROM public.profiles
    WHERE id = NEW.created_by::uuid AND status = 'active';

    IF v_creator_role = 'manager' THEN
      NEW.manager_id := NEW.created_by::uuid;
      RETURN NEW;
    END IF;
  END IF;

  -- Otherwise, find the active manager for this branch
  IF NEW.branch_id IS NOT NULL THEN
    SELECT id INTO v_branch_manager_id
    FROM public.profiles
    WHERE role = 'manager'
      AND branch_id = NEW.branch_id
      AND status = 'active'
    LIMIT 1;

    IF v_branch_manager_id IS NOT NULL THEN
      NEW.manager_id := v_branch_manager_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_auto_set_manager_id ON public.jobs;

CREATE TRIGGER trg_auto_set_manager_id
  BEFORE INSERT OR UPDATE ON public.jobs
  FOR EACH ROW
  EXECUTE FUNCTION public.auto_set_manager_id();

-- Backfill: set manager_id for existing jobs where branch matches a manager
UPDATE public.jobs j
SET manager_id = p.id
FROM public.profiles p
WHERE j.manager_id IS NULL
  AND j.branch_id IS NOT NULL
  AND p.role = 'manager'
  AND p.branch_id = j.branch_id
  AND p.status = 'active';

-- Backfill: set manager_id for jobs created by a manager
UPDATE public.jobs j
SET manager_id = j.created_by::uuid
FROM public.profiles p
WHERE j.manager_id IS NULL
  AND j.created_by IS NOT NULL
  AND j.created_by::uuid = p.id
  AND p.role = 'manager'
  AND p.status = 'active';
