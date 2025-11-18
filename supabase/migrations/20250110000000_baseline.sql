

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "app_auth";


ALTER SCHEMA "app_auth" OWNER TO "postgres";

CREATE SCHEMA IF NOT EXISTS "net";


CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA "pg_catalog";






CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA "net";






CREATE EXTENSION IF NOT EXISTS "pgsodium";






COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgjwt" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."job_status_enum" AS ENUM (
    'pending',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."job_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."notification_type_enum" AS ENUM (
    'job_assignment',
    'job_started',
    'passenger_onboard',
    'job_completed',
    'job_stalled',
    'driver_inactive'
);


ALTER TYPE "public"."notification_type_enum" OWNER TO "postgres";


CREATE TYPE "public"."quote_status_enum" AS ENUM (
    'draft',
    'sent',
    'accepted',
    'declined',
    'closed'
);


ALTER TYPE "public"."quote_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."transport_status_enum" AS ENUM (
    'pending',
    'in_transit',
    'completed',
    'cancelled'
);


ALTER TYPE "public"."transport_status_enum" OWNER TO "postgres";


CREATE TYPE "public"."user_role_enum" AS ENUM (
    'administrator',
    'manager',
    'driver_manager',
    'driver',
    'suspended'
);


ALTER TYPE "public"."user_role_enum" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "app_auth"."create_user_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- insert into the real profiles table
  INSERT INTO public.profiles (id, user_email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$$;


ALTER FUNCTION "app_auth"."create_user_profile"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."arrive_at_dropoff"("job_id" bigint, "trip_index" integer, "gps_lat" numeric, "gps_lng" numeric, "gps_accuracy" numeric) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    driver_id_val UUID;
BEGIN
    -- Get the driver_id from the jobs table
    SELECT j.driver_id INTO driver_id_val
    FROM jobs j
    WHERE j.id = arrive_at_dropoff.job_id;
    
    -- Update driver_flow table to move to next step
    UPDATE driver_flow df
    SET 
        current_step = 'trip_complete',
        last_activity_at = NOW(),
        updated_at = NOW()
    WHERE df.job_id = arrive_at_dropoff.job_id;
    
    -- Log the action
    RAISE NOTICE 'Driver % arrived at dropoff for job % trip % at %', 
        driver_id_val, arrive_at_dropoff.job_id, arrive_at_dropoff.trip_index, NOW();
END;
$$;


ALTER FUNCTION "public"."arrive_at_dropoff"("job_id" bigint, "trip_index" integer, "gps_lat" numeric, "gps_lng" numeric, "gps_accuracy" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."block_notifications_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  dummy_row notifications;
begin
  dummy_row.id := gen_random_uuid();
  dummy_row.user_id := new.user_id;
  dummy_row.created_at := now();
  dummy_row.body := 'Notifications suppressed';
  return dummy_row;
end;
$$;


ALTER FUNCTION "public"."block_notifications_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."calculate_job_progress"("job_id_param" bigint) RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
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
$$;


ALTER FUNCTION "public"."calculate_job_progress"("job_id_param" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."clean_text"("input_text" "text") RETURNS "text"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  RETURN regexp_replace(
    regexp_replace(
      regexp_replace(
        regexp_replace(
          regexp_replace(
            regexp_replace(
              regexp_replace(
                regexp_replace(
                  regexp_replace(
                    regexp_replace(
                      coalesce(input_text, ''),
                      '[\u2010-\u2015]', '-', 'g'),  -- All dash variants
                      '[\u2018\u2019]', '''', 'g'),   -- Smart quotes
                      '[\u201C\u201D]', '"', 'g'),    -- Smart double quotes
                      '[\u2026]', '...', 'g'),        -- Ellipsis
                      '[\u00A0]', ' ', 'g'),          -- Non-breaking space
                      '[\u2000-\u200F]', ' ', 'g'),   -- Various spaces
                      '[\u2028\u2029]', ' ', 'g'),    -- Line/paragraph separators
                      '[\uFEFF]', '', 'g'),           -- Zero-width no-break space
                      '[\u00AD]', '', 'g'),           -- Soft hyphen
                      '[\u200B-\u200D\uFEFF]', '', 'g'); -- Zero-width characters
END;
$$;


ALTER FUNCTION "public"."clean_text"("input_text" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."cleanup_expired_notifications"() RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE public.app_notifications
  SET 
    is_hidden = true,
    dismissed_at = NOW(),
    updated_at = NOW()
  WHERE expires_at IS NOT NULL 
    AND expires_at < NOW() 
    AND is_hidden = false;
END;
$$;


ALTER FUNCTION "public"."cleanup_expired_notifications"() OWNER TO "postgres";


COMMENT ON FUNCTION "public"."cleanup_expired_notifications"() IS 'Hides expired notifications';



CREATE OR REPLACE FUNCTION "public"."close_job"("job_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Update jobs table status
    UPDATE jobs 
    SET job_status = 'completed'
    WHERE id = close_job.job_id;
    
    -- Update driver_flow
    UPDATE driver_flow 
    SET 
        job_closed_time = NOW(),
        last_activity_at = NOW()
    WHERE driver_flow.job_id = close_job.job_id;
    
    -- Log the action (NO NOTIFICATIONS)
    RAISE NOTICE 'Job % closed', job_id;
END;
$$;


ALTER FUNCTION "public"."close_job"("job_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."complete_trip"("job_id" bigint, "trip_index" integer, "notes" "text" DEFAULT NULL::"text") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."complete_trip"("job_id" bigint, "trip_index" integer, "notes" "text") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."complete_trip"("job_id" bigint, "trip_index" integer, "notes" "text") IS 'Records trip completion with optional notes and South African timestamp';



CREATE OR REPLACE FUNCTION "public"."copy_quote_transport_to_job"("source_quote_id" bigint, "target_job_id" bigint) RETURNS "void"
    LANGUAGE "sql"
    AS $$
insert into transport (
  job_id,
  pickup_date,
  pickup_location,
  dropoff_location,
  amount,
  notes
)
select
  target_job_id,
  pickup_date,
  pickup_location,
  dropoff_location,
  amount,
  notes
from quotes_transport_details
where quote_id = source_quote_id;
$$;


ALTER FUNCTION "public"."copy_quote_transport_to_job"("source_quote_id" bigint, "target_job_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_user_profile"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  INSERT INTO public.profile(id, display_name, user_email)
  VALUES (NEW.id, 'Add User Name', New.email);
  RETURN NEW;
END;$$;


ALTER FUNCTION "public"."create_user_profile"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_user_role"() RETURNS "public"."user_role_enum"
    LANGUAGE "plpgsql" STABLE
    AS $$
DECLARE
  r public.user_role_enum;
BEGIN
  SELECT role
    INTO r
    FROM public.profiles
   WHERE id = auth.uid();
  RETURN r;
END;
$$;


ALTER FUNCTION "public"."current_user_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."ensure_driver_flow_record"("p_job_id" bigint, "p_driver_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    INSERT INTO driver_flow (job_id, driver_user, current_step, current_trip_index, progress_percentage)
    VALUES (p_job_id, p_driver_id, 'vehicle_collection', 1, 0)
    ON CONFLICT (job_id) DO NOTHING;
END;
$$;


ALTER FUNCTION "public"."ensure_driver_flow_record"("p_job_id" bigint, "p_driver_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_driver_current_job"("driver_uuid" "uuid") RETURNS TABLE("job_id" bigint, "current_step" "text", "progress_percentage" integer, "last_activity_at" timestamp with time zone, "total_trips" integer, "completed_trips" integer)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."get_driver_current_job"("driver_uuid" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_invoice_data_for_job"("p_job_id" bigint) RETURNS "jsonb"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE
  result jsonb;
  job_record record;
  transport_data jsonb;
  banking_details jsonb;
BEGIN
  -- Check if user has access to this job
  IF NOT EXISTS (
    SELECT 1 FROM jobs j
    JOIN clients c ON j.client_id = c.id
    WHERE j.id = p_job_id
    AND c.status = 'active'
  ) THEN
    RAISE EXCEPTION 'Access denied: Job not found or client inactive';
  END IF;

  -- Return the complete invoice data with ALL client fields
  RETURN (
    SELECT
      jsonb_build_object(
        -- job fields
        'job_id', j.id,
        'quote_no', j.quote_no,
        'quote_date', to_char(j.order_date, 'YYYY-MM-DD'),
        'company_name', coalesce(c.company_name, 'Choice Lux Cars'),
        'company_logo', c.company_logo,
        'client_contact_person', coalesce(c.contact_person, ''),
        'client_contact_number', coalesce(c.contact_number, ''),
        'client_contact_email', coalesce(c.contact_email, ''),
        'client_billing_address', coalesce(c.billing_address, ''),
        'client_company_registration', coalesce(c.company_registration_number, ''), -- ADDED
        'client_vat_number', coalesce(c.vat_number, ''), -- ADDED
        'client_website', coalesce(c.website_address, ''), -- ADDED
        'agent_name', coalesce(a.agent_name, 'Not available'),
        'agent_contact', coalesce(a.contact_number, 'Not available'),
        'agent_email', coalesce(a.contact_email, ''),
        'passenger_name', coalesce(j.passenger_name, 'Not specified'),
        'passenger_contact', coalesce(j.passenger_contact, 'Not specified'),
        'number_passengers', coalesce(j.pax, 0),
        'luggage', coalesce(j.number_bags, 'Not specified'),
        'driver_name', coalesce(p.display_name, 'Not assigned'),
        'driver_contact', coalesce(p.number, 'Not available'),
        'vehicle_type', coalesce(concat(v.make, ' ', v.model), 'Not assigned'),
        'notes', coalesce(j.notes, ''),
        'total_amount', coalesce(j.amount, 0),
        'tax_amount', coalesce(j.amount * 0.15, 0),
        'subtotal', coalesce(j.amount * 0.85, 0),

        -- transport details with FIXED character cleaning
        'transport', (
          SELECT coalesce(
            jsonb_agg(
              jsonb_build_object(
                'date', t.pickup_date,
                'time', to_char(t.pickup_date, 'HH24:MI'),
                'pickup_location', replace(replace(coalesce(t.pickup_location, ''), chr(8211), '-'), chr(8212), '-'),
                'dropoff_location', replace(replace(coalesce(t.dropoff_location, ''), chr(8211), '-'), chr(8212), '-')
              )
              ORDER BY t.pickup_date ASC
            ),
            '[]'::jsonb
          )
          FROM public.transport t
          WHERE t.job_id = j.id
        ),

        -- invoice specific fields with NEW PAYMENT TERMS
        'invoice_number', 'INV-' || j.id,
        'invoice_date', to_char(CURRENT_DATE, 'YYYY-MM-DD'),
        'due_date', to_char(CURRENT_DATE, 'YYYY-MM-DD'),
        'currency', 'ZAR',
        'payment_terms', 'Payment must be made on receipt of invoice. No service delivery without payment.',
        'banking_details', jsonb_build_object(
          'bank_name', 'ABSA Bank',
          'account_name', 'CHOICELUX CARS (PTY) LTD',
          'account_number', '411 511 5471',
          'branch_code', '632005',
          'swift_code', 'SBZAZAJJ',
          'reference', 'INV-' || j.id
        )
      )
    FROM public.jobs j
    LEFT JOIN public.clients c ON c.id = j.client_id
    LEFT JOIN public.agents a ON a.id = j.agent_id
    LEFT JOIN public.profiles p ON p.id = j.driver_id
    LEFT JOIN public.vehicles v ON v.id = j.vehicle_id
    WHERE j.id = p_job_id
  );
END;$$;


ALTER FUNCTION "public"."get_invoice_data_for_job"("p_job_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_invoice_data_for_pdf"("p_job_id" bigint) RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  result jsonb;
BEGIN
  -- Access check
  IF NOT EXISTS (
    SELECT 1
    FROM public.jobs j
    JOIN public.clients c ON j.client_id = c.id
    WHERE j.id = p_job_id
      AND c.status = 'active'
  ) THEN
    RAISE EXCEPTION 'Access denied: Job not found or client inactive';
  END IF;

  RETURN (
    SELECT
      jsonb_build_object(
        -- ids/counts → int
        'job_id',                (j.id)::int,
        'quote_no',              COALESCE(j.quote_no::text, ''),
        'number_passengers',     COALESCE(j.pax, 0)::int,

        -- money → numeric (explicit)
        'total_amount',          COALESCE((j.amount)::numeric, 0)::numeric,
        'tax_amount',            COALESCE((j.amount)::numeric * 0.15, 0)::numeric,
        'subtotal',              COALESCE((j.amount)::numeric * 0.85, 0)::numeric,

        -- strings/dates
        'quote_date',            to_char(j.order_date, 'YYYY-MM-DD'),
        'company_name',          COALESCE(c.company_name, 'Choice Lux Cars'),
        'company_logo',          c.company_logo,
        'client_contact_person', COALESCE(c.contact_person, ''),
        'client_contact_number', COALESCE(c.contact_number, ''),
        'client_contact_email',  COALESCE(c.contact_email, ''),
        'agent_name',            COALESCE(a.agent_name, 'Not available'),
        'agent_contact',         COALESCE(a.contact_number, 'Not available'),
        'agent_email',           COALESCE(a.contact_email, ''),
        'passenger_name',        COALESCE(j.passenger_name, 'Not specified'),
        'passenger_contact',     COALESCE(j.passenger_contact, 'Not specified'),
        'luggage',               COALESCE(j.number_bags, 'Not specified'),
        'driver_name',           COALESCE(p.display_name, 'Not assigned'),
        'driver_contact',        COALESCE(p.number, 'Not available'),
        'vehicle_type',          COALESCE(concat(v.make, ' ', v.model), 'Not assigned'),
        'notes',                 COALESCE(j.notes, ''),

        -- transport
        'transport', (
          SELECT COALESCE(
            jsonb_agg(
              jsonb_build_object(
                'date',             t.pickup_date,
                'time',             to_char(t.pickup_date, 'HH24:MI'),
                'pickup_location',  replace(replace(COALESCE(t.pickup_location, ''), chr(8211), '-'), chr(8212), '-'),
                'dropoff_location', replace(replace(COALESCE(t.dropoff_location, ''), chr(8211), '-'), chr(8212), '-')
              )
              ORDER BY t.pickup_date ASC
            ),
            '[]'::jsonb
          )
          FROM public.transport t
          WHERE t.job_id = j.id
        ),

        -- invoice meta
        'invoice_number', 'INV-' || j.id,
        'invoice_date',   to_char(CURRENT_DATE, 'YYYY-MM-DD'),
        'due_date',       to_char(CURRENT_DATE, 'YYYY-MM-DD'),
        'currency',       'ZAR',
        'payment_terms',  'Payment must be made on receipt of invoice. No service delivery without payment.',
        'banking_details', jsonb_build_object(
          'bank_name',      'Standard Bank',
          'account_name',   'Choice Lux Cars (Pty) Ltd',
          'account_number', '1234567890',
          'branch_code',    '051001',
          'swift_code',     'SBZAZAJJ',
          'reference',      'INV-' || j.id
        )
      )::json
    FROM public.jobs j
    LEFT JOIN public.clients  c ON c.id = j.client_id
    LEFT JOIN public.agents   a ON a.id = j.agent_id
    LEFT JOIN public.profiles p ON p.id = j.driver_id
    LEFT JOIN public.vehicles v ON v.id = j.vehicle_id
    WHERE j.id = p_job_id
  );
END;
$$;


ALTER FUNCTION "public"."get_invoice_data_for_pdf"("p_job_id" bigint) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_invoice_data_for_pdf"("p_job_id" bigint) IS 'Fetches complete invoice data for PDF generation with proper character cleaning and all required fields';



CREATE OR REPLACE FUNCTION "public"."get_job_progress"("job_id_param" bigint) RETURNS TABLE("job_id" bigint, "current_step" "text", "progress_percentage" integer, "total_trips" integer, "completed_trips" integer, "current_trip_index" integer, "job_status" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        jps.job_id,
        jps.current_step,
        jps.progress_percentage,
        jps.total_trips,
        jps.completed_trips,
        jps.current_trip_index,
        j.job_status::text
    FROM job_progress_summary jps
    JOIN jobs j ON jps.job_id = j.id
    WHERE jps.job_id = job_id_param;
END;
$$;


ALTER FUNCTION "public"."get_job_progress"("job_id_param" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_jobs_needing_start_deadline_notifications"("p_current_time" timestamp with time zone) RETURNS TABLE("job_id" bigint, "job_number" "text", "driver_name" "text", "pickup_date" timestamp without time zone, "minutes_before" integer, "notification_type" "text", "recipient_role" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
DECLARE
  v_sa_offset interval := '2 hours'; -- SA time is UTC+2
  v_current_sa_time timestamp with time zone;
  v_pickup_as_tz timestamp with time zone;
  v_minutes_until_pickup interval;
BEGIN
  -- Convert current time to SA timezone for comparison
  -- p_current_time is already in UTC, add 2 hours to get SA time
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
      AND j.job_status NOT IN ('cancelled', 'completed')  -- Filter by status
  )
  SELECT 
    jwd.job_id,
    jwd.job_number,
    COALESCE(jwd.driver_name, 'Unknown') as driver_name,
    jwd.earliest_pickup_date as pickup_date,
    CASE 
      -- Check if we're within 90 minutes before pickup window (manager notification)
      -- Window: 90-85 minutes before pickup (5-minute window for cron checks)
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '90 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '85 minutes'
      THEN 90
      -- Check if we're within 30 minutes before pickup window (administrator notification)
      -- Window: 30-25 minutes before pickup (5-minute window for cron checks)
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '30 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '25 minutes'
      THEN 30
      ELSE NULL
    END as minutes_before,
    CASE 
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '90 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '85 minutes'
      THEN 'job_start_deadline_warning_90min'
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '30 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '25 minutes'
      THEN 'job_start_deadline_warning_30min'
      ELSE NULL
    END as notification_type,
    CASE 
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '90 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '85 minutes'
      THEN 'manager'
      WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '30 minutes'
           AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '25 minutes'
      THEN 'administrator'
      ELSE NULL
    END as recipient_role
  FROM jobs_with_driver jwd
  WHERE 
    -- Only return jobs that need notification (within 90min or 30min window)
    (
      (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '90 minutes'
      AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '85 minutes'
    )
    OR
    (
      (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '30 minutes'
      AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '25 minutes'
    )
  ORDER BY jwd.earliest_pickup_date ASC;
END;
$$;


ALTER FUNCTION "public"."get_jobs_needing_start_deadline_notifications"("p_current_time" timestamp with time zone) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_jobs_needing_start_deadline_notifications"("p_current_time" timestamp with time zone) IS 'Finds jobs needing start deadline notifications. Returns jobs where driver has not started job and we are 90 minutes before pickup (manager) or 30 minutes before pickup (administrator).';



CREATE OR REPLACE FUNCTION "public"."get_notification_stats"("user_uuid" "uuid") RETURNS "jsonb"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
  result JSONB;
BEGIN
  SELECT jsonb_build_object(
    'total_count', COUNT(*),
    'unread_count', COUNT(*) FILTER (WHERE is_read = false AND is_hidden = false),
    'read_count', COUNT(*) FILTER (WHERE is_read = true),
    'dismissed_count', COUNT(*) FILTER (WHERE is_hidden = true),
    'by_type', (
      SELECT jsonb_object_agg(notification_type, type_count)
      FROM (
        SELECT notification_type, COUNT(*) as type_count
        FROM public.app_notifications
        WHERE user_id = user_uuid
        GROUP BY notification_type
      ) type_stats
    )
  ) INTO result
  FROM public.app_notifications
  WHERE user_id = user_uuid;
  
  RETURN COALESCE(result, '{}'::jsonb);
END;
$$;


ALTER FUNCTION "public"."get_notification_stats"("user_uuid" "uuid") OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_notification_stats"("user_uuid" "uuid") IS 'Returns notification statistics for a user';



CREATE OR REPLACE FUNCTION "public"."get_quote_data_for_pdf"("p_quote_id" bigint) RETURNS "jsonb"
    LANGUAGE "sql" STABLE
    AS $$
SELECT
  jsonb_build_object(
    -- top‐level quote fields
    'quote_no',            q.id,
    'quote_date',          to_char(q.quote_date,  'YYYY-MM-DD'),
    'quote_title',         coalesce(q.quote_title,       ''),
    'quote_description',   coalesce(q.quote_description,     ''),
    'passenger_name',      coalesce(q.passenger_name,      ''),
    'passenger_contact',   coalesce(q.passenger_contact,      ''),
    'vehicle_type',        coalesce(q.vehicle_type,      ''),
    'number_passengers',   coalesce(q.pax,               0),
    'luggage',             coalesce(q.luggage,           ''),
    'amount',              coalesce(q.quote_amount,      0),
    'notes',               coalesce(q.notes,             ''),

    -- client & agent
    'company_name',        coalesce(cd.company_name,     ''),
    'agent_name',          coalesce(ad.agent_name,       ''),

    -- trip lines
    'transport_details', (
      SELECT coalesce(
        jsonb_agg(
          jsonb_build_object(
            'pickup_date',      to_char(td.pickup_date, 'DD Mon YYYY'),
            'pickup_time',      to_char(td.pickup_date, 'HH24:MI'),
            'pickup_location',  coalesce(td.pickup_location,  ''),
            'dropoff_location', coalesce(td.dropoff_location, ''),
            'amount',           coalesce(td.amount,           0)
          )
        ),
        '[]'::jsonb
      )
      FROM public.quotes_transport_details td
      WHERE td.quote_id = q.id
    ),

    -- transport total
    'transport_total', (
      SELECT coalesce(sum(td.amount), 0)
      FROM public.quotes_transport_details td
      WHERE td.quote_id = q.id
    )
  )
FROM public.quotes q
LEFT JOIN public.clients cd ON cd.id = q.client_id
LEFT JOIN public.agents  ad ON ad.id = q.agent_id
WHERE q.id = p_quote_id;
$$;


ALTER FUNCTION "public"."get_quote_data_for_pdf"("p_quote_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_trip_progress"("job_id_param" bigint) RETURNS TABLE("trip_index" integer, "status" "text", "pickup_arrived_at" timestamp with time zone, "passenger_onboard_at" timestamp with time zone, "dropoff_arrived_at" timestamp with time zone, "completed_at" timestamp with time zone, "pickup_gps_lat" numeric, "pickup_gps_lng" numeric, "dropoff_gps_lat" numeric, "dropoff_gps_lng" numeric)
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        tp.trip_index,
        tp.status,
        tp.pickup_arrived_at,
        tp.passenger_onboard_at,
        tp.dropoff_arrived_at,
        tp.completed_at,
        tp.pickup_gps_lat,
        tp.pickup_gps_lng,
        tp.dropoff_gps_lat,
        tp.dropoff_gps_lng
    FROM trip_progress tp
    WHERE tp.job_id = job_id_param
    ORDER BY tp.trip_index;
END;
$$;


ALTER FUNCTION "public"."get_trip_progress"("job_id_param" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_voucher_data_for_job"("p_job_id" bigint) RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  -- Check if user has access to this voucher/job
  IF NOT EXISTS (
    SELECT 1 FROM jobs j
    JOIN clients c ON j.client_id = c.id
    WHERE j.id = p_job_id
    AND c.status = 'active'
  ) THEN
    RAISE EXCEPTION 'Access denied: Job not found or client inactive';
  END IF;

  RETURN (
    SELECT
      jsonb_build_object(
        -- job fields only
        'job_id', j.id,
        'job_date', to_char(j.job_start_date, 'YYYY-MM-DD'),
        'job_title', '',
        'job_description', coalesce(j.notes, ''),
        'passenger_name', coalesce(j.passenger_name, ''),
        'passenger_contact', coalesce(j.passenger_contact, ''),
        'vehicle_type', coalesce(concat(v.make, ' ', v.model), ''),
        'number_passangers', coalesce(j.pax, 0),
        'luggage', coalesce(j.number_bags, ''),
        'amount', coalesce(j.amount, 0),
        'notes', coalesce(j.notes, ''),  -- Job notes

        -- client & agent with logo support
        'company_name', coalesce(c.company_name, ''),
        'company_logo', coalesce(c.company_logo, ''),  -- Client logo
        'client_website', coalesce(c.website_address, ''),  -- NEW: Client website
        'client_contact_phone', coalesce(c.contact_number, ''),  -- NEW: Client phone
        'client_contact_email', coalesce(c.contact_email, ''),  -- NEW: Client email
        'client_registration', coalesce(c.company_registration_number, ''),  -- NEW: Client registration
        'client_vat_number', coalesce(c.vat_number, ''),  -- NEW: Client VAT
        'agent_name', coalesce(a.agent_name, ''),
        'agent_contact', coalesce(a.contact_number, ''),  -- Agent contact

        -- driver information - FIXED: Correct column names
        'driver_name', coalesce(p.display_name, 'Not assigned'),  -- Driver name
        'driver_contact', coalesce(p.number, 'Not available'),    -- Driver contact

        -- transport details with character cleaning and trip notes
        'transport_details', (
          SELECT coalesce(
            jsonb_agg(
              jsonb_build_object(
                'pickup_date', t.pickup_date,
                'pickup_time', t.pickup_date,
                'pickup_location', replace(replace(coalesce(t.pickup_location, ''), chr(8211), '-'), chr(8212), '-'),
                'dropoff_location', replace(replace(coalesce(t.dropoff_location, ''), chr(8211), '-'), chr(8212), '-'),
                'amount', coalesce(t.amount, 0),
                'notes', coalesce(t.notes, '')  -- Trip notes
              )
              ORDER BY t.pickup_date ASC
            ),
            '[]'::jsonb
          )
          FROM public.transport t
          WHERE t.job_id = j.id
        ),

        -- transport total
        'transport_total', (
          SELECT coalesce(sum(t.amount), 0)
          FROM public.transport t
          WHERE t.job_id = j.id
        )
      )
    FROM public.jobs j
    LEFT JOIN public.clients c ON c.id = j.client_id
    LEFT JOIN public.agents a ON a.id = j.agent_id
    LEFT JOIN public.vehicles v ON v.id = j.vehicle_id
    LEFT JOIN public.profiles p ON p.id = j.driver_id
    WHERE j.id = p_job_id
  );
END;$$;


ALTER FUNCTION "public"."get_voucher_data_for_job"("p_job_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_voucher_data_for_pdf"("p_voucher_id" integer) RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$DECLARE
  result json;
  job_record record;
  transport_data json;
BEGIN
  -- Check if user has access to this voucher/job
  IF NOT EXISTS (
    SELECT 1 FROM jobs j
    JOIN clients c ON j.client_id = c.id
    WHERE j.id = p_voucher_id
    AND c.status = 'active'
  ) THEN
    RAISE EXCEPTION 'Access denied: Job not found or client inactive';
  END IF;

  -- Return the complete voucher data with proper date formatting
  RETURN (
    SELECT
      jsonb_build_object(
        -- top‐level quote fields
        'job_id',             j.id,
        'quote_no',           q.id,
        'quote_date',         to_char(q.quote_date,  'YYYY-MM-DD'),
        'quote_title',        coalesce(q.quote_title,       ''),
        'quote_description',  coalesce(q.quote_description,     ''),
        'passenger_name',     coalesce(q.passenger_name,      ''),
        'passenger_contact',  coalesce(q.passenger_contact,      ''),
        'vehicle_type',       coalesce(q.vehicle_type,      ''),
        'number_passangers',  coalesce(q.pax,               0),
        'luggage',            coalesce(q.luggage,           ''),
        'amount',             coalesce(q.quote_amount,      0),
        'notes',              coalesce(q.notes,             ''),

        -- client & agent
        'company_name',       coalesce(cd.company_name,     ''),
        'agent_name',         coalesce(ad.agent_name,       ''),

        -- trip lines - MINIMAL FIXES ONLY
        'transport_details', (
          SELECT coalesce(
            jsonb_agg(
              jsonb_build_object(
                'pickup_date',      td.pickup_date,  -- FIXED: Removed to_char formatting
                'pickup_time',      td.pickup_date,  -- FIXED: Removed to_char formatting
                'pickup_location',  coalesce(td.pickup_location,  ''),
                'dropoff_location', coalesce(td.dropoff_location, ''),
                'amount',           coalesce(td.amount,           0)
              )
              ORDER BY td.pickup_date ASC  -- FIXED: Added chronological sorting
            ),
            '[]'::jsonb
          )
          FROM public.quotes_transport_details td
          WHERE td.quote_id = q.id
        ),

        -- transport total
        'transport_total', (
          SELECT coalesce(sum(td.amount), 0)
          FROM public.quotes_transport_details td
          WHERE td.quote_id = q.id
        )
      )
    FROM public.jobs j
    LEFT JOIN public.quotes q ON q.id = j.quote_no
    LEFT JOIN public.clients cd ON cd.id = q.client_id
    LEFT JOIN public.agents  ad ON ad.id = q.agent_id
    WHERE j.id = p_voucher_id
  );
END;$$;


ALTER FUNCTION "public"."get_voucher_data_for_pdf"("p_voucher_id" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."get_voucher_data_for_pdf"("p_voucher_id" integer) IS 'Fetches complete voucher data for PDF generation including driver contact information.';



CREATE OR REPLACE FUNCTION "public"."handle_notifications_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  -- Add your logic here. For example:
  -- If you want to suppress based on some condition:
  IF NEW.user_id IS NULL THEN
    -- mark as suppressed, or log externally
    UPDATE notifications SET suppressed = true WHERE id = NEW.id;
  END IF;

  RETURN NULL;
END;
$$;


ALTER FUNCTION "public"."handle_notifications_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."http_post_for_cron"("p_url" "text", "p_headers" "jsonb" DEFAULT '{}'::"jsonb", "p_body" "jsonb" DEFAULT '{}'::"jsonb", "p_timeout_milliseconds" integer DEFAULT 30000) RETURNS bigint
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public', 'net'
    AS $$
DECLARE
  v_request_id bigint;
BEGIN
  SELECT net.http_post(
    url := p_url,
    headers := p_headers,
    body := p_body,
    timeout_milliseconds := p_timeout_milliseconds
  ) INTO v_request_id;
  
  RETURN v_request_id;
END;
$$;


ALTER FUNCTION "public"."http_post_for_cron"("p_url" "text", "p_headers" "jsonb", "p_body" "jsonb", "p_timeout_milliseconds" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."insert_notification"("_user_id" "uuid", "_body" "text") RETURNS "json"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
declare
  result json;
begin
  if _user_id != auth.uid() then
    raise exception 'unauthorized';
  end if;

  insert into notifications (user_id, body)
  values (_user_id, _body)
  returning row_to_json(notifications.*)
  into result;

  return result;
end;
$$;


ALTER FUNCTION "public"."insert_notification"("_user_id" "uuid", "_body" "text") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."log_notification_created"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  -- Just log the notification creation - NO HTTP CALLS
  RAISE NOTICE 'Notification created: % for user: %', NEW.id, NEW.user_id;
  
  -- Insert into delivery log with pending status
  INSERT INTO public.notification_delivery_log (
    notification_id,
    user_id,
    fcm_token,
    fcm_response,
    sent_at,
    success,
    error_message,
    retry_count
  ) VALUES (
    NEW.id,
    NEW.user_id,
    NULL,
    NULL,
    NULL,
    false,
    'Created - will be sent via Edge Function',
    0
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- If anything fails, just log and continue
    RAISE NOTICE 'Logging failed (non-critical): %', SQLERRM;
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."log_notification_created"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."mark_notifications_as_read"("notification_ids" "uuid"[]) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  UPDATE public.app_notifications
  SET 
    is_read = true,
    read_at = NOW(),
    updated_at = NOW()
  WHERE id = ANY(notification_ids);
END;
$$;


ALTER FUNCTION "public"."mark_notifications_as_read"("notification_ids" "uuid"[]) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."mark_notifications_as_read"("notification_ids" "uuid"[]) IS 'Marks multiple notifications as read';



CREATE OR REPLACE FUNCTION "public"."notify_driver_progress"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  admin_user record;
begin
  -- Job Started
  if new.vehicle_time is not null and old.vehicle_time is null then
    for admin_user in
      select id from profiles where role in ('admin', 'manager', 'driver_manager')
    loop
      insert into notifications (user_id, body)
      values (admin_user.id, 'Driver started job #' || new.job_id);
    end loop;
  end if;

  -- Driver Arrived
  if new.pickup_arrive_time is not null and old.pickup_arrive_time is null then
    for admin_user in
      select id from profiles where role in ('admin', 'manager', 'driver_manager')
    loop
      insert into notifications (user_id, body)
      values (admin_user.id, 'Driver arrived at destination for job #' || new.job_id);
    end loop;
  end if;

  -- Passenger Onboard
  if new.pickup_ind = true and (old.pickup_ind is distinct from true) then
    for admin_user in
      select id from profiles where role in ('admin', 'manager', 'driver_manager')
    loop
      insert into notifications (user_id, body)
      values (admin_user.id, 'Passenger onboard for job #' || new.job_id);
    end loop;
  end if;

  -- Job Completed
  if new.transport_completed_ind = true and (old.transport_completed_ind is distinct from true) then
    for admin_user in
      select id from profiles where role in ('admin', 'manager', 'driver_manager')
    loop
      insert into notifications (user_id, body)
      values (admin_user.id, 'Job #' || new.job_id || ' has been completed.');
    end loop;
  end if;

  return new;
end;
$$;


ALTER FUNCTION "public"."notify_driver_progress"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."passenger_onboard"("job_id" bigint, "trip_index" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
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
$$;


ALTER FUNCTION "public"."passenger_onboard"("job_id" bigint, "trip_index" integer) OWNER TO "postgres";


COMMENT ON FUNCTION "public"."passenger_onboard"("job_id" bigint, "trip_index" integer) IS 'Records passenger onboard with South African timestamp';



CREATE OR REPLACE FUNCTION "public"."resume_job"("job_id" bigint) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
    -- Update last activity
    UPDATE driver_flow 
    SET last_activity_at = NOW()
    WHERE driver_flow.job_id = resume_job.job_id;
    
    -- Log the action (NO NOTIFICATIONS)
    RAISE NOTICE 'Job % resumed', job_id;
END;
$$;


ALTER FUNCTION "public"."resume_job"("job_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."set_updated_at"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."set_updated_at"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."start_job"("job_id" bigint, "odo_start_reading" numeric DEFAULT NULL::numeric, "pdp_start_image" "text" DEFAULT NULL::"text", "gps_lat" numeric DEFAULT NULL::numeric, "gps_lng" numeric DEFAULT NULL::numeric, "gps_accuracy" numeric DEFAULT NULL::numeric) RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    driver_uuid uuid;
BEGIN
    -- Get the driver for this job (fix: qualify job_id with function name)
    SELECT driver_id INTO driver_uuid FROM jobs WHERE id = start_job.job_id;
    
    IF driver_uuid IS NULL THEN
        RAISE EXCEPTION 'No driver assigned to job %', start_job.job_id;
    END IF;
    
    -- Ensure driver_flow record exists (fix: qualify job_id with function name)
    PERFORM ensure_driver_flow_record(start_job.job_id, driver_uuid);
    
    -- Update job status to started (fix: qualify job_id with function name)
    UPDATE jobs 
    SET job_status = 'started'
    WHERE id = start_job.job_id;
    
    -- Update driver_flow with start details (this one was already correct)
    UPDATE driver_flow 
    SET 
        job_started_at = NOW(),
        odo_start_reading = COALESCE(start_job.odo_start_reading, odo_start_reading),
        pdp_start_image = COALESCE(start_job.pdp_start_image, pdp_start_image),
        pickup_loc = CASE 
            WHEN start_job.gps_lat IS NOT NULL AND start_job.gps_lng IS NOT NULL 
            THEN format('POINT(%s %s)', start_job.gps_lng, start_job.gps_lat)
            ELSE pickup_loc 
        END,
        vehicle_collected = true,
        vehicle_collected_at = NOW(),
        current_step = 'pickup_arrival',
        progress_percentage = 20,
        last_activity_at = NOW()
    WHERE job_id = start_job.job_id;
    
    -- Create initial trip_progress record if none exists (fix: qualify job_id with function name)
    INSERT INTO trip_progress (job_id, trip_index, status)
    VALUES (start_job.job_id, 1, 'pending')
    ON CONFLICT (job_id, trip_index) DO NOTHING;
    
END;
$$;


ALTER FUNCTION "public"."start_job"("job_id" bigint, "odo_start_reading" numeric, "pdp_start_image" "text", "gps_lat" numeric, "gps_lng" numeric, "gps_accuracy" numeric) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."suppress_notifications_insert"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
declare
  dummy notifications%rowtype;
begin
  -- Fill dummy with mock values (adjust per your schema)
  dummy.id := gen_random_uuid(); -- replace with actual PK
  dummy.created_at := now();     -- adjust if needed
  dummy.message := 'Notification suppressed'; -- optional
  dummy.user_id := new.user_id;  -- if this field exists
  dummy.role := new.role;        -- if this field exists
  dummy.status := 'suppressed';  -- optional if field exists

  -- Return a fake row to satisfy `return=representation`
  return dummy;
end;
$$;


ALTER FUNCTION "public"."suppress_notifications_insert"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_driver_flow_activity"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.last_activity_at = NOW();
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_driver_flow_activity"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_expired_quotes"() RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$BEGIN
  UPDATE public.quotes -- Use public.quotes if your table is in the public schema
  SET quote_status = 'Expired'
  WHERE
    quote_status = 'Open'
    AND quote_date < (NOW() - INTERVAL '24 hours');
END;$$;


ALTER FUNCTION "public"."update_expired_quotes"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_job_total"("job_to_update" "uuid") RETURNS "void"
    LANGUAGE "plpgsql"
    AS $$
declare
  total_amount numeric;
begin
  -- Sum transport.amount where transport.job_id matches
  select coalesce(sum(amount), 0)
  into total_amount
  from transport
  where job_id = job_to_update;

  -- Update the job's total amount
  update jobs
  set amount = total_amount
  where id = job_to_update;
end;
$$;


ALTER FUNCTION "public"."update_job_total"("job_to_update" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_trip_progress_timestamp"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION "public"."update_trip_progress_timestamp"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."updatelastmessage"() RETURNS "trigger"
    LANGUAGE "plpgsql"
    AS $$
begin
    update chats
    set 
        last_message = new.message_text,
        last_message_time = new.created_at
    where id = new.recipient_id;

    return new;
end;
$$;


ALTER FUNCTION "public"."updatelastmessage"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."upsert_device_token"("p_profile_id" "uuid", "p_token" "text") RETURNS TABLE("profile_id" "uuid", "token" "text", "last_seen" timestamp with time zone)
    LANGUAGE "sql"
    AS $$
  INSERT INTO public.device_tokens (profile_id, token, last_seen)
  VALUES (p_profile_id, p_token, NOW())
  ON CONFLICT (profile_id)
  DO UPDATE
    SET token     = EXCLUDED.token,
        last_seen = EXCLUDED.last_seen
  RETURNING profile_id, token, last_seen;
$$;


ALTER FUNCTION "public"."upsert_device_token"("p_profile_id" "uuid", "p_token" "text") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."vehicles" (
    "id" bigint NOT NULL,
    "make" "text",
    "model" "text",
    "reg_plate" "text",
    "reg_date" "date",
    "fuel_type" "text",
    "vehicle_image" "text",
    "status" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "license_expiry_date" "date"
);


ALTER TABLE "public"."vehicles" OWNER TO "postgres";


COMMENT ON TABLE "public"."vehicles" IS 'Vehicle Descriptions';



ALTER TABLE "public"."vehicles" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."Garage_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."agents" (
    "id" bigint NOT NULL,
    "agent_name" "text",
    "client_key" bigint,
    "contact_number" "text",
    "contact_email" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "is_deleted" boolean DEFAULT false NOT NULL
);


ALTER TABLE "public"."agents" OWNER TO "postgres";


ALTER TABLE "public"."agents" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."agent_details_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."app_notifications" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "message" "text" NOT NULL,
    "notification_type" "text" NOT NULL,
    "priority" "text" DEFAULT 'normal'::"text",
    "job_id" "text",
    "action_data" "jsonb",
    "is_read" boolean DEFAULT false,
    "is_hidden" boolean DEFAULT false,
    "read_at" timestamp with time zone,
    "dismissed_at" timestamp with time zone,
    "expires_at" timestamp with time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "app_notifications_priority_check" CHECK (("priority" = ANY (ARRAY['low'::"text", 'normal'::"text", 'high'::"text", 'urgent'::"text"])))
);

ALTER TABLE ONLY "public"."app_notifications" REPLICA IDENTITY NOTHING;


ALTER TABLE "public"."app_notifications" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."app_version" (
    "id" bigint NOT NULL,
    "version_number" "text",
    "is_mandatory" boolean DEFAULT false,
    "update_url" "text"
);


ALTER TABLE "public"."app_version" OWNER TO "postgres";


ALTER TABLE "public"."app_version" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."app_version_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."clients" (
    "id" bigint NOT NULL,
    "company_name" "text",
    "contact_person" "text",
    "contact_number" "text",
    "contact_email" "text",
    "company_logo" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "status" "text" DEFAULT 'active'::"text" NOT NULL,
    "deleted_at" timestamp with time zone,
    "website_address" "text",
    "company_registration_number" "text",
    "vat_number" "text",
    "billing_address" "text",
    CONSTRAINT "check_status_values" CHECK (("status" = ANY (ARRAY['active'::"text", 'pending'::"text", 'vip'::"text", 'inactive'::"text"]))),
    CONSTRAINT "clients_status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'pending'::"text", 'vip'::"text", 'inactive'::"text"])))
);


ALTER TABLE "public"."clients" OWNER TO "postgres";


COMMENT ON COLUMN "public"."clients"."website_address" IS 'Client company website URL';



COMMENT ON COLUMN "public"."clients"."company_registration_number" IS 'Company registration number (CIPC/Companies House)';



COMMENT ON COLUMN "public"."clients"."vat_number" IS 'VAT registration number';



ALTER TABLE "public"."clients" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."client_details_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."device_tokens" (
    "id" bigint NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "token" "text" NOT NULL,
    "last_seen" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."device_tokens" OWNER TO "postgres";


ALTER TABLE "public"."device_tokens" ALTER COLUMN "id" ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME "public"."device_tokens_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."driver_flow" (
    "id" bigint NOT NULL,
    "job_id" bigint,
    "vehicle_collected" boolean DEFAULT false NOT NULL,
    "vehicle_time" timestamp without time zone,
    "user" "uuid",
    "odo_start_img" "text",
    "odo_start_reading" numeric,
    "pickup_arrive_loc" "text",
    "pickup_arrive_time" timestamp with time zone,
    "pickup_ind" boolean DEFAULT false,
    "payment_collected_ind" boolean DEFAULT false,
    "transport_completed_ind" boolean DEFAULT false,
    "job_closed_odo" numeric,
    "job_closed_odo_img" "text",
    "job_closed_time" timestamp without time zone,
    "current_step" "text" DEFAULT 'vehicle_collection'::"text",
    "current_trip_index" integer DEFAULT 1,
    "progress_percentage" integer DEFAULT 0,
    "last_activity_at" timestamp with time zone,
    "job_started_at" timestamp with time zone,
    "vehicle_collected_at" timestamp with time zone,
    "pdp_start_image" "text",
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "driver_user" "uuid",
    "pickup_loc" "text"
);

ALTER TABLE ONLY "public"."driver_flow" REPLICA IDENTITY NOTHING;


ALTER TABLE "public"."driver_flow" OWNER TO "postgres";


ALTER TABLE "public"."driver_flow" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."driver_flow_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."expenses" (
    "id" bigint NOT NULL,
    "job_id" bigint,
    "expense_description" "text",
    "exp_amount" numeric,
    "exp_date" timestamp with time zone,
    "slip_image" "text",
    "expense_location" "text",
    "user" "text",
    "other_description" "text",
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL
);


ALTER TABLE "public"."expenses" OWNER TO "postgres";


ALTER TABLE "public"."expenses" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."expenses_details_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."invoices" (
    "id" bigint NOT NULL,
    "quote_id" bigint NOT NULL,
    "invoice_number" "text" NOT NULL,
    "invoice_date" "date" DEFAULT CURRENT_DATE,
    "pdf_url" "text",
    "status" "text" DEFAULT 'Pending'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "job_allocated" boolean DEFAULT false
);


ALTER TABLE "public"."invoices" OWNER TO "postgres";


CREATE SEQUENCE IF NOT EXISTS "public"."invoices_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "public"."invoices_id_seq" OWNER TO "postgres";


ALTER SEQUENCE "public"."invoices_id_seq" OWNED BY "public"."invoices"."id";



CREATE TABLE IF NOT EXISTS "public"."job_notification_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "job_id" bigint NOT NULL,
    "driver_id" "uuid" NOT NULL,
    "is_reassignment" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "processed_at" timestamp with time zone,
    "status" "text" DEFAULT 'pending'::"text"
);


ALTER TABLE "public"."job_notification_log" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."jobs" (
    "id" bigint NOT NULL,
    "client_id" bigint,
    "vehicle_id" bigint,
    "driver_id" "uuid",
    "order_date" "date",
    "amount" numeric,
    "amount_collect" boolean DEFAULT false,
    "passenger_name" "text",
    "passenger_contact" "text",
    "agent_id" bigint NOT NULL,
    "job_status" "text" DEFAULT 'assigned'::"text",
    "pax" numeric,
    "location" "text",
    "cancel_reason" "text",
    "driver_confirm_ind" boolean DEFAULT false,
    "job_start_date" "date",
    "number_bags" "text",
    "quote_no" bigint,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "voucher_pdf" "text",
    "notes" "text",
    "created_by" "text",
    "is_confirmed" boolean DEFAULT false,
    "confirmed_at" timestamp with time zone,
    "confirmed_by" "uuid",
    "job_number" "text",
    "invoice_pdf" "text"
);

ALTER TABLE ONLY "public"."jobs" REPLICA IDENTITY NOTHING;


ALTER TABLE "public"."jobs" OWNER TO "postgres";


COMMENT ON COLUMN "public"."jobs"."driver_confirm_ind" IS 'Whether the driver has confirmed receiving the job assignment';



COMMENT ON COLUMN "public"."jobs"."job_start_date" IS 'Scheduled start date of the job for notification expiration calculation';



COMMENT ON COLUMN "public"."jobs"."job_number" IS 'Human-readable job number for display in notifications';



COMMENT ON COLUMN "public"."jobs"."invoice_pdf" IS 'URL to the generated invoice PDF file stored in Supabase Storage';



CREATE TABLE IF NOT EXISTS "public"."login_attempts" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "attempted_at" timestamp with time zone DEFAULT "now"(),
    "ip_address" "text",
    "email" "text",
    "user_agent" "text",
    "success" boolean
);


ALTER TABLE "public"."login_attempts" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."notification_delivery_log" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "notification_id" "uuid" NOT NULL,
    "user_id" "uuid" NOT NULL,
    "fcm_token" "text",
    "fcm_response" "jsonb",
    "sent_at" timestamp with time zone DEFAULT "now"(),
    "success" boolean DEFAULT false,
    "error_message" "text",
    "retry_count" integer DEFAULT 0
);


ALTER TABLE "public"."notification_delivery_log" OWNER TO "postgres";


COMMENT ON TABLE "public"."notification_delivery_log" IS 'Tracks delivery attempts for push notifications';



CREATE TABLE IF NOT EXISTS "public"."notifications_backup" (
    "id" "uuid",
    "user_id" "uuid",
    "created_at" timestamp with time zone,
    "message" "text",
    "suppressed" boolean,
    "job_id" bigint,
    "is_read" boolean,
    "notification_type" character varying(50),
    "updated_at" timestamp with time zone,
    "is_hidden" boolean,
    "dismissed_at" timestamp with time zone,
    "priority" "text",
    "action_data" "jsonb",
    "expires_at" timestamp with time zone,
    "read_at" timestamp with time zone
);


ALTER TABLE "public"."notifications_backup" OWNER TO "postgres";


ALTER TABLE "public"."jobs" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."order_details_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "display_name" "text",
    "profile_image" "text",
    "address" "text",
    "number" "text",
    "kin" "text",
    "kin_number" "text",
    "role" "public"."user_role_enum",
    "driver_licence" "text",
    "driver_lic_exp" "date",
    "pdp" "text",
    "pdp_exp" "date",
    "user_email" "text",
    "traf_reg" "text",
    "traf_exp_date" "date",
    "fcm_token" "text",
    "status" "text" DEFAULT 'active'::"text",
    "fcm_token_web" "text",
    CONSTRAINT "status_check" CHECK (("status" = ANY (ARRAY['active'::"text", 'deactivated'::"text", 'unassigned'::"text"])))
);

ALTER TABLE ONLY "public"."profiles" REPLICA IDENTITY NOTHING;


ALTER TABLE "public"."profiles" OWNER TO "postgres";


COMMENT ON COLUMN "public"."profiles"."fcm_token" IS 'FCM token for mobile/Android platform push notifications';



COMMENT ON COLUMN "public"."profiles"."fcm_token_web" IS 'FCM token for web platform push notifications';



CREATE TABLE IF NOT EXISTS "public"."quotes" (
    "id" bigint NOT NULL,
    "job_date" "date",
    "vehicle_type" "text",
    "quote_status" "text",
    "pax" numeric,
    "luggage" "text",
    "passenger_name" "text",
    "passenger_contact" "text",
    "notes" "text",
    "quote_pdf" "text",
    "client_id" bigint,
    "agent_id" bigint,
    "quote_date" "date",
    "quote_amount" numeric,
    "quote_title" "text",
    "quote_description" "text",
    "driver_id" "uuid",
    "vehicle_id" bigint,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "location" "text"
);


ALTER TABLE "public"."quotes" OWNER TO "postgres";


ALTER TABLE "public"."quotes" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."quotes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."quotes_transport_details" (
    "id" bigint NOT NULL,
    "quote_id" bigint,
    "pickup_date" timestamp without time zone,
    "pickup_location" "text",
    "dropoff_location" character varying,
    "amount" numeric,
    "notes" "text"
);


ALTER TABLE "public"."quotes_transport_details" OWNER TO "postgres";


COMMENT ON TABLE "public"."quotes_transport_details" IS 'This is a duplicate of transport_details';



ALTER TABLE "public"."quotes_transport_details" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."quotes_transport_details_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."transport" (
    "id" bigint NOT NULL,
    "job_id" bigint,
    "pickup_date" timestamp without time zone,
    "pickup_location" "text",
    "dropoff_location" character varying,
    "notes" "text",
    "client_pickup_time" timestamp without time zone,
    "client_dropoff_time" timestamp without time zone,
    "amount" numeric,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "updated_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "status" "text" DEFAULT 'pending'::"text",
    "pickup_arrived_at" timestamp with time zone,
    "passenger_onboard_at" timestamp with time zone,
    "dropoff_arrived_at" timestamp with time zone,
    CONSTRAINT "transport_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'pickup_arrived'::"text", 'passenger_onboard'::"text", 'dropoff_arrived'::"text", 'completed'::"text"])))
);


ALTER TABLE "public"."transport" OWNER TO "postgres";


ALTER TABLE "public"."transport" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."transport_details_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."user_notification_preferences" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "user_id" "uuid" NOT NULL,
    "job_assignments" boolean DEFAULT true,
    "job_reassignments" boolean DEFAULT true,
    "job_status_changes" boolean DEFAULT true,
    "job_cancellations" boolean DEFAULT true,
    "payment_reminders" boolean DEFAULT true,
    "system_alerts" boolean DEFAULT true,
    "push_notifications" boolean DEFAULT true,
    "in_app_notifications" boolean DEFAULT true,
    "email_notifications" boolean DEFAULT false,
    "sound_enabled" boolean DEFAULT true,
    "vibration_enabled" boolean DEFAULT true,
    "high_priority_only" boolean DEFAULT false,
    "quiet_hours_enabled" boolean DEFAULT false,
    "quiet_hours_start" time without time zone DEFAULT '22:00:00'::time without time zone,
    "quiet_hours_end" time without time zone DEFAULT '07:00:00'::time without time zone,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."user_notification_preferences" OWNER TO "postgres";


COMMENT ON TABLE "public"."user_notification_preferences" IS 'Stores user notification preferences and settings';



COMMENT ON COLUMN "public"."user_notification_preferences"."job_assignments" IS 'Whether to receive job assignment notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."job_reassignments" IS 'Whether to receive job reassignment notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."job_status_changes" IS 'Whether to receive job status change notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."job_cancellations" IS 'Whether to receive job cancellation notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."payment_reminders" IS 'Whether to receive payment reminder notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."system_alerts" IS 'Whether to receive system alert notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."push_notifications" IS 'Whether to receive push notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."in_app_notifications" IS 'Whether to show in-app notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."email_notifications" IS 'Whether to receive email notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."sound_enabled" IS 'Whether to play sound for notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."vibration_enabled" IS 'Whether to vibrate for notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."high_priority_only" IS 'Whether to only show high priority notifications';



COMMENT ON COLUMN "public"."user_notification_preferences"."quiet_hours_enabled" IS 'Whether to enable quiet hours';



COMMENT ON COLUMN "public"."user_notification_preferences"."quiet_hours_start" IS 'Start time for quiet hours (HH:MM format)';



COMMENT ON COLUMN "public"."user_notification_preferences"."quiet_hours_end" IS 'End time for quiet hours (HH:MM format)';



CREATE OR REPLACE VIEW "public"."view_dashboard_kpis" AS
 SELECT "count"(*) FILTER (WHERE ("quotes"."created_at" >= "date_trunc"('month'::"text", "now"()))) AS "quotes_this_month",
    "count"(*) FILTER (WHERE ("quotes"."quote_status" = 'approved'::"text")) AS "approved_quotes",
    "count"(*) FILTER (WHERE ("jobs"."job_status" = 'in_progress'::"text")) AS "jobs_in_progress",
    "count"(*) FILTER (WHERE ("jobs"."job_status" = 'completed'::"text")) AS "jobs_completed",
    "count"(*) FILTER (WHERE ("jobs"."job_status" = 'cancelled'::"text")) AS "jobs_cancelled",
    "sum"("quotes"."quote_amount") AS "total_quote_value",
    "count"(*) FILTER (WHERE ("jobs"."amount_collect" IS TRUE)) AS "jobs_to_collect"
   FROM ("public"."quotes"
     LEFT JOIN "public"."jobs" ON (("quotes"."id" = "jobs"."quote_no")));


ALTER TABLE "public"."view_dashboard_kpis" OWNER TO "postgres";


ALTER TABLE ONLY "public"."invoices" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."invoices_id_seq"'::"regclass");



ALTER TABLE ONLY "public"."vehicles"
    ADD CONSTRAINT "Garage_id_key" UNIQUE ("id");



ALTER TABLE ONLY "public"."vehicles"
    ADD CONSTRAINT "Garage_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."agents"
    ADD CONSTRAINT "agent_details_id_key" UNIQUE ("id");



ALTER TABLE ONLY "public"."agents"
    ADD CONSTRAINT "agent_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_notifications"
    ADD CONSTRAINT "app_notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."app_version"
    ADD CONSTRAINT "app_version_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."clients"
    ADD CONSTRAINT "client_details_id_key" UNIQUE ("id");



ALTER TABLE ONLY "public"."clients"
    ADD CONSTRAINT "client_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "device_tokens_profile_id_key" UNIQUE ("profile_id");



ALTER TABLE ONLY "public"."driver_flow"
    ADD CONSTRAINT "driver_flow_job_unique" UNIQUE ("job_id");



ALTER TABLE ONLY "public"."driver_flow"
    ADD CONSTRAINT "driver_flow_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."expenses"
    ADD CONSTRAINT "expenses_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."job_notification_log"
    ADD CONSTRAINT "job_notification_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."jobs"
    ADD CONSTRAINT "jobs_job_number_key" UNIQUE ("job_number");



ALTER TABLE ONLY "public"."login_attempts"
    ADD CONSTRAINT "login_attempts_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notification_delivery_log"
    ADD CONSTRAINT "notification_delivery_log_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."jobs"
    ADD CONSTRAINT "order_details_id_key" UNIQUE ("id");



ALTER TABLE ONLY "public"."jobs"
    ADD CONSTRAINT "order_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profile_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quotes"
    ADD CONSTRAINT "quotes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."quotes_transport_details"
    ADD CONSTRAINT "quotes_transport_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."transport"
    ADD CONSTRAINT "transport_details_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_notification_preferences"
    ADD CONSTRAINT "user_notification_preferences_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."user_notification_preferences"
    ADD CONSTRAINT "user_notification_preferences_user_id_key" UNIQUE ("user_id");



CREATE INDEX "idx_app_notifications_created_at" ON "public"."app_notifications" USING "btree" ("created_at" DESC);



CREATE INDEX "idx_app_notifications_job_id" ON "public"."app_notifications" USING "btree" ("job_id");



CREATE INDEX "idx_app_notifications_read" ON "public"."app_notifications" USING "btree" ("is_read");



CREATE INDEX "idx_app_notifications_type" ON "public"."app_notifications" USING "btree" ("notification_type");



CREATE INDEX "idx_app_notifications_unread" ON "public"."app_notifications" USING "btree" ("user_id", "is_read", "is_hidden") WHERE (("is_read" = false) AND ("is_hidden" = false));



CREATE INDEX "idx_app_notifications_user_id" ON "public"."app_notifications" USING "btree" ("user_id");



CREATE INDEX "idx_clients_company_registration_number" ON "public"."clients" USING "btree" ("company_registration_number");



CREATE INDEX "idx_clients_deleted_at" ON "public"."clients" USING "btree" ("deleted_at");



CREATE INDEX "idx_clients_status" ON "public"."clients" USING "btree" ("status");



CREATE INDEX "idx_clients_vat_number" ON "public"."clients" USING "btree" ("vat_number");



CREATE INDEX "idx_clients_website_address" ON "public"."clients" USING "btree" ("website_address");



CREATE INDEX "idx_device_tokens_profile" ON "public"."device_tokens" USING "btree" ("profile_id");



CREATE INDEX "idx_driver_flow_current_step" ON "public"."driver_flow" USING "btree" ("current_step");



CREATE INDEX "idx_driver_flow_driver_user" ON "public"."driver_flow" USING "btree" ("driver_user");



CREATE INDEX "idx_driver_flow_job_id" ON "public"."driver_flow" USING "btree" ("job_id");



CREATE INDEX "idx_driver_flow_last_activity" ON "public"."driver_flow" USING "btree" ("last_activity_at");



CREATE INDEX "idx_job_notification_log_pending" ON "public"."job_notification_log" USING "btree" ("status", "created_at") WHERE ("status" = 'pending'::"text");



CREATE INDEX "idx_jobs_agent_id" ON "public"."jobs" USING "btree" ("agent_id");



CREATE INDEX "idx_jobs_client_id" ON "public"."jobs" USING "btree" ("client_id");



CREATE INDEX "idx_jobs_driver_confirm_ind" ON "public"."jobs" USING "btree" ("driver_confirm_ind");



CREATE INDEX "idx_jobs_driver_id" ON "public"."jobs" USING "btree" ("driver_id");



COMMENT ON INDEX "public"."idx_jobs_driver_id" IS 'Index on driver_id field for efficient driver role-based filtering';



CREATE INDEX "idx_jobs_driver_id_not_null" ON "public"."jobs" USING "btree" ("driver_id") WHERE ("driver_id" IS NOT NULL);



COMMENT ON INDEX "public"."idx_jobs_driver_id_not_null" IS 'Partial index on non-null driver_id values for driver role filtering';



CREATE INDEX "idx_jobs_invoice_pdf" ON "public"."jobs" USING "btree" ("invoice_pdf") WHERE ("invoice_pdf" IS NOT NULL);



CREATE INDEX "idx_jobs_job_number" ON "public"."jobs" USING "btree" ("job_number");



CREATE INDEX "idx_jobs_pax" ON "public"."jobs" USING "btree" ("pax");



CREATE INDEX "idx_jobs_start_date" ON "public"."jobs" USING "btree" ("job_start_date");



CREATE INDEX "idx_jobs_vehicle_id" ON "public"."jobs" USING "btree" ("vehicle_id");



CREATE INDEX "idx_jobs_voucher_pdf" ON "public"."jobs" USING "btree" ("voucher_pdf") WHERE ("voucher_pdf" IS NOT NULL);



CREATE INDEX "idx_notification_delivery_log_notification_id" ON "public"."notification_delivery_log" USING "btree" ("notification_id");



CREATE INDEX "idx_notification_delivery_log_sent_at" ON "public"."notification_delivery_log" USING "btree" ("sent_at" DESC);



CREATE INDEX "idx_notification_delivery_log_user_id" ON "public"."notification_delivery_log" USING "btree" ("user_id");



CREATE INDEX "idx_profiles_fcm_token" ON "public"."profiles" USING "btree" ("fcm_token") WHERE ("fcm_token" IS NOT NULL);



CREATE INDEX "idx_profiles_fcm_token_mobile" ON "public"."profiles" USING "btree" ("fcm_token") WHERE ("fcm_token" IS NOT NULL);



CREATE INDEX "idx_profiles_fcm_token_web" ON "public"."profiles" USING "btree" ("fcm_token_web") WHERE ("fcm_token_web" IS NOT NULL);



CREATE INDEX "idx_quotes_status_date" ON "public"."quotes" USING "btree" ("quote_status", "quote_date");



CREATE INDEX "idx_user_notification_preferences_user_id" ON "public"."user_notification_preferences" USING "btree" ("user_id");



CREATE OR REPLACE TRIGGER "on_driver_flow_update" AFTER UPDATE ON "public"."driver_flow" FOR EACH ROW EXECUTE FUNCTION "public"."notify_driver_progress"();

ALTER TABLE "public"."driver_flow" DISABLE TRIGGER "on_driver_flow_update";



CREATE OR REPLACE TRIGGER "trg_agents_updated_at" BEFORE UPDATE ON "public"."agents" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_clients_updated_at" BEFORE UPDATE ON "public"."clients" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_expenses_updated_at" BEFORE UPDATE ON "public"."expenses" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_quotes_updated_at" BEFORE UPDATE ON "public"."quotes" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_transport_updated_at" BEFORE UPDATE ON "public"."transport" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trg_vehicles_updated_at" BEFORE UPDATE ON "public"."vehicles" FOR EACH ROW EXECUTE FUNCTION "public"."set_updated_at"();



CREATE OR REPLACE TRIGGER "trigger_update_driver_flow_activity" BEFORE UPDATE ON "public"."driver_flow" FOR EACH ROW EXECUTE FUNCTION "public"."update_driver_flow_activity"();

ALTER TABLE "public"."driver_flow" DISABLE TRIGGER "trigger_update_driver_flow_activity";



ALTER TABLE ONLY "public"."agents"
    ADD CONSTRAINT "agent_details_client_key_fkey" FOREIGN KEY ("client_key") REFERENCES "public"."clients"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."app_notifications"
    ADD CONSTRAINT "app_notifications_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."driver_flow"
    ADD CONSTRAINT "driver_flow_driver_user_fkey" FOREIGN KEY ("driver_user") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."driver_flow"
    ADD CONSTRAINT "driver_flow_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."device_tokens"
    ADD CONSTRAINT "fk_device_tokens_profile" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."invoices"
    ADD CONSTRAINT "invoices_quote_id_fkey" FOREIGN KEY ("quote_id") REFERENCES "public"."quotes"("id");



ALTER TABLE ONLY "public"."job_notification_log"
    ADD CONSTRAINT "job_notification_log_driver_id_fkey" FOREIGN KEY ("driver_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."job_notification_log"
    ADD CONSTRAINT "job_notification_log_job_id_fkey" FOREIGN KEY ("job_id") REFERENCES "public"."jobs"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."jobs"
    ADD CONSTRAINT "jobs_confirmed_by_fkey" FOREIGN KEY ("confirmed_by") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."notification_delivery_log"
    ADD CONSTRAINT "notification_delivery_log_notification_id_fkey" FOREIGN KEY ("notification_id") REFERENCES "public"."app_notifications"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."notification_delivery_log"
    ADD CONSTRAINT "notification_delivery_log_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."jobs"
    ADD CONSTRAINT "order_details_client_id_fkey" FOREIGN KEY ("client_id") REFERENCES "public"."clients"("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profile_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON UPDATE CASCADE ON DELETE CASCADE;



ALTER TABLE ONLY "public"."quotes"
    ADD CONSTRAINT "quote_details_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "public"."agents"("id");



ALTER TABLE ONLY "public"."quotes"
    ADD CONSTRAINT "quotes_company_id_fkey" FOREIGN KEY ("client_id") REFERENCES "public"."clients"("id");



ALTER TABLE ONLY "public"."quotes_transport_details"
    ADD CONSTRAINT "quotes_transport_details_job_id_fkey" FOREIGN KEY ("quote_id") REFERENCES "public"."quotes"("id");



ALTER TABLE ONLY "public"."user_notification_preferences"
    ADD CONSTRAINT "user_notification_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



CREATE POLICY "Allow authenticated delete transport" ON "public"."transport" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated insert transport" ON "public"."transport" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "Allow authenticated read transport" ON "public"."transport" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow authenticated update transport" ON "public"."transport" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Allow logged in user to update own profile" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));



CREATE POLICY "Allow read" ON "public"."driver_flow" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Allow self-update" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Authenticated can read fcm_token" ON "public"."profiles" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "Authenticated user can update own profile" ON "public"."profiles" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Authenticated users can delete driver_flow" ON "public"."driver_flow" FOR DELETE USING ((("auth"."uid"())::"text" = USER));



CREATE POLICY "Authenticated users can insert driver_flow" ON "public"."driver_flow" FOR INSERT TO "authenticated" WITH CHECK ((USER = ("auth"."uid"())::"text"));



CREATE POLICY "Authenticated users can read driver_flow" ON "public"."driver_flow" FOR SELECT USING (("auth"."uid"() IS NOT NULL));



CREATE POLICY "Authenticated users can update driver_flow" ON "public"."driver_flow" FOR UPDATE USING ((("auth"."uid"())::"text" = USER));



CREATE POLICY "Client Policy" ON "public"."clients" TO "authenticated", "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "Profile Policy" ON "public"."profiles" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "Users can insert own notification preferences" ON "public"."user_notification_preferences" FOR INSERT WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update own notification preferences" ON "public"."user_notification_preferences" FOR UPDATE USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can update their fcm_token only" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK ((("auth"."uid"() = "id") AND ("fcm_token" IS NOT NULL)));



CREATE POLICY "Users can update their own profile" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id")) WITH CHECK (("auth"."uid"() = "id"));



CREATE POLICY "Users can view own notification preferences" ON "public"."user_notification_preferences" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Users can view their own delivery logs" ON "public"."notification_delivery_log" FOR SELECT USING (("auth"."uid"() = "user_id"));



CREATE POLICY "Version Control" ON "public"."app_version" USING (true) WITH CHECK (true);



CREATE POLICY "agent rules" ON "public"."agents" TO "authenticated" USING (true) WITH CHECK (true);



CREATE POLICY "allow_anon_insert" ON "public"."app_notifications" FOR INSERT TO "anon" WITH CHECK (true);



CREATE POLICY "allow_authenticated_insert" ON "public"."app_notifications" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "allow_service_role_all" ON "public"."app_notifications" TO "service_role" USING (true) WITH CHECK (true);



CREATE POLICY "allow_users_update_own" ON "public"."app_notifications" FOR UPDATE TO "authenticated" USING (("auth"."uid"() = "user_id")) WITH CHECK (("auth"."uid"() = "user_id"));



CREATE POLICY "allow_users_view_own" ON "public"."app_notifications" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "user_id"));



CREATE POLICY "dt_admin_manager_full" ON "public"."device_tokens" USING (("public"."current_user_role"() = ANY (ARRAY['administrator'::"public"."user_role_enum", 'manager'::"public"."user_role_enum"]))) WITH CHECK (("public"."current_user_role"() = ANY (ARRAY['administrator'::"public"."user_role_enum", 'manager'::"public"."user_role_enum"])));



CREATE POLICY "dt_self_manage" ON "public"."device_tokens" USING ((("profile_id" = "auth"."uid"()) AND ("public"."current_user_role"() <> 'suspended'::"public"."user_role_enum"))) WITH CHECK ((("profile_id" = "auth"."uid"()) AND ("public"."current_user_role"() <> 'suspended'::"public"."user_role_enum")));



ALTER TABLE "public"."expenses" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "jobs_delete_policy" ON "public"."jobs" FOR DELETE TO "authenticated" USING (true);



CREATE POLICY "jobs_insert_policy" ON "public"."jobs" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "jobs_select_policy" ON "public"."jobs" FOR SELECT TO "authenticated" USING (true);



CREATE POLICY "jobs_update_policy" ON "public"."jobs" FOR UPDATE TO "authenticated" USING (true) WITH CHECK (true);



ALTER TABLE "public"."user_notification_preferences" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "vehicle_details_policy" ON "public"."vehicles" TO "authenticated" USING (true) WITH CHECK (true);





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";












GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "app_auth"."create_user_profile"() TO "dashboard_user";









































































































































































































GRANT ALL ON FUNCTION "public"."arrive_at_dropoff"("job_id" bigint, "trip_index" integer, "gps_lat" numeric, "gps_lng" numeric, "gps_accuracy" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."arrive_at_dropoff"("job_id" bigint, "trip_index" integer, "gps_lat" numeric, "gps_lng" numeric, "gps_accuracy" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."arrive_at_dropoff"("job_id" bigint, "trip_index" integer, "gps_lat" numeric, "gps_lng" numeric, "gps_accuracy" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."block_notifications_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."block_notifications_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."block_notifications_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."calculate_job_progress"("job_id_param" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."calculate_job_progress"("job_id_param" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."calculate_job_progress"("job_id_param" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."clean_text"("input_text" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."clean_text"("input_text" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."clean_text"("input_text" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."cleanup_expired_notifications"() TO "anon";
GRANT ALL ON FUNCTION "public"."cleanup_expired_notifications"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."cleanup_expired_notifications"() TO "service_role";



GRANT ALL ON FUNCTION "public"."close_job"("job_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."close_job"("job_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."close_job"("job_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."complete_trip"("job_id" bigint, "trip_index" integer, "notes" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."complete_trip"("job_id" bigint, "trip_index" integer, "notes" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."complete_trip"("job_id" bigint, "trip_index" integer, "notes" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."copy_quote_transport_to_job"("source_quote_id" bigint, "target_job_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."copy_quote_transport_to_job"("source_quote_id" bigint, "target_job_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."copy_quote_transport_to_job"("source_quote_id" bigint, "target_job_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."create_user_profile"() TO "anon";
GRANT ALL ON FUNCTION "public"."create_user_profile"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_user_profile"() TO "service_role";



GRANT ALL ON FUNCTION "public"."current_user_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."current_user_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_user_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."ensure_driver_flow_record"("p_job_id" bigint, "p_driver_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."ensure_driver_flow_record"("p_job_id" bigint, "p_driver_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."ensure_driver_flow_record"("p_job_id" bigint, "p_driver_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_driver_current_job"("driver_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_driver_current_job"("driver_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_driver_current_job"("driver_uuid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_invoice_data_for_job"("p_job_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_invoice_data_for_job"("p_job_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_invoice_data_for_job"("p_job_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_invoice_data_for_pdf"("p_job_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_invoice_data_for_pdf"("p_job_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_invoice_data_for_pdf"("p_job_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_job_progress"("job_id_param" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_job_progress"("job_id_param" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_job_progress"("job_id_param" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_jobs_needing_start_deadline_notifications"("p_current_time" timestamp with time zone) TO "anon";
GRANT ALL ON FUNCTION "public"."get_jobs_needing_start_deadline_notifications"("p_current_time" timestamp with time zone) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_jobs_needing_start_deadline_notifications"("p_current_time" timestamp with time zone) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_notification_stats"("user_uuid" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."get_notification_stats"("user_uuid" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_notification_stats"("user_uuid" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."get_quote_data_for_pdf"("p_quote_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_quote_data_for_pdf"("p_quote_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_quote_data_for_pdf"("p_quote_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_trip_progress"("job_id_param" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_trip_progress"("job_id_param" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_trip_progress"("job_id_param" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_voucher_data_for_job"("p_job_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."get_voucher_data_for_job"("p_job_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_voucher_data_for_job"("p_job_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."get_voucher_data_for_pdf"("p_voucher_id" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."get_voucher_data_for_pdf"("p_voucher_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_voucher_data_for_pdf"("p_voucher_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_notifications_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_notifications_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_notifications_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."http_post_for_cron"("p_url" "text", "p_headers" "jsonb", "p_body" "jsonb", "p_timeout_milliseconds" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."http_post_for_cron"("p_url" "text", "p_headers" "jsonb", "p_body" "jsonb", "p_timeout_milliseconds" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."http_post_for_cron"("p_url" "text", "p_headers" "jsonb", "p_body" "jsonb", "p_timeout_milliseconds" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."insert_notification"("_user_id" "uuid", "_body" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."insert_notification"("_user_id" "uuid", "_body" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."insert_notification"("_user_id" "uuid", "_body" "text") TO "service_role";



GRANT ALL ON FUNCTION "public"."log_notification_created"() TO "anon";
GRANT ALL ON FUNCTION "public"."log_notification_created"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."log_notification_created"() TO "service_role";



GRANT ALL ON FUNCTION "public"."mark_notifications_as_read"("notification_ids" "uuid"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."mark_notifications_as_read"("notification_ids" "uuid"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."mark_notifications_as_read"("notification_ids" "uuid"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."notify_driver_progress"() TO "anon";
GRANT ALL ON FUNCTION "public"."notify_driver_progress"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."notify_driver_progress"() TO "service_role";



GRANT ALL ON FUNCTION "public"."passenger_onboard"("job_id" bigint, "trip_index" integer) TO "anon";
GRANT ALL ON FUNCTION "public"."passenger_onboard"("job_id" bigint, "trip_index" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."passenger_onboard"("job_id" bigint, "trip_index" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."resume_job"("job_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."resume_job"("job_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."resume_job"("job_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "anon";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."set_updated_at"() TO "service_role";



GRANT ALL ON FUNCTION "public"."start_job"("job_id" bigint, "odo_start_reading" numeric, "pdp_start_image" "text", "gps_lat" numeric, "gps_lng" numeric, "gps_accuracy" numeric) TO "anon";
GRANT ALL ON FUNCTION "public"."start_job"("job_id" bigint, "odo_start_reading" numeric, "pdp_start_image" "text", "gps_lat" numeric, "gps_lng" numeric, "gps_accuracy" numeric) TO "authenticated";
GRANT ALL ON FUNCTION "public"."start_job"("job_id" bigint, "odo_start_reading" numeric, "pdp_start_image" "text", "gps_lat" numeric, "gps_lng" numeric, "gps_accuracy" numeric) TO "service_role";



GRANT ALL ON FUNCTION "public"."suppress_notifications_insert"() TO "anon";
GRANT ALL ON FUNCTION "public"."suppress_notifications_insert"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."suppress_notifications_insert"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_driver_flow_activity"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_driver_flow_activity"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_driver_flow_activity"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_expired_quotes"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_expired_quotes"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_expired_quotes"() TO "service_role";



GRANT ALL ON FUNCTION "public"."update_job_total"("job_to_update" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."update_job_total"("job_to_update" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_job_total"("job_to_update" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."update_trip_progress_timestamp"() TO "anon";
GRANT ALL ON FUNCTION "public"."update_trip_progress_timestamp"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_trip_progress_timestamp"() TO "service_role";



GRANT ALL ON FUNCTION "public"."updatelastmessage"() TO "anon";
GRANT ALL ON FUNCTION "public"."updatelastmessage"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."updatelastmessage"() TO "service_role";



GRANT ALL ON FUNCTION "public"."upsert_device_token"("p_profile_id" "uuid", "p_token" "text") TO "anon";
GRANT ALL ON FUNCTION "public"."upsert_device_token"("p_profile_id" "uuid", "p_token" "text") TO "authenticated";
GRANT ALL ON FUNCTION "public"."upsert_device_token"("p_profile_id" "uuid", "p_token" "text") TO "service_role";
























GRANT ALL ON TABLE "public"."vehicles" TO "anon";
GRANT ALL ON TABLE "public"."vehicles" TO "authenticated";
GRANT ALL ON TABLE "public"."vehicles" TO "service_role";



GRANT ALL ON SEQUENCE "public"."Garage_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."Garage_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."Garage_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."agents" TO "anon";
GRANT ALL ON TABLE "public"."agents" TO "authenticated";
GRANT ALL ON TABLE "public"."agents" TO "service_role";



GRANT ALL ON SEQUENCE "public"."agent_details_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."agent_details_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."agent_details_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."app_notifications" TO "anon";
GRANT ALL ON TABLE "public"."app_notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."app_notifications" TO "service_role";



GRANT ALL ON TABLE "public"."app_version" TO "anon";
GRANT ALL ON TABLE "public"."app_version" TO "authenticated";
GRANT ALL ON TABLE "public"."app_version" TO "service_role";



GRANT ALL ON SEQUENCE "public"."app_version_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."app_version_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."app_version_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."clients" TO "anon";
GRANT ALL ON TABLE "public"."clients" TO "authenticated";
GRANT ALL ON TABLE "public"."clients" TO "service_role";



GRANT ALL ON SEQUENCE "public"."client_details_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."client_details_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."client_details_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."device_tokens" TO "anon";
GRANT ALL ON TABLE "public"."device_tokens" TO "authenticated";
GRANT ALL ON TABLE "public"."device_tokens" TO "service_role";



GRANT ALL ON SEQUENCE "public"."device_tokens_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."device_tokens_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."device_tokens_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."driver_flow" TO "anon";
GRANT ALL ON TABLE "public"."driver_flow" TO "authenticated";
GRANT ALL ON TABLE "public"."driver_flow" TO "service_role";



GRANT ALL ON SEQUENCE "public"."driver_flow_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."driver_flow_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."driver_flow_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."expenses" TO "anon";
GRANT ALL ON TABLE "public"."expenses" TO "authenticated";
GRANT ALL ON TABLE "public"."expenses" TO "service_role";



GRANT ALL ON SEQUENCE "public"."expenses_details_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."expenses_details_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."expenses_details_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."invoices" TO "anon";
GRANT ALL ON TABLE "public"."invoices" TO "authenticated";
GRANT ALL ON TABLE "public"."invoices" TO "service_role";



GRANT ALL ON SEQUENCE "public"."invoices_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."invoices_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."invoices_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."job_notification_log" TO "anon";
GRANT ALL ON TABLE "public"."job_notification_log" TO "authenticated";
GRANT ALL ON TABLE "public"."job_notification_log" TO "service_role";



GRANT ALL ON TABLE "public"."jobs" TO "anon";
GRANT ALL ON TABLE "public"."jobs" TO "authenticated";
GRANT ALL ON TABLE "public"."jobs" TO "service_role";



GRANT ALL ON TABLE "public"."login_attempts" TO "anon";
GRANT ALL ON TABLE "public"."login_attempts" TO "authenticated";
GRANT ALL ON TABLE "public"."login_attempts" TO "service_role";



GRANT ALL ON TABLE "public"."notification_delivery_log" TO "anon";
GRANT ALL ON TABLE "public"."notification_delivery_log" TO "authenticated";
GRANT ALL ON TABLE "public"."notification_delivery_log" TO "service_role";



GRANT ALL ON TABLE "public"."notifications_backup" TO "anon";
GRANT ALL ON TABLE "public"."notifications_backup" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications_backup" TO "service_role";



GRANT ALL ON SEQUENCE "public"."order_details_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."order_details_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."order_details_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."quotes" TO "anon";
GRANT ALL ON TABLE "public"."quotes" TO "authenticated";
GRANT ALL ON TABLE "public"."quotes" TO "service_role";



GRANT ALL ON SEQUENCE "public"."quotes_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."quotes_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."quotes_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."quotes_transport_details" TO "anon";
GRANT ALL ON TABLE "public"."quotes_transport_details" TO "authenticated";
GRANT ALL ON TABLE "public"."quotes_transport_details" TO "service_role";



GRANT ALL ON SEQUENCE "public"."quotes_transport_details_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."quotes_transport_details_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."quotes_transport_details_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."transport" TO "anon";
GRANT ALL ON TABLE "public"."transport" TO "authenticated";
GRANT ALL ON TABLE "public"."transport" TO "service_role";



GRANT ALL ON SEQUENCE "public"."transport_details_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."transport_details_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."transport_details_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."user_notification_preferences" TO "anon";
GRANT ALL ON TABLE "public"."user_notification_preferences" TO "authenticated";
GRANT ALL ON TABLE "public"."user_notification_preferences" TO "service_role";



GRANT ALL ON TABLE "public"."view_dashboard_kpis" TO "anon";
GRANT ALL ON TABLE "public"."view_dashboard_kpis" TO "authenticated";
GRANT ALL ON TABLE "public"."view_dashboard_kpis" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS  TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES  TO "service_role";






























