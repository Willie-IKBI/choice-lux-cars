-- Migration: Add Passenger No-Show Support
-- Date: 2026-01-09
-- Purpose: Add fields to track passenger no-show scenarios in driver flow
--          Allows drivers to mark passenger as no-show with mandatory comment,
--          skip passenger collection/dropoff steps, and still complete job.

BEGIN;

-- Add passenger_no_show_ind boolean flag to driver_flow table
ALTER TABLE public.driver_flow
ADD COLUMN IF NOT EXISTS passenger_no_show_ind boolean DEFAULT false;

-- Add passenger_no_show_comment text field to store driver's comment
ALTER TABLE public.driver_flow
ADD COLUMN IF NOT EXISTS passenger_no_show_comment text;

-- Add passenger_no_show_at timestamp to record when no-show was marked
ALTER TABLE public.driver_flow
ADD COLUMN IF NOT EXISTS passenger_no_show_at timestamptz;

-- Add comments to document the purpose of each column
COMMENT ON COLUMN public.driver_flow.passenger_no_show_ind IS 
  'Boolean flag indicating passenger did not show up at pickup location. When true, passenger_onboard and dropoff_arrival steps are skipped.';

COMMENT ON COLUMN public.driver_flow.passenger_no_show_comment IS 
  'Mandatory comment from driver explaining the no-show situation. Required when passenger_no_show_ind is set to true.';

COMMENT ON COLUMN public.driver_flow.passenger_no_show_at IS 
  'Timestamp when driver marked passenger as no-show. Recorded after pickup arrival but before passenger onboard step.';

COMMIT;
