-- Migration: Add notification_prefs JSONB column to profiles table
-- Purpose: Store per-user push notification preferences (super_admin only can edit)
-- Date: 2025-12-17

-- Add notification_prefs column if it doesn't exist
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS notification_prefs JSONB DEFAULT '{}'::jsonb;

-- Add comment explaining the column
COMMENT ON COLUMN public.profiles.notification_prefs IS 
'Per-user push notification preferences stored as JSONB. 
Format: {"job_assignment": true, "job_start": false, ...}
Controls whether push notifications (FCM) are sent for each notification type.
Only super_admin users can modify their own preferences.
Defaults to empty object {} - missing keys default to true (push enabled).
Does not affect in-app notification list visibility.';

-- Optional: Add GIN index for efficient querying by notification type
-- This allows queries like: WHERE notification_prefs->>'job_assignment' = 'false'
CREATE INDEX IF NOT EXISTS idx_profiles_notification_prefs_gin 
ON public.profiles USING GIN (notification_prefs);

