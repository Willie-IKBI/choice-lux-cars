-- Add pickup_arrival_img column to trip_progress table for storing
-- location photos taken when driver arrives at pickup location.
-- This is part of the enhanced driver flow requiring photo proof of arrival.

ALTER TABLE public.trip_progress
  ADD COLUMN IF NOT EXISTS pickup_arrival_img text;

COMMENT ON COLUMN public.trip_progress.pickup_arrival_img 
  IS 'URL of location photo taken when driver arrives at pickup.';
