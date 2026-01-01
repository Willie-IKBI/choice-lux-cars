BEGIN;

-- 1) Fix the create_user_profile function to set proper RBAC defaults
CREATE OR REPLACE FUNCTION public.create_user_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $$
BEGIN
  INSERT INTO public.profiles(
    id,
    display_name,
    user_email,
    role,
    status,
    branch_id
  )
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'display_name', 'Add User Name'),
    NEW.email,
    NULL, -- role is NULL for unassigned users
    'unassigned', -- status must be 'unassigned' for new users
    NULL -- branch_id is NULL for unassigned users
  )
  ON CONFLICT (id) DO NOTHING; -- Prevent duplicate inserts
  RETURN NEW;
END;
$$;

-- 2) Create the trigger on auth.users if it doesn't exist
DROP TRIGGER IF EXISTS new_user_trigger ON auth.users;

CREATE TRIGGER new_user_trigger
AFTER INSERT ON auth.users
FOR EACH ROW
EXECUTE FUNCTION public.create_user_profile();

-- 3) Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.create_user_profile() TO anon;
GRANT EXECUTE ON FUNCTION public.create_user_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_user_profile() TO service_role;

COMMIT;

