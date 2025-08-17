-- COMPREHENSIVE JOB FLOW FIX BASED ON ACTUAL SCHEMA
-- Run this in your Supabase SQL Editor to fix the job flow

-- ========================================
-- STEP 1: FIX SCHEMA ISSUES
-- ========================================

-- Clean up orphaned records first
DELETE FROM driver_flow 
WHERE job_id NOT IN (SELECT id FROM jobs);

DELETE FROM trip_progress 
WHERE job_id NOT IN (SELECT id FROM jobs);

-- Ensure we have at least one job for testing
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM jobs LIMIT 1) THEN
        -- Create a test job if none exists
        INSERT INTO jobs (client_id, agent_id, driver_id, job_status, order_date, job_start_date)
        VALUES (1, 1, (SELECT id FROM profiles WHERE role = 'driver' LIMIT 1), 'assigned', CURRENT_DATE, CURRENT_DATE);
    END IF;
END $$;

-- Add missing foreign key constraint (check if it exists first)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'driver_flow_job_id_fkey' 
        AND table_name = 'driver_flow'
    ) THEN
        ALTER TABLE driver_flow 
        ADD CONSTRAINT driver_flow_job_id_fkey 
        FOREIGN KEY (job_id) REFERENCES jobs(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Ensure all required columns exist with correct types
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
ADD COLUMN IF NOT EXISTS driver_user uuid REFERENCES profiles(id);

-- Add missing indexes for performance
CREATE INDEX IF NOT EXISTS idx_driver_flow_job_id ON driver_flow(job_id);
CREATE INDEX IF NOT EXISTS idx_driver_flow_current_step ON driver_flow(current_step);
CREATE INDEX IF NOT EXISTS idx_driver_flow_last_activity ON driver_flow(last_activity_at);
CREATE INDEX IF NOT EXISTS idx_trip_progress_job_id ON trip_progress(job_id);
CREATE INDEX IF NOT EXISTS idx_trip_progress_status ON trip_progress(status);

-- Ensure unique constraint exists on trip_progress
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name LIKE '%trip_progress%' 
        AND constraint_type = 'UNIQUE'
        AND table_name = 'trip_progress'
    ) THEN
        ALTER TABLE trip_progress 
        ADD CONSTRAINT trip_progress_job_trip_unique UNIQUE (job_id, trip_index);
    END IF;
END $$;

-- ========================================
-- STEP 2: DROP ALL EXISTING FUNCTIONS
-- ========================================

-- Drop all variations of start_job function to ensure clean slate
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric, numeric, numeric);
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric, numeric);
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text, numeric);
DROP FUNCTION IF EXISTS start_job(bigint, numeric, text);
DROP FUNCTION IF EXISTS start_job(bigint, numeric);
DROP FUNCTION IF EXISTS start_job(bigint);

-- Drop other job flow functions
DROP FUNCTION IF EXISTS arrive_at_pickup(bigint, integer, numeric, numeric, numeric);
DROP FUNCTION IF EXISTS passenger_onboard(bigint, integer);
DROP FUNCTION IF EXISTS arrive_at_dropoff(bigint, integer, numeric, numeric, numeric);
DROP FUNCTION IF EXISTS complete_trip(bigint, integer, text);

