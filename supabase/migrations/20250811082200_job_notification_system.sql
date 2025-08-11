-- Job Progress Notification System Migration
-- Applied: 2025-08-11
-- Description: Extends notifications table and implements automatic job progress notifications

-- 1. Create notification types enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
        CREATE TYPE notification_type_enum AS ENUM (
            'job_started',
            'passenger_onboard',
            'job_completed',
            'job_stalled',
            'driver_inactive'
        );
    END IF;
END $$;

-- 2. Add notification type column to notifications table
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS notification_type notification_type_enum;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS job_id bigint REFERENCES jobs(id);
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS read_at timestamptz;
ALTER TABLE notifications ADD COLUMN IF NOT EXISTS dismissed_at timestamptz;

-- 3. Create indexes for notification queries
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(notification_type);
CREATE INDEX IF NOT EXISTS idx_notifications_job_id ON notifications(job_id);
CREATE INDEX IF NOT EXISTS idx_notifications_read_at ON notifications(read_at);

-- 4. Function to create job progress notifications
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
    driver_manager_users uuid[];
    target_user uuid;
BEGIN
    -- Get driver ID for this job
    SELECT j.driver_id INTO driver_id FROM jobs j WHERE j.id = job_id_param;
    
    -- Get all admin, manager, and driver_manager users
    SELECT ARRAY_AGG(id) INTO admin_users 
    FROM profiles 
    WHERE role = 'admin';
    
    SELECT ARRAY_AGG(id) INTO manager_users 
    FROM profiles 
    WHERE role = 'manager';
    
    SELECT ARRAY_AGG(id) INTO driver_manager_users 
    FROM profiles 
    WHERE role = 'driver_manager';
    
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
    
    -- Driver Managers
    IF driver_manager_users IS NOT NULL THEN
        FOREACH target_user IN ARRAY driver_manager_users
        LOOP
            INSERT INTO notifications (user_id, message, notification_type, job_id, created_at)
            VALUES (target_user, message_param, notification_type_param, job_id_param, NOW());
        END LOOP;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- 5. Function to mark notification as read
CREATE OR REPLACE FUNCTION mark_notification_read(notification_id_param uuid)
RETURNS void AS $$
BEGIN
    UPDATE notifications 
    SET read_at = NOW()
    WHERE id = notification_id_param;
END;
$$ LANGUAGE plpgsql;

-- 6. Function to dismiss notification
CREATE OR REPLACE FUNCTION dismiss_notification(notification_id_param uuid)
RETURNS void AS $$
BEGIN
    UPDATE notifications 
    SET dismissed_at = NOW()
    WHERE id = notification_id_param;
END;
$$ LANGUAGE plpgsql;

-- 7. Trigger for job started notification
CREATE OR REPLACE FUNCTION notify_job_started()
RETURNS TRIGGER AS $$
DECLARE
    client_name text;
    driver_name text;
    message text;
BEGIN
    -- Only trigger when job is first started
    IF OLD.job_started_at IS NULL AND NEW.job_started_at IS NOT NULL THEN
        -- Get client and driver names
        SELECT c.company_name, p.display_name 
        INTO client_name, driver_name
        FROM jobs j
        LEFT JOIN clients c ON j.client_id = c.id
        LEFT JOIN profiles p ON j.driver_id = p.id
        WHERE j.id = NEW.job_id;
        
        message := format('Driver %s started job for client %s', driver_name, client_name);
        
        PERFORM create_job_notification(NEW.job_id, 'job_started', message);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_job_started ON driver_flow;
CREATE TRIGGER trigger_notify_job_started
    AFTER UPDATE ON driver_flow
    FOR EACH ROW
    EXECUTE FUNCTION notify_job_started();

-- 8. Trigger for passenger onboard notification
CREATE OR REPLACE FUNCTION notify_passenger_onboard()
RETURNS TRIGGER AS $$
DECLARE
    client_name text;
    driver_name text;
    message text;
