-- Add missing roles used by the app to the user_role_enum
-- This fixes: invalid input value for enum user_role_enum: "unassigned"
--
-- NOTE: ALTER TYPE ... ADD VALUE can be sensitive to transaction wrapping on some Postgres versions.
-- We intentionally do NOT wrap this migration in BEGIN/COMMIT.

ALTER TYPE public.user_role_enum ADD VALUE IF NOT EXISTS 'unassigned';
ALTER TYPE public.user_role_enum ADD VALUE IF NOT EXISTS 'agent';


