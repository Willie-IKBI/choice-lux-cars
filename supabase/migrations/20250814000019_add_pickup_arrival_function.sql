-- Add Pickup Arrival Function
-- Applied: 2025-08-14
-- Description: Create function to handle pickup arrival with South African timezone

-- ========================================
-- CREATE ARRIVE AT PICKUP FUNCTION
-- ========================================

CREATE OR REPLACE FUNCTION arrive_at_pickup(
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
    WHERE j.id = arrive_at_pickup.job_id;
    
    -- Get current time in South African timezone (UTC+2)
    current_time_sa := NOW() AT TIME ZONE 'UTC' AT TIME ZONE 'Africa/Johannesburg';
    
    -- Update trip_progress table with pickup arrival data
    UPDATE trip_progress tp
    SET 
        pickup_arrived_at = current_time_sa,
        pickup_gps_lat = arrive_at_pickup.gps_lat,
        pickup_gps_lng = arrive_at_pickup.gps_lng,
        pickup_gps_accuracy = arrive_at_pickup.gps_accuracy,
        status = 'pickup_arrived',
        updated_at = NOW()
    WHERE tp.job_id = arrive_at_pickup.job_id 
      AND tp.trip_index = arrive_at_pickup.trip_index;
    
    -- Update driver_flow table to move to next step
    UPDATE driver_flow df
    SET 
        current_step = 'passenger_onboard',
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE df.job_id = arrive_at_pickup.job_id;
    
    -- Log the action
    RAISE NOTICE 'Driver % arrived at pickup for job % trip % at % (SA time)', 
        driver_id_val, arrive_at_pickup.job_id, arrive_at_pickup.trip_index, current_time_sa;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- GRANT PERMISSIONS
-- ========================================

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION arrive_at_pickup(bigint, integer, numeric, numeric, numeric) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION arrive_at_pickup(bigint, integer, numeric, numeric, numeric) IS 'Records pickup arrival with GPS coordinates and South African timestamp';

-- ========================================
-- VERIFY FUNCTION CREATION
-- ========================================

-- Check if function was created successfully
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name = 'arrive_at_pickup';

DO $$ 
BEGIN 
    RAISE NOTICE 'arrive_at_pickup function created successfully with South African timezone support';
END; 
$$;
