-- One-off script: Set job 1625 so the next step in the app is "Arrive at Dropoff".
-- Run in Supabase SQL Editor (or psql) with a role that can write to driver_flow and trip_progress
-- (e.g. service_role or dashboard). Only job 1625 and its driver_flow/trip_progress rows are touched.
--
-- Result: Driver opens job 1625 → progress shows through "Passenger Onboard" completed →
-- "Arrive at Dropoff" is the current actionable step (button visible; GPS captured when tapped).

DO $$
DECLARE
  v_driver_id uuid;
  v_updated int;
BEGIN
  SELECT driver_id INTO v_driver_id FROM public.jobs WHERE id = 1625;
  IF v_driver_id IS NULL THEN
    RAISE NOTICE 'Job 1625 not found or has no driver_id. Assign a driver to the job and re-run.';
    RETURN;
  END IF;

  -- Ensure job is started
  UPDATE public.jobs
  SET job_status = 'started', updated_at = now()
  WHERE id = 1625 AND (job_status IS NULL OR job_status NOT IN ('started', 'in_progress'));

  -- driver_flow: set current_step = passenger_onboard, prior steps completed, dropoff/trip_complete null
  UPDATE public.driver_flow SET
    current_step = 'passenger_onboard',
    vehicle_collected = true,
    vehicle_collected_at = COALESCE(vehicle_collected_at, now() - interval '45 minutes'),
    job_started_at = COALESCE(job_started_at, now() - interval '45 minutes'),
    progress_percentage = 50,
    pickup_arrive_time = COALESCE(pickup_arrive_time, now() - interval '30 minutes'),
    pickup_arrive_loc = COALESCE(pickup_arrive_loc, 'GPS: -33.9249, 18.4241'),
    passenger_onboard_at = COALESCE(passenger_onboard_at, now() - interval '15 minutes'),
    dropoff_arrive_at = NULL,
    trip_complete_at = NULL,
    driver_user = v_driver_id,
    last_activity_at = now(),
    updated_at = now()
  WHERE job_id = 1625;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    INSERT INTO public.driver_flow (
      job_id, driver_user, current_step, vehicle_collected, vehicle_collected_at,
      job_started_at, progress_percentage, pickup_arrive_time, pickup_arrive_loc,
      passenger_onboard_at, dropoff_arrive_at, trip_complete_at, last_activity_at, updated_at
    )
    VALUES (
      1625, v_driver_id, 'passenger_onboard', true, now() - interval '45 minutes',
      now() - interval '45 minutes', 50, now() - interval '30 minutes', 'GPS: -33.9249, 18.4241',
      now() - interval '15 minutes', NULL, NULL, now(), now()
    );
  END IF;

  -- trip_progress: first trip has pickup set, dropoff null, status not completed
  -- Allowed statuses: pending, pickup_arrived, passenger_onboard, dropoff_arrived, completed
  UPDATE public.trip_progress SET
    status = 'passenger_onboard',
    pickup_gps_lat = COALESCE(pickup_gps_lat, -33.9249),
    pickup_gps_lng = COALESCE(pickup_gps_lng, 18.4241),
    pickup_arrived_at = COALESCE(pickup_arrived_at, now() - interval '30 minutes'),
    dropoff_gps_lat = NULL,
    dropoff_gps_lng = NULL,
    dropoff_arrived_at = NULL,
    completed_at = NULL,
    updated_at = now()
  WHERE job_id = 1625 AND trip_index = 1;

  GET DIAGNOSTICS v_updated = ROW_COUNT;
  IF v_updated = 0 THEN
    INSERT INTO public.trip_progress (
      job_id, trip_index, status, pickup_gps_lat, pickup_gps_lng, pickup_arrived_at,
      dropoff_gps_lat, dropoff_gps_lng, dropoff_arrived_at, updated_at
    )
    VALUES (
      1625, 1, 'passenger_onboard', -33.9249, 18.4241, now() - interval '30 minutes',
      NULL, NULL, NULL, now()
    );
  END IF;

  RAISE NOTICE 'Job 1625 set to dropoff step: driver_flow.current_step=passenger_onboard; trip 1 ready for Arrive at Dropoff.';
END $$;
