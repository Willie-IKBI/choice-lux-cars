-- Migration: Backfill default notification preferences for existing users
-- Purpose: Set all notification preferences to ON (true) for all existing users
-- Date: 2025-12-17

-- Default notification preferences object with all types enabled (true)
-- This matches all notification types from the push notifications audit
UPDATE public.profiles
SET notification_prefs = '{
  "job_assignment": true,
  "job_reassignment": true,
  "job_confirmation": true,
  "job_cancelled": true,
  "job_status_change": true,
  "job_start": true,
  "step_completion": true,
  "job_completion": true,
  "job_start_deadline_warning_90min": true,
  "job_start_deadline_warning_30min": true,
  "payment_reminder": true,
  "system_alert": true
}'::jsonb
WHERE notification_prefs IS NULL 
   OR notification_prefs = '{}'::jsonb
   OR jsonb_typeof(notification_prefs) = 'null';

-- Log the number of users updated (for verification)
DO $$
DECLARE
  updated_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO updated_count
  FROM public.profiles
  WHERE notification_prefs IS NOT NULL 
    AND notification_prefs != '{}'::jsonb
    AND jsonb_typeof(notification_prefs) != 'null';
  
  RAISE NOTICE 'Notification preferences initialized for % users', updated_count;
END $$;

