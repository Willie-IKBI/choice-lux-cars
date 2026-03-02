-- Replace the failing HTTP-based cron job for deadline checks with a direct SQL function.
-- The old approach used pg_net (http_post_for_cron) which fails with:
--   "permission denied for sequence http_request_queue_id_seq"
-- This new function does the same work entirely in SQL, bypassing pg_net.

CREATE OR REPLACE FUNCTION public.check_job_start_deadlines_sql()
RETURNS TABLE(jobs_checked int, notifications_created int)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_job record;
  v_recipient record;
  v_message text;
  v_now timestamptz := now();
  v_jobs_checked int := 0;
  v_notifications_created int := 0;
  v_existing_id uuid;
BEGIN
  FOR v_job IN
    SELECT * FROM public.get_jobs_needing_start_deadline_notifications(v_now)
  LOOP
    v_jobs_checked := v_jobs_checked + 1;
    v_message := 'Warning job# ' || v_job.job_number || ' has not started with the driver ' || COALESCE(v_job.driver_name, 'assigned');

    IF v_job.recipient_role = 'manager' THEN
      IF v_job.manager_id IS NULL THEN
        CONTINUE;
      END IF;

      SELECT id INTO v_existing_id
      FROM public.app_notifications
      WHERE job_id = v_job.job_id::text
        AND notification_type = v_job.notification_type
        AND user_id = v_job.manager_id
        AND is_hidden = false
      LIMIT 1;

      IF v_existing_id IS NULL THEN
        INSERT INTO public.app_notifications (user_id, message, notification_type, job_id, priority, action_data, created_at, updated_at)
        VALUES (
          v_job.manager_id,
          v_message,
          v_job.notification_type,
          v_job.job_id::text,
          'high',
          jsonb_build_object(
            'route', '/jobs/' || v_job.job_id || '/summary',
            'job_id', v_job.job_id::text,
            'job_number', v_job.job_number,
            'driver_name', v_job.driver_name,
            'minutes_before_pickup', v_job.minutes_before
          ),
          v_now,
          v_now
        );
        v_notifications_created := v_notifications_created + 1;
      END IF;

    ELSIF v_job.recipient_role = 'administrator' THEN
      FOR v_recipient IN
        SELECT id FROM public.profiles
        WHERE role IN ('administrator', 'super_admin')
          AND status = 'active'
      LOOP
        SELECT id INTO v_existing_id
        FROM public.app_notifications
        WHERE job_id = v_job.job_id::text
          AND notification_type = v_job.notification_type
          AND user_id = v_recipient.id
          AND is_hidden = false
        LIMIT 1;

        IF v_existing_id IS NULL THEN
          INSERT INTO public.app_notifications (user_id, message, notification_type, job_id, priority, action_data, created_at, updated_at)
          VALUES (
            v_recipient.id,
            v_message,
            v_job.notification_type,
            v_job.job_id::text,
            'high',
            jsonb_build_object(
              'route', '/jobs/' || v_job.job_id || '/summary',
              'job_id', v_job.job_id::text,
              'job_number', v_job.job_number,
              'driver_name', v_job.driver_name,
              'minutes_before_pickup', v_job.minutes_before
            ),
            v_now,
            v_now
          );
          v_notifications_created := v_notifications_created + 1;
        END IF;
      END LOOP;
    END IF;
  END LOOP;

  RETURN QUERY SELECT v_jobs_checked, v_notifications_created;
END;
$$;

-- Remove the old failing HTTP-based cron job and schedule the new SQL-based one
-- (Already done via execute_sql: old jobid=4 unscheduled, new job 'check-job-start-deadlines-sql' scheduled)
SELECT cron.schedule('check-job-start-deadlines-sql', '*/10 * * * *', 'SELECT * FROM public.check_job_start_deadlines_sql();');