-- ========================================
-- STEP 3: CREATE FIXED START_JOB FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION start_job(
    p_job_id bigint,  -- Use p_job_id to avoid column ambiguity
    odo_start_reading numeric DEFAULT NULL,
    pdp_start_image text DEFAULT NULL,
    gps_lat numeric DEFAULT NULL,
    gps_lng numeric DEFAULT NULL,
    gps_accuracy numeric DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    driver_uuid uuid;
BEGIN
    -- Get the driver for this job (use explicit table alias)
    SELECT j.driver_id INTO driver_uuid 
    FROM jobs j 
    WHERE j.id = p_job_id;
    
    IF driver_uuid IS NULL THEN
        RAISE EXCEPTION 'No driver assigned to job %', p_job_id;
    END IF;
    
    -- Ensure driver_flow record exists
    INSERT INTO driver_flow (job_id, driver_user, current_step, last_activity_at)
    SELECT 
        p_job_id,
        driver_uuid,
        'vehicle_collection',
        NOW()
    WHERE NOT EXISTS (
        SELECT 1 FROM driver_flow df WHERE df.job_id = p_job_id
    );
    
    -- Update job status to started
    UPDATE jobs j
    SET job_status = 'started'
    WHERE j.id = p_job_id;
    
    -- Update driver_flow with start details
    UPDATE driver_flow df
    SET 
        job_started_at = NOW(),
        odo_start_reading = COALESCE(start_job.odo_start_reading, df.odo_start_reading),
        pdp_start_image = COALESCE(start_job.pdp_start_image, df.pdp_start_image),
        pickup_loc = CASE 
            WHEN start_job.gps_lat IS NOT NULL AND start_job.gps_lng IS NOT NULL 
            THEN format('POINT(%s %s)', start_job.gps_lng, start_job.gps_lat)
            ELSE df.pickup_loc 
        END,
        vehicle_collected = true,
        vehicle_collected_at = NOW(),
        current_step = 'pickup_arrival',
        progress_percentage = 20,
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE df.job_id = p_job_id;
    
    -- Create initial trip_progress record if none exists
    INSERT INTO trip_progress (job_id, trip_index, status)
    VALUES (p_job_id, 1, 'pending')
    ON CONFLICT (job_id, trip_index) DO NOTHING;
    
    -- Log success
    RAISE NOTICE 'Job % started successfully by driver %', p_job_id, driver_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 4: CREATE ARRIVE AT PICKUP FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION arrive_at_pickup(
    p_job_id bigint,
    trip_index integer,
    gps_lat numeric,
    gps_lng numeric,
    gps_accuracy numeric DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    driver_id_val UUID;
BEGIN
    -- Get the driver_id from the jobs table
    SELECT j.driver_id INTO driver_id_val
    FROM jobs j
    WHERE j.id = p_job_id;
    
    -- Update trip_progress table with pickup arrival data
    UPDATE trip_progress tp
    SET 
        pickup_arrived_at = NOW(),
        pickup_gps_lat = arrive_at_pickup.gps_lat,
        pickup_gps_lng = arrive_at_pickup.gps_lng,
        pickup_gps_accuracy = arrive_at_pickup.gps_accuracy,
        status = 'pickup_arrived',
        updated_at = NOW()
    WHERE tp.job_id = p_job_id 
      AND tp.trip_index = arrive_at_pickup.trip_index;
    
    -- Update driver_flow table to move to next step
    UPDATE driver_flow df
    SET 
        current_step = 'passenger_onboard',
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE df.job_id = p_job_id;
    
    -- Log the action
    RAISE NOTICE 'Driver % arrived at pickup for job % trip %', 
        driver_id_val, p_job_id, arrive_at_pickup.trip_index;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 5: CREATE PASSENGER ONBOARD FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION passenger_onboard(
    p_job_id bigint,
    trip_index integer
)
RETURNS void AS $$
DECLARE
    driver_id_val UUID;
BEGIN
    -- Get the driver_id from the jobs table
    SELECT j.driver_id INTO driver_id_val
    FROM jobs j
    WHERE j.id = p_job_id;
    
    -- Update trip_progress table with passenger onboard data
    UPDATE trip_progress tp
    SET 
        passenger_onboard_at = NOW(),
        status = 'onboard',
        updated_at = NOW()
    WHERE tp.job_id = p_job_id 
      AND tp.trip_index = passenger_onboard.trip_index;
    
    -- Update driver_flow table to move to next step
    UPDATE driver_flow df
    SET 
        current_step = 'dropoff_arrival',
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE df.job_id = p_job_id;
    
    -- Log the action
    RAISE NOTICE 'Driver % recorded passenger onboard for job % trip %', 
        driver_id_val, p_job_id, passenger_onboard.trip_index;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 6: CREATE ARRIVE AT DROPOFF FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION arrive_at_dropoff(
    p_job_id bigint,
    trip_index integer,
    gps_lat numeric,
    gps_lng numeric,
    gps_accuracy numeric DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    driver_id_val UUID;
BEGIN
    -- Get the driver_id from the jobs table
    SELECT j.driver_id INTO driver_id_val
    FROM jobs j
    WHERE j.id = p_job_id;
    
    -- Update trip_progress table with dropoff arrival data
    UPDATE trip_progress tp
    SET 
        dropoff_arrived_at = NOW(),
        dropoff_gps_lat = arrive_at_dropoff.gps_lat,
        dropoff_gps_lng = arrive_at_dropoff.gps_lng,
        dropoff_gps_accuracy = arrive_at_dropoff.gps_accuracy,
        status = 'dropoff_arrived',
        updated_at = NOW()
    WHERE tp.job_id = p_job_id 
      AND tp.trip_index = arrive_at_dropoff.trip_index;
    
    -- Update driver_flow table to move to next step
    UPDATE driver_flow df
    SET 
        current_step = 'trip_complete',
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE df.job_id = p_job_id;
    
    -- Log the action
    RAISE NOTICE 'Driver % arrived at dropoff for job % trip %', 
        driver_id_val, p_job_id, arrive_at_dropoff.trip_index;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 7: CREATE COMPLETE TRIP FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION complete_trip(
    p_job_id bigint,
    trip_index integer,
    notes text DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    driver_id_val UUID;
BEGIN
    -- Get the driver_id from the jobs table
    SELECT j.driver_id INTO driver_id_val
    FROM jobs j
    WHERE j.id = p_job_id;
    
    -- Update trip_progress table with trip completion data
    UPDATE trip_progress tp
    SET 
        status = 'completed',
        notes = complete_trip.notes,
        updated_at = NOW()
    WHERE tp.job_id = p_job_id 
      AND tp.trip_index = complete_trip.trip_index;
    
    -- Update driver_flow table to move to next step
    UPDATE driver_flow df
    SET 
        current_step = 'vehicle_return',
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE df.job_id = p_job_id;
    
    -- Log the action
    RAISE NOTICE 'Driver % completed trip for job % trip %', 
        driver_id_val, p_job_id, complete_trip.trip_index;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- STEP 8: GRANT PERMISSIONS
-- ========================================

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION start_job(bigint, numeric, text, numeric, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION arrive_at_pickup(bigint, integer, numeric, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION passenger_onboard(bigint, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION arrive_at_dropoff(bigint, integer, numeric, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_trip(bigint, integer, text) TO authenticated;

-- ========================================
-- STEP 9: VERIFY FIX
-- ========================================

-- Check if functions exist
SELECT 
    routine_name, 
    routine_type,
    specific_name
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN ('start_job', 'arrive_at_pickup', 'passenger_onboard', 'arrive_at_dropoff', 'complete_trip')
ORDER BY routine_name;

-- Test with a sample job (replace 1 with actual job ID)
-- SELECT start_job(1, 12345.0, 'test_image_url.jpg', -26.2041, 28.0473, 10.0);
