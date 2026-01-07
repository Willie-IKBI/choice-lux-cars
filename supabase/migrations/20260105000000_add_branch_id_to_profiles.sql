-- Migration: Add branch_id column to profiles table
-- Date: 2026-01-05
-- Purpose: Add branch assignment for users (Jhb, Cpt, Dbn)
--          Branch assignment is required for users to access the system

BEGIN;

-- Add branch_id column to profiles table
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS branch_id text;

-- Add comment
COMMENT ON COLUMN public.profiles.branch_id IS 'Branch assignment for the user (Jhb, Cpt, Dbn). Required for active users to access the system.';

COMMIT;

