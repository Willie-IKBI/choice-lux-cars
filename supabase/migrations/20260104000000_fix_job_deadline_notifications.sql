-- Migration: Fix Job Start Deadline Notifications
-- Date: 2026-01-04
-- Purpose: 
--   1. Change admin threshold from T-30 to T-60 (55-60 minutes window)
--   2. Add manager_id to RPC return type for proper manager scoping
--   3. Update notification_type from 30min to 60min

BEGIN;

-- Drop and recreate function with updated thresholds and manager_id
DROP FUNCTION IF EXISTS public.get_jobs_needing_start_deadline_notifications(timestamp with time zone);

CREATE OR REPLACE FUNCTION public.get_jobs_needing_start_deadline_notifications(
  p_current_time timestamp with time zone
)
RETURNS TABLE (
  job_id bigint,
  job_number text,
  driver_name text,
  manager_id uuid,
  pickup_date timestamp without time zone,
  minutes_before integer,
  notification_type text,
  recipient_role text
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sa_offset interval := '2 hours'; -- SA time is UTC+2
  v_current_sa_time timestamp with time zone;
BEGIN
  -- Convert current time to SA timezone for comparison
  v_current_sa_time := p_current_time + v_sa_offset;

  RETURN QUERY
  WITH job_earliest_pickup AS (
    -- Get earliest pickup_date per job
    SELECT 
      t.job_id,
      MIN(t.pickup_date) as earliest_pickup_date
    FROM public.transport t
    WHERE t.pickup_date IS NOT NULL
    GROUP BY t.job_id
  ),
  jobs_with_driver AS (
    -- Get jobs with driver assigned and not started
    SELECT 
      j.id as job_id,
      j.job_number,
      j.driver_id,
      j.manager_id,
      j.job_status,
      p.display_name as driver_name,
      jep.earliest_pickup_date,
      df.job_started_at
    FROM public.jobs j
    INNER JOIN job_earliest_pickup jep ON j.id = jep.job_id
    LEFT JOIN public.profiles p ON j.driver_id = p.id
    LEFT JOIN public.driver_flow df ON j.id = df.job_id
    WHERE 
      j.driver_id IS NOT NULL
      AND (df.job_started_at IS NULL)  -- Job hasn't started
      AND j.job_status NOT IN ('cancelled', 'completed', 'declined')  -- Filter by status
  )
  SELECT 
    jwd.job_id,
    jwd.job_number,
    COALESCE(jwd.driver_name, 'Unknown') as driver_name,
    jwd.manager_id,
    jwd.earliest_pickup_date as pickup_date,
    CASE 
      -- Check if we're within 90 minutes before pickup window (manager notification)
      -- Window: 90-85 minutes before pickup (5-minute window for cron checks)
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '90 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '85 minutes'
      THEN 90
      -- Check if we're within 60 minutes before pickup window (administrator notification)
      -- Window: 60-55 minutes before pickup (5-minute window for cron checks)
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '60 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '55 minutes'
      THEN 60
      ELSE NULL
    END as minutes_before,
    CASE 
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '90 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '85 minutes'
      THEN 'job_start_deadline_warning_90min'
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '60 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '55 minutes'
      THEN 'job_start_deadline_warning_60min'
      ELSE NULL
    END as notification_type,
    CASE 
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '90 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '85 minutes'
      THEN 'manager'
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '60 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '55 minutes'
      THEN 'administrator'
      ELSE NULL
    END as recipient_role
  FROM jobs_with_driver jwd
  WHERE 
    -- Only return jobs that need notification (within 90min or 60min window)
    (
      (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '90 minutes'
      AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '85 minutes'
    )
    OR
    (
      (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '60 minutes'
      AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '55 minutes'
    )
  ORDER BY jwd.earliest_pickup_date ASC;
END;
$$;

-- Set function owner
ALTER FUNCTION public.get_jobs_needing_start_deadline_notifications(timestamp with time zone) OWNER TO postgres;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION public.get_jobs_needing_start_deadline_notifications(timestamp with time zone) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_jobs_needing_start_deadline_notifications(timestamp with time zone) TO service_role;

-- Update comment
COMMENT ON FUNCTION public.get_jobs_needing_start_deadline_notifications(timestamp with time zone) IS 
'Finds jobs needing start deadline notifications. Returns jobs where driver has not started job and we are 90 minutes before pickup (manager) or 60 minutes before pickup (administrator/super_admin). Includes manager_id for proper recipient scoping.';

COMMIT;

