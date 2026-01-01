-- Migration 7b: Drop Legacy Expenses Policy
-- Purpose: Remove legacy permissive policy that conflicts with granular RLS policies
-- Prerequisites: Migration 7 must be applied
--
-- This migration drops the legacy policy "Allow authenticated access to expenses"
-- which was overly permissive (USING true / WITH CHECK true) and granted ALL
-- operations to all authenticated users. This policy conflicts with the granular
-- RLS policies created in Migration 7 (expenses_select_policy, expenses_insert_policy,
-- expenses_update_policy, expenses_delete_policy) which enforce proper access control
-- based on job assignment and approval status.

BEGIN;

-- Drop legacy permissive policy that grants ALL access to authenticated
DROP POLICY IF EXISTS "Allow authenticated access to expenses" ON public.expenses;

COMMIT;

