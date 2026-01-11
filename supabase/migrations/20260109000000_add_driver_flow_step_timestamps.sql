-- Migration: Add Dedicated Timestamp Columns for Driver Flow Steps
-- Date: 2026-01-09
-- Purpose: Add dedicated timestamp columns for each step to prevent overwriting times
--          This fixes the issue where multiple steps were using last_activity_at,
--          causing previous step times to be lost.

BEGIN;

-- Add passenger_onboard_at timestamp for passenger onboard step
ALTER TABLE public.driver_flow
ADD COLUMN IF NOT EXISTS passenger_onboard_at timestamptz;

-- Add dropoff_arrive_at timestamp for dropoff arrival step
ALTER TABLE public.driver_flow
ADD COLUMN IF NOT EXISTS dropoff_arrive_at timestamptz;

-- Add trip_complete_at timestamp for trip complete step
ALTER TABLE public.driver_flow
ADD COLUMN IF NOT EXISTS trip_complete_at timestamptz;

-- Add comments to document the purpose of each column
COMMENT ON COLUMN public.driver_flow.passenger_onboard_at IS 
  'Timestamp when passenger was marked as onboard. Dedicated field to preserve step completion time.';

COMMENT ON COLUMN public.driver_flow.dropoff_arrive_at IS 
  'Timestamp when driver arrived at dropoff location. Dedicated field to preserve step completion time.';

COMMENT ON COLUMN public.driver_flow.trip_complete_at IS 
  'Timestamp when trip was marked as complete. Dedicated field to preserve step completion time.';

COMMIT;
