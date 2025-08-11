-- Fix Missing pdp_start_image Column
-- Applied: 2025-08-11
-- Description: Adds the missing pdp_start_image column to driver_flow table

-- Add the missing pdp_start_image column
ALTER TABLE driver_flow 
ADD COLUMN IF NOT EXISTS pdp_start_image text;
