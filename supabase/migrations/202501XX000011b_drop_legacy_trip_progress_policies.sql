-- Migration 11b: Drop Legacy Trip Progress Policies
-- Purpose: Remove legacy permissive policies that conflict with granular RLS policies
-- Prerequisites: Migration 11 must be applied
--
-- This migration drops the legacy policies:
-- 1) "Authenticated users can read trip_progress" (SELECT policy)
-- 2) "Drivers can update their trip_progress" (UPDATE policy)
--
-- These policies are replaced by the granular policies created in Migration 11:
-- - trip_progress_select_policy
-- - trip_progress_update_policy

BEGIN;

-- Drop legacy SELECT policy
DROP POLICY IF EXISTS "Authenticated users can read trip_progress" ON public.trip_progress;

-- Drop legacy UPDATE policy
DROP POLICY IF EXISTS "Drivers can update their trip_progress" ON public.trip_progress;

COMMIT;

