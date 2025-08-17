-- Fix Step Progression Functions Migration
-- Applied: 2025-08-15
-- Description: Adds proper database functions for step progression

-- ========================================
-- PASSENGER ONBOARD FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION passenger_onboard(
    job_id bigint,
    trip_index integer
)
RETURNS void AS $$
DECLARE
    driver_id_val UUID;
    current_time_sa timestamp with time zone;
BEGIN
    -- Get the driver_id from the jobs table
    SELECT j.driver_id INTO driver_id_val
    FROM jobs j
    WHERE j.id = passenger_onboard.job_id;
    
    -- Get current time in South African timezone (UTC+2)
    current_time_sa := NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Africa/Johannesburg';
    
    -- Update trip_progress table with passenger onboard data
    UPDATE trip_progress tp
    SET 
        passenger_onboard_at = current_time_sa,
        status = 'onboard',
        updated_at = NOW()
    WHERE tp.job_id = passenger_onboard.job_id 
      AND tp.trip_index = passenger_onboard.trip_index;
    
    -- Update driver_flow table to move to next step
    UPDATE driver_flow df
    SET 
        current_step = 'dropoff_arrival',
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE df.job_id = passenger_onboard.job_id;
    
    -- Log the action
    RAISE NOTICE 'Driver % recorded passenger onboard for job % trip % at % (SA time)', 
        driver_id_val, passenger_onboard.job_id, passenger_onboard.trip_index, current_time_sa;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- DROPOFF ARRIVAL FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION arrive_at_dropoff(
    job_id bigint,
    trip_index integer,
    gps_lat numeric,
    gps_lng numeric,
    gps_accuracy numeric DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    driver_id_val UUID;
    current_time_sa timestamp with time zone;
BEGIN
    -- Get the driver_id from the jobs table
    SELECT j.driver_id INTO driver_id_val
    FROM jobs j
    WHERE j.id = arrive_at_dropoff.job_id;
    
    -- Get current time in South African timezone (UTC+2)
    current_time_sa := NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Africa/Johannesburg';
    
    -- Update trip_progress table with dropoff arrival data
    UPDATE trip_progress tp
    SET 
        dropoff_arrived_at = current_time_sa,
        dropoff_gps_lat = arrive_at_dropoff.gps_lat,
        dropoff_gps_lng = arrive_at_dropoff.gps_lng,
        dropoff_gps_accuracy = arrive_at_dropoff.gps_accuracy,
        status = 'dropoff_arrived',
        updated_at = NOW()
    WHERE tp.job_id = arrive_at_dropoff.job_id 
      AND tp.trip_index = arrive_at_dropoff.trip_index;
    
    -- Update driver_flow table to move to next step
    UPDATE driver_flow df
    SET 
        current_step = 'trip_complete',
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE df.job_id = arrive_at_dropoff.job_id;
    
    -- Log the action
    RAISE NOTICE 'Driver % arrived at dropoff for job % trip % at % (SA time)', 
        driver_id_val, arrive_at_dropoff.job_id, arrive_at_dropoff.trip_index, current_time_sa;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- COMPLETE TRIP FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION complete_trip(
    job_id bigint,
    trip_index integer,
    notes text DEFAULT NULL
)
RETURNS void AS $$
DECLARE
    driver_id_val UUID;
    current_time_sa timestamp with time zone;
BEGIN
    -- Get the driver_id from the jobs table
    SELECT j.driver_id INTO driver_id_val
    FROM jobs j
    WHERE j.id = complete_trip.job_id;
    
    -- Get current time in South African timezone (UTC+2)
    current_time_sa := NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Africa/Johannesburg';
    
    -- Update trip_progress table with trip completion data
    UPDATE trip_progress tp
    SET 
        status = 'completed',
        notes = complete_trip.notes,
        updated_at = NOW()
    WHERE tp.job_id = complete_trip.job_id 
      AND tp.trip_index = complete_trip.trip_index;
    
    -- Update driver_flow table to move to next step
    UPDATE driver_flow df
    SET 
        current_step = 'vehicle_return',
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE df.job_id = complete_trip.job_id;
    
    -- Log the action
    RAISE NOTICE 'Driver % completed trip for job % trip % at % (SA time)', 
        driver_id_val, complete_trip.job_id, complete_trip.trip_index, current_time_sa;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- GRANT PERMISSIONS
-- ========================================

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION passenger_onboard(bigint, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION arrive_at_dropoff(bigint, integer, numeric, numeric, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION complete_trip(bigint, integer, text) TO authenticated;

-- ========================================
-- ADD COMMENTS FOR DOCUMENTATION
-- ========================================

COMMENT ON FUNCTION passenger_onboard(bigint, integer) IS 'Records passenger onboard with South African timestamp';
COMMENT ON FUNCTION arrive_at_dropoff(bigint, integer, numeric, numeric, numeric) IS 'Records dropoff arrival with GPS coordinates and South African timestamp';
COMMENT ON FUNCTION complete_trip(bigint, integer, text) IS 'Records trip completion with optional notes and South African timestamp';

-- ========================================
-- VERIFY FUNCTION CREATION
-- ========================================

-- Check if functions were created successfully
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN ('passenger_onboard', 'arrive_at_dropoff', 'complete_trip');

DO $$ 
BEGIN 
    RAISE NOTICE 'Step progression functions created successfully with South African timezone support';
END; 
$$;
