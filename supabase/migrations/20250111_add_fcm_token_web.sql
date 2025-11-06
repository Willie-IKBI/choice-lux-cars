-- Migration: Add fcm_token_web column for web push notifications
-- Purpose: Support separate FCM tokens for web and mobile devices
-- Created: 2025-01-11

-- Add fcm_token_web column for web platform tokens
-- Keep fcm_token for mobile/Android tokens (backward compatibility)
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS fcm_token_web text NULL;

-- Add comment
COMMENT ON COLUMN public.profiles.fcm_token_web IS 'FCM token for web platform push notifications';
COMMENT ON COLUMN public.profiles.fcm_token IS 'FCM token for mobile/Android platform push notifications';

-- Create index for faster lookups (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token_web ON public.profiles(fcm_token_web) WHERE fcm_token_web IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token_mobile ON public.profiles(fcm_token) WHERE fcm_token IS NOT NULL;