BEGIN
    -- Only trigger when passenger gets onboard
    IF OLD.passenger_onboard_at IS NULL AND NEW.passenger_onboard_at IS NOT NULL THEN
        -- Get client and driver names
        SELECT c.company_name, p.display_name 
        INTO client_name, driver_name
        FROM jobs j
        LEFT JOIN clients c ON j.client_id = c.id
        LEFT JOIN profiles p ON j.driver_id = p.id
        WHERE j.id = NEW.job_id;
        
        message := format('Driver %s picked up passenger for client %s', driver_name, client_name);
        
        PERFORM create_job_notification(NEW.job_id, 'passenger_onboard', message);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_passenger_onboard ON trip_progress;
CREATE TRIGGER trigger_notify_passenger_onboard
    AFTER UPDATE ON trip_progress
    FOR EACH ROW
    EXECUTE FUNCTION notify_passenger_onboard();

-- 9. Trigger for job completed notification
CREATE OR REPLACE FUNCTION notify_job_completed()
RETURNS TRIGGER AS $$
DECLARE
    client_name text;
    driver_name text;
    message text;
BEGIN
    -- Only trigger when job is completed
    IF OLD.job_closed_time IS NULL AND NEW.job_closed_time IS NOT NULL THEN
        -- Get client and driver names
        SELECT c.company_name, p.display_name 
        INTO client_name, driver_name
        FROM jobs j
        LEFT JOIN clients c ON j.client_id = c.id
        LEFT JOIN profiles p ON j.driver_id = p.id
        WHERE j.id = NEW.job_id;
        
        message := format('Driver %s completed job for client %s', driver_name, client_name);
        
        PERFORM create_job_notification(NEW.job_id, 'job_completed', message);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_notify_job_completed ON driver_flow;
CREATE TRIGGER trigger_notify_job_completed
    AFTER UPDATE ON driver_flow
    FOR EACH ROW
    EXECUTE FUNCTION notify_job_completed();

-- 10. Function to check for stalled jobs and notify
CREATE OR REPLACE FUNCTION check_stalled_jobs()
RETURNS void AS $$
DECLARE
    stalled_job RECORD;
    client_name text;
    driver_name text;
    message text;
BEGIN
    -- Find jobs that haven't had activity in the last 2 hours
    FOR stalled_job IN 
        SELECT 
            j.id as job_id,
            c.company_name,
            p.display_name as driver_name,
            df.last_activity_at,
            df.current_step
        FROM jobs j
        LEFT JOIN driver_flow df ON j.id = df.job_id
        LEFT JOIN clients c ON j.client_id = c.id
        LEFT JOIN profiles p ON j.driver_id = p.id
        WHERE j.job_status IN ('started', 'in_progress', 'ready_to_close')
        AND df.last_activity_at < NOW() - INTERVAL '2 hours'
        AND df.last_activity_at > NOW() - INTERVAL '24 hours' -- Only recent jobs
    LOOP
        message := format('Job for client %s by driver %s appears stalled at step: %s', 
                         stalled_job.company_name, stalled_job.driver_name, stalled_job.current_step);
        
        PERFORM create_job_notification(stalled_job.job_id, 'job_stalled', message);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 11. View for unread notifications
CREATE OR REPLACE VIEW unread_notifications AS
SELECT
    n.id,
    n.user_id,
    n.message,
    n.notification_type,
    n.job_id,
    n.created_at,
    p.display_name as user_name,
    p.role as user_role
FROM notifications n
LEFT JOIN profiles p ON n.user_id = p.id
WHERE n.read_at IS NULL 
AND n.dismissed_at IS NULL
ORDER BY n.created_at DESC;

-- 12. Function to get notifications for a specific user
CREATE OR REPLACE FUNCTION get_user_notifications(user_uuid uuid, limit_count integer DEFAULT 50)
RETURNS TABLE (
    id uuid,
    body text,
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
        n.body,
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
$$ LANGUAGE plpgsql;
