-- Driver Flow Schema Updates Migration
-- Applied: 2025-08-11
-- Description: Updates driver_flow table and creates trip_progress table for granular job tracking

-- 1. Add new columns to driver_flow table
ALTER TABLE driver_flow ADD COLUMN IF NOT EXISTS current_step text DEFAULT 'vehicle_collection';
ALTER TABLE driver_flow ADD COLUMN IF NOT EXISTS current_trip_index integer DEFAULT 1;
ALTER TABLE driver_flow ADD COLUMN IF NOT EXISTS progress_percentage integer DEFAULT 0;
ALTER TABLE driver_flow ADD COLUMN IF NOT EXISTS last_activity_at timestamptz;
ALTER TABLE driver_flow ADD COLUMN IF NOT EXISTS job_started_at timestamptz;
ALTER TABLE driver_flow ADD COLUMN IF NOT EXISTS vehicle_collected_at timestamptz;

-- 2. Create trip_progress table for individual trip tracking
CREATE TABLE IF NOT EXISTS trip_progress (
    id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    job_id bigint REFERENCES jobs(id) ON DELETE CASCADE,
    trip_index integer NOT NULL,
    pickup_arrived_at timestamptz,
    pickup_gps_lat numeric(10, 8),
    pickup_gps_lng numeric(11, 8),
    pickup_gps_accuracy numeric(5, 2),
    passenger_onboard_at timestamptz,
    dropoff_arrived_at timestamptz,
    dropoff_gps_lat numeric(10, 8),
    dropoff_gps_lng numeric(11, 8),
    dropoff_gps_accuracy numeric(5, 2),
    status text DEFAULT 'pending' CHECK (status IN ('pending', 'pickup_arrived', 'onboard', 'dropoff_arrived', 'completed')),
    notes text,
    created_at timestamptz DEFAULT NOW(),
    updated_at timestamptz DEFAULT NOW(),
    UNIQUE(job_id, trip_index)
);

-- 3. Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_trip_progress_job_id ON trip_progress(job_id);
CREATE INDEX IF NOT EXISTS idx_trip_progress_status ON trip_progress(status);
CREATE INDEX IF NOT EXISTS idx_driver_flow_current_step ON driver_flow(current_step);
CREATE INDEX IF NOT EXISTS idx_driver_flow_last_activity ON driver_flow(last_activity_at);

-- 4. Add trigger to update last_activity_at
CREATE OR REPLACE FUNCTION update_driver_flow_activity()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_activity_at = NOW();
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_driver_flow_activity ON driver_flow;
CREATE TRIGGER trigger_update_driver_flow_activity
    BEFORE UPDATE ON driver_flow
    FOR EACH ROW
    EXECUTE FUNCTION update_driver_flow_activity();

-- 5. Add trigger to update trip_progress updated_at
CREATE OR REPLACE FUNCTION update_trip_progress_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_trip_progress_timestamp ON trip_progress;
CREATE TRIGGER trigger_update_trip_progress_timestamp
    BEFORE UPDATE ON trip_progress
    FOR EACH ROW
    EXECUTE FUNCTION update_trip_progress_timestamp();

-- 6. Create view for job progress summary
CREATE OR REPLACE VIEW job_progress_summary AS
SELECT 
    j.id as job_id,
    j.job_status,
    j.driver_id,
    df.current_step,
    df.current_trip_index,
    df.progress_percentage,
    df.last_activity_at,
    df.job_started_at,
    df.vehicle_collected,
    df.vehicle_collected_at,
    df.transport_completed_ind,
    df.job_closed_time,
    COUNT(tp.id) as total_trips,
    COUNT(CASE WHEN tp.status = 'completed' THEN 1 END) as completed_trips,
    CASE 
        WHEN df.job_closed_time IS NOT NULL THEN 'completed'
        WHEN df.transport_completed_ind = true THEN 'ready_to_close'
        WHEN df.vehicle_collected = true THEN 'in_progress'
        WHEN df.job_started_at IS NOT NULL THEN 'started'
        ELSE 'assigned'
    END as calculated_status
FROM jobs j
LEFT JOIN driver_flow df ON j.id = df.job_id
LEFT JOIN trip_progress tp ON j.id = tp.job_id
GROUP BY j.id, j.job_status, j.driver_id, df.current_step, df.current_trip_index, 
         df.progress_percentage, df.last_activity_at, df.job_started_at, 
         df.vehicle_collected, df.vehicle_collected_at, df.transport_completed_ind, df.job_closed_time;

-- 7. Function to calculate progress percentage
CREATE OR REPLACE FUNCTION calculate_job_progress(job_id_param bigint)
RETURNS integer AS $$
DECLARE
    total_steps integer;
    completed_steps integer;
    df_record driver_flow%ROWTYPE;
    trip_count integer;
    completed_trips integer;
BEGIN
    -- Get driver flow record
    SELECT * INTO df_record FROM driver_flow WHERE job_id = job_id_param;
    
    IF df_record IS NULL THEN
        RETURN 0;
    END IF;
    
    -- Count total trips for this job
    SELECT COUNT(*) INTO trip_count FROM transport WHERE job_id = job_id_param;
    
    -- Count completed trips
    SELECT COUNT(*) INTO completed_trips 
    FROM trip_progress 
    WHERE job_id = job_id_param AND status = 'completed';
    
    -- Calculate total steps: 1 (vehicle collection) + (3 steps per trip) + 1 (vehicle return)
    total_steps := 1 + (trip_count * 3) + 1;
    
    -- Calculate completed steps
    completed_steps := 0;
    
    -- Vehicle collection step
    IF df_record.vehicle_collected = true THEN
        completed_steps := completed_steps + 1;
    END IF;
    
    -- Trip steps (3 per trip)
    completed_steps := completed_steps + (completed_trips * 3);
    
    -- Vehicle return step
    IF df_record.job_closed_time IS NOT NULL THEN
        completed_steps := completed_steps + 1;
    END IF;
    
    -- Return percentage
    IF total_steps = 0 THEN
        RETURN 0;
    ELSE
        RETURN ROUND((completed_steps::numeric / total_steps::numeric) * 100);
    END IF;
END;
$$ LANGUAGE plpgsql;
