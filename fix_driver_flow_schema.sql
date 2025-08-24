-- Fix Driver Flow Schema
-- Run this in your Supabase SQL Editor to fix the driver flow table

-- Ensure all required columns exist in driver_flow table
ALTER TABLE driver_flow 
ADD COLUMN IF NOT EXISTS pickup_loc text,
ADD COLUMN IF NOT EXISTS pdp_start_image text,
ADD COLUMN IF NOT EXISTS odo_start_reading numeric,
ADD COLUMN IF NOT EXISTS job_started_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS current_step text DEFAULT 'vehicle_collection',
ADD COLUMN IF NOT EXISTS last_activity_at timestamp with time zone DEFAULT now(),
ADD COLUMN IF NOT EXISTS current_trip_index integer DEFAULT 1,
ADD COLUMN IF NOT EXISTS progress_percentage integer DEFAULT 0,
ADD COLUMN IF NOT EXISTS vehicle_collected_at timestamp with time zone,
ADD COLUMN IF NOT EXISTS vehicle_collected boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS job_closed_odo numeric,
ADD COLUMN IF NOT EXISTS job_closed_odo_img text,
ADD COLUMN IF NOT EXISTS job_closed_time timestamp with time zone,
ADD COLUMN IF NOT EXISTS transport_completed_ind boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS payment_collected_ind boolean DEFAULT false,
ADD COLUMN IF NOT EXISTS driver_user uuid REFERENCES profiles(id),
ADD COLUMN IF NOT EXISTS updated_at timestamp with time zone DEFAULT now();

-- Add missing indexes for performance
CREATE INDEX IF NOT EXISTS idx_driver_flow_job_id ON driver_flow(job_id);
CREATE INDEX IF NOT EXISTS idx_driver_flow_current_step ON driver_flow(current_step);
CREATE INDEX IF NOT EXISTS idx_driver_flow_last_activity ON driver_flow(last_activity_at);

-- Ensure trip_progress table exists with correct structure
CREATE TABLE IF NOT EXISTS trip_progress (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    job_id bigint REFERENCES jobs(id) ON DELETE CASCADE,
    trip_index integer NOT NULL,
    pickup_arrived_at timestamp with time zone,
    pickup_gps_lat numeric(10, 8),
    pickup_gps_lng numeric(11, 8),
    pickup_gps_accuracy numeric(5, 2),
    passenger_onboard_at timestamp with time zone,
    dropoff_arrived_at timestamp with time zone,
    dropoff_gps_lat numeric(10, 8),
    dropoff_gps_lng numeric(11, 8),
    dropoff_gps_accuracy numeric(5, 2),
    status text DEFAULT 'pending',
    notes text,
    created_at timestamp with time zone DEFAULT NOW(),
    updated_at timestamp with time zone DEFAULT NOW(),
    UNIQUE(job_id, trip_index)
);

-- Add indexes for trip_progress
CREATE INDEX IF NOT EXISTS idx_trip_progress_job_id ON trip_progress(job_id);
CREATE INDEX IF NOT EXISTS idx_trip_progress_status ON trip_progress(status);

-- Verify the schema
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'driver_flow' 
ORDER BY ordinal_position;

-- Show trip_progress schema
SELECT 
    column_name, 
    data_type, 
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'trip_progress' 
ORDER BY ordinal_position;
