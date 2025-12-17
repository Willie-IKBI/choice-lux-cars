-- Migration: Add super_admin role to user_role_enum
-- Purpose: Add super_admin role for users who can configure their own notification preferences
-- Date: 2025-12-17

-- Add 'super_admin' value to the existing enum
-- Note: ALTER TYPE ... ADD VALUE cannot be run inside a transaction block in PostgreSQL
-- This is safe to run multiple times (idempotent check)
DO $$
BEGIN
    -- Check if 'super_admin' already exists in the enum
    IF NOT EXISTS (
        SELECT 1 
        FROM pg_enum 
        WHERE enumlabel = 'super_admin' 
        AND enumtypid = 'public.user_role_enum'::regtype
    ) THEN
        ALTER TYPE public.user_role_enum ADD VALUE 'super_admin';
    END IF;
END $$;

-- Add comment to document the new role
COMMENT ON TYPE public.user_role_enum IS 'User roles: administrator (full access), super_admin (full access + notification preferences), manager (branch-scoped), driver_manager (branch-scoped), driver (branch-scoped), suspended (disabled)';

