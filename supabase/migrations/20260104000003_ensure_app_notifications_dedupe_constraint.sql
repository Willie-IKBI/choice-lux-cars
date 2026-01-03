-- Migration: Ensure Unique Constraint for Notification Deduplication
-- Date: 2026-01-04
-- Purpose: Ensure unique constraint exists on (job_id, user_id, notification_type) to prevent duplicates
--          This provides defense-in-depth for deduplication at the database level
--          Includes cleanup of existing duplicates before creating constraint

BEGIN;

-- Step 1: Clean up existing duplicates (keep the oldest notification, delete newer ones)
-- This handles duplicates created before the constraint was added
WITH duplicates AS (
  SELECT 
    id,
    ROW_NUMBER() OVER (
      PARTITION BY job_id, user_id, notification_type 
      ORDER BY created_at ASC, id ASC
    ) as row_num
  FROM public.app_notifications
  WHERE job_id IS NOT NULL
  AND is_hidden = false
)
DELETE FROM public.app_notifications
WHERE id IN (
  SELECT id FROM duplicates WHERE row_num > 1
);

-- Step 2: Drop existing index if it exists (to recreate with correct column order)
DROP INDEX IF EXISTS public.ux_app_notifications_job_type_user;

-- Step 3: Create unique index on (job_id, user_id, notification_type)
-- Note: job_id is text, so we need to handle NULL values (job_id can be NULL for system notifications)
-- Using a partial unique index to exclude NULL job_id values and hidden notifications
CREATE UNIQUE INDEX IF NOT EXISTS ux_app_notifications_job_user_type
  ON public.app_notifications (job_id, user_id, notification_type)
  WHERE job_id IS NOT NULL
  AND is_hidden = false;

-- Add comment
COMMENT ON INDEX ux_app_notifications_job_user_type IS
  'Unique constraint ensuring one notification per (job_id, user_id, notification_type) combination. Prevents duplicate notifications for the same job deadline warning to the same user. Excludes hidden notifications and NULL job_ids.';

COMMIT;

