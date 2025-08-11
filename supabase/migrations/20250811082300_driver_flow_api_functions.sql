-- Driver Flow API Functions Migration
-- Applied: 2025-08-11
-- Description: Creates RPC functions for driver flow API endpoints

-- 1. Function to start a job
CREATE OR REPLACE FUNCTION start_job(
    job_id bigint,
    odo_start_reading numeric,
    pdp_start_image text,
    gps_lat numeric,
    gps_lng numeric,
    gps_accuracy numeric DEFAULT NULL
)
RETURNS void AS $$
BEGIN
    -- Update driver_flow table
    UPDATE driver_flow 
    SET 
        job_started_at = NOW(),
        odo_start_reading = odo_start_reading,
        pdp_start_image = pdp_start_image,
        pickup_loc = format('POINT(%s %s)', gps_lng, gps_lat),
        current_step = 'vehicle_collection',
        last_activity_at = NOW()
    WHERE driver_flow.job_id = start_job.job_id;
    
    -- Update jobs table status
    UPDATE jobs 
    SET job_status = 'started'::job_status_enum
    WHERE id = start_job.job_id;
    
    -- Create notification for job started
    PERFORM create_job_notification(job_id, 'job_started', 
        format('Job %s has been started', job_id));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Function to resume a job
CREATE OR REPLACE FUNCTION resume_job(job_id bigint)
RETURNS void AS $$
BEGIN
    -- Update last activity
    UPDATE driver_flow 
    SET last_activity_at = NOW()
    WHERE driver_flow.job_id = resume_job.job_id;
    
    -- Create notification for job resumed
    PERFORM create_job_notification(job_id, 'job_started', 
        format('Job %s has been resumed', job_id));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Function to close a job
CREATE OR REPLACE FUNCTION close_job(job_id bigint)
RETURNS void AS $$
BEGIN
    -- Update jobs table status
    UPDATE jobs 
    SET job_status = 'completed'::job_status_enum
    WHERE id = close_job.job_id;
    
    -- Update driver_flow table
    UPDATE driver_flow 
    SET 
        transport_completed_ind = true,
        last_activity_at = NOW()
    WHERE driver_flow.job_id = close_job.job_id;
    
    -- Create notification for job completed
    PERFORM create_job_notification(job_id, 'job_completed', 
        format('Job %s has been completed', job_id));
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Function to get driver's current job
DROP FUNCTION IF EXISTS get_driver_current_job(uuid);
CREATE OR REPLACE FUNCTION get_driver_current_job(driver_uuid uuid)
RETURNS TABLE (
    job_id bigint,
    current_step text,
    progress_percentage integer,
    last_activity_at timestamptz,
    total_trips integer,
    completed_trips integer
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        df.job_id,
        df.current_step,
        df.progress_percentage,
        df.last_activity_at,
        jps.total_trips,
        jps.completed_trips
    FROM driver_flow df
    LEFT JOIN job_progress_summary jps ON df.job_id = jps.job_id
    WHERE df.driver_user = driver_uuid
    AND df.job_closed_time IS NULL
    ORDER BY df.last_activity_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Function to get active jobs for monitoring
DROP FUNCTION IF EXISTS get_active_jobs_for_monitoring();
CREATE OR REPLACE FUNCTION get_active_jobs_for_monitoring()
RETURNS TABLE (
    job_id bigint,
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. Function to check for stalled jobs
DROP FUNCTION IF EXISTS check_stalled_jobs();
CREATE OR REPLACE FUNCTION check_stalled_jobs()
RETURNS void AS $$
DECLARE
    stalled_job RECORD;
    message text;
BEGIN
    -- Find jobs that haven't had activity in the last 2 hours
    FOR stalled_job IN 
        SELECT 
            j.id as job_id,
            p.display_name as driver_name,
            df.last_activity_at,
            df.current_step
        FROM jobs j
        LEFT JOIN driver_flow df ON j.id = df.job_id
        LEFT JOIN profiles p ON j.driver_id = p.id
        WHERE j.job_status IN ('started', 'in_progress', 'ready_to_close')
        AND df.last_activity_at < NOW() - INTERVAL '2 hours'
        AND df.last_activity_at > NOW() - INTERVAL '24 hours' -- Only recent jobs
    LOOP
        message := format('Job %s by driver %s appears stalled at step: %s', 
                         stalled_job.job_id, stalled_job.driver_name, stalled_job.current_step);
        
        PERFORM create_job_notification(stalled_job.job_id, 'job_stalled', message);
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Function to get user notifications
DROP FUNCTION IF EXISTS get_user_notifications(uuid, integer);
CREATE OR REPLACE FUNCTION get_user_notifications(user_uuid uuid, limit_count integer DEFAULT 50)
RETURNS TABLE (
    id uuid,
    message text,
    notification_type notification_type_enum,
    job_id bigint,
    created_at timestamptz,
    read_at timestamptz,
    dismissed_at timestamptz
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        n.id,
        n.message,
        n.notification_type,
        n.job_id,
        n.created_at,
        n.read_at,
        n.dismissed_at
    FROM notifications n
    WHERE n.user_id = user_uuid
    ORDER BY n.created_at DESC
    LIMIT limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Function to mark notification as read
DROP FUNCTION IF EXISTS mark_notification_read(uuid);
CREATE OR REPLACE FUNCTION mark_notification_read(notification_id_param uuid)
RETURNS void AS $$
BEGIN
    UPDATE notifications 
    SET read_at = NOW()
    WHERE id = notification_id_param
    AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. Function to dismiss notification
DROP FUNCTION IF EXISTS dismiss_notification(uuid);
CREATE OR REPLACE FUNCTION dismiss_notification(notification_id_param uuid)
RETURNS void AS $$
BEGIN
    UPDATE notifications 
    SET dismissed_at = NOW()
    WHERE id = notification_id_param
    AND user_id = auth.uid();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 10. Function to create job notification
DROP FUNCTION IF EXISTS create_job_notification(bigint, notification_type_enum, text);
CREATE OR REPLACE FUNCTION create_job_notification(
    job_id_param bigint,
    notification_type_param notification_type_enum,
    message_param text
)
RETURNS void AS $$
DECLARE
    driver_id uuid;
    admin_users uuid[];
    manager_users uuid[];
    target_user uuid;
BEGIN
    -- Get driver ID for this job
    SELECT j.driver_id INTO driver_id FROM jobs j WHERE j.id = job_id_param;
    
    -- Get all admin and manager users
    SELECT ARRAY_AGG(id) INTO admin_users 
    FROM profiles 
    WHERE role = 'administrator';
    
    SELECT ARRAY_AGG(id) INTO manager_users 
    FROM profiles 
    WHERE role = 'manager';
    
    -- Create notifications for all relevant users
    -- Admins
    IF admin_users IS NOT NULL THEN
        FOREACH target_user IN ARRAY admin_users
        LOOP
            INSERT INTO notifications (user_id, message, notification_type, job_id, created_at)
            VALUES (target_user, message_param, notification_type_param, job_id_param, NOW());
        END LOOP;
    END IF;
    
    -- Managers
    IF manager_users IS NOT NULL THEN
        FOREACH target_user IN ARRAY manager_users
        LOOP
            INSERT INTO notifications (user_id, message, notification_type, job_id, created_at)
            VALUES (target_user, message_param, notification_type_param, job_id_param, NOW());
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
