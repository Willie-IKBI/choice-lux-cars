-- Migration: Add Unique Constraint for Notification Deduplication
-- Date: 2026-01-04
-- Purpose: Prevent duplicate notifications for the same (job_id, notification_type, user_id)
--          This ensures race-safe deduplication at the database level

BEGIN;

-- Step 1: Clean up existing duplicates (keep the oldest notification, delete newer ones)
-- This handles duplicates created before the constraint was added
WITH duplicates AS (
  SELECT 
    id,
    ROW_NUMBER() OVER (
      PARTITION BY job_id, notification_type, user_id 
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

-- Step 2: Add unique constraint on (job_id, notification_type, user_id)
-- Note: job_id is text, so we need to handle NULL values (job_id can be NULL for system notifications)
-- Using a partial unique index to exclude NULL job_id values
CREATE UNIQUE INDEX IF NOT EXISTS ux_app_notifications_job_type_user
  ON public.app_notifications (job_id, notification_type, user_id)
  WHERE job_id IS NOT NULL
  AND is_hidden = false;

-- Add comment
COMMENT ON INDEX ux_app_notifications_job_type_user IS
  'Unique constraint ensuring one notification per (job_id, notification_type, user_id) combination. Prevents duplicate notifications for the same job deadline warning to the same user. Excludes hidden notifications and NULL job_ids.';

COMMIT;

