-- Progress Management System
-- Real-time tracking and status indicators for administrators/managers

-- 1. Create job status enum
CREATE TYPE job_status_enum AS ENUM (
    'assigned',      -- Job assigned to driver
    'started',       -- Driver started the job
    'in_progress',   -- Vehicle collected, trips in progress
    'ready_to_close', -- All trips completed, ready for vehicle return
    'completed',     -- Job fully completed
    'cancelled'      -- Job cancelled
);

-- 2. Update jobs table to use enum
ALTER TABLE jobs ALTER COLUMN job_status TYPE job_status_enum USING job_status::job_status_enum;

-- 3. Create driver activity tracking view
CREATE VIEW driver_activity_summary AS
SELECT 
    p.id as driver_id,
    p.display_name as driver_name,
    p.number as driver_phone,
    COUNT(CASE WHEN jps.calculated_status = 'assigned' THEN 1 END) as assigned_jobs,
    COUNT(CASE WHEN jps.calculated_status = 'started' THEN 1 END) as started_jobs,
    COUNT(CASE WHEN jps.calculated_status = 'in_progress' THEN 1 END) as active_jobs,
    COUNT(CASE WHEN jps.calculated_status = 'ready_to_close' THEN 1 END) as ready_to_close_jobs,
    MAX(jps.last_activity_at) as last_activity,
    CASE 
        WHEN MAX(jps.last_activity_at) > NOW() - INTERVAL '30 minutes' THEN 'active'
        WHEN MAX(jps.last_activity_at) > NOW() - INTERVAL '2 hours' THEN 'recent'
        ELSE 'inactive'
    END as driver_status
FROM profiles p
LEFT JOIN job_progress_summary jps ON p.id = jps.driver_id
WHERE p.role = 'driver'
GROUP BY p.id, p.display_name, p.number;

-- 4. Create current job status view for dashboard
CREATE VIEW current_job_status AS
SELECT 
    j.id as job_id,
    j.job_status,
    c.company_name as client_name,
    p.display_name as driver_name,
    p.number as driver_phone,
    df.current_step,
    df.current_trip_index,
    df.progress_percentage,
    df.last_activity_at,
    df.job_started_at,
    jps.calculated_status,
    jps.total_trips,
    jps.completed_trips,
    CASE 
        WHEN df.last_activity_at > NOW() - INTERVAL '15 minutes' THEN 'very_recent'
        WHEN df.last_activity_at > NOW() - INTERVAL '1 hour' THEN 'recent'
        WHEN df.last_activity_at > NOW() - INTERVAL '4 hours' THEN 'stale'
        ELSE 'old'
    END as activity_recency,
    -- Calculate ETA based on current progress
    CASE 
        WHEN df.progress_percentage = 0 THEN NULL
        WHEN df.progress_percentage = 100 THEN df.job_closed_time
        ELSE df.job_started_at + (
            (NOW() - df.job_started_at) * (100.0 / df.progress_percentage)
        )
    END as estimated_completion
FROM jobs j
LEFT JOIN driver_flow df ON j.id = df.job_id
LEFT JOIN job_progress_summary jps ON j.id = jps.job_id
LEFT JOIN clients c ON j.client_id = c.id
LEFT JOIN profiles p ON j.driver_id = p.id
WHERE j.job_status NOT IN ('completed', 'cancelled')
ORDER BY df.last_activity_at DESC NULLS LAST;

-- 5. Create function to update job status based on progress
CREATE OR REPLACE FUNCTION update_job_status_from_progress()
RETURNS TRIGGER AS $$
BEGIN
    -- Update job status based on driver flow progress
    UPDATE jobs 
    SET job_status = 
        CASE 
            WHEN NEW.job_closed_time IS NOT NULL THEN 'completed'::job_status_enum
            WHEN NEW.transport_completed_ind = true THEN 'ready_to_close'::job_status_enum
            WHEN NEW.vehicle_collected = true THEN 'in_progress'::job_status_enum
            WHEN NEW.job_started_at IS NOT NULL THEN 'started'::job_status_enum
            ELSE 'assigned'::job_status_enum
        END
    WHERE id = NEW.job_id;
    
    -- Update progress percentage
    NEW.progress_percentage = calculate_job_progress(NEW.job_id);
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_job_status
    BEFORE UPDATE ON driver_flow
    FOR EACH ROW
    EXECUTE FUNCTION update_job_status_from_progress();

-- 6. Create function to get driver's current job
CREATE OR REPLACE FUNCTION get_driver_current_job(driver_uuid uuid)
RETURNS TABLE (
    job_id bigint,
    client_name text,
    current_step text,
    progress_percentage integer,
    last_activity_at timestamptz,
    total_trips integer,
    completed_trips integer
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cjs.job_id,
        cjs.client_name,
        cjs.current_step,
        cjs.progress_percentage,
        cjs.last_activity_at,
        cjs.total_trips,
        cjs.completed_trips
    FROM current_job_status cjs
    WHERE cjs.driver_id = driver_uuid
    AND cjs.calculated_status IN ('started', 'in_progress', 'ready_to_close')
    ORDER BY cjs.last_activity_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- 7. Create function to get all active jobs for monitoring
CREATE OR REPLACE FUNCTION get_active_jobs_for_monitoring()
RETURNS TABLE (
    job_id bigint,
    client_name text,
    driver_name text,
    driver_phone text,
    current_step text,
    progress_percentage integer,
    last_activity_at timestamptz,
    activity_recency text,
    estimated_completion timestamptz
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        cjs.job_id,
        cjs.client_name,
        cjs.driver_name,
        cjs.driver_phone,
        cjs.current_step,
        cjs.progress_percentage,
        cjs.last_activity_at,
        cjs.activity_recency,
        cjs.estimated_completion
    FROM current_job_status cjs
    WHERE cjs.calculated_status IN ('started', 'in_progress', 'ready_to_close')
    ORDER BY 
        CASE cjs.activity_recency
            WHEN 'very_recent' THEN 1
            WHEN 'recent' THEN 2
            WHEN 'stale' THEN 3
            ELSE 4
        END,
        cjs.last_activity_at DESC;
END;
$$ LANGUAGE plpgsql;
