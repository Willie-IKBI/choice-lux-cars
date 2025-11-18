set check_function_bodies = off;

CREATE OR REPLACE FUNCTION app_auth.create_user_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  -- insert into the real profiles table
  INSERT INTO public.profiles (id, user_email)
  VALUES (NEW.id, NEW.email);
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.arrive_at_dropoff(job_id bigint, trip_index integer, gps_lat numeric, gps_lng numeric, gps_accuracy numeric)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.block_notifications_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
declare
  dummy_row notifications;
begin
  dummy_row.id := gen_random_uuid();
  dummy_row.user_id := new.user_id;
  dummy_row.created_at := now();
  dummy_row.body := 'Notifications suppressed';
  return dummy_row;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.calculate_job_progress(job_id_param bigint)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.clean_text(input_text text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.cleanup_expired_notifications()
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.copy_quote_transport_to_job(source_quote_id bigint, target_job_id bigint)
 RETURNS void
 LANGUAGE sql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.create_user_profile()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$BEGIN
  INSERT INTO public.profile(id, display_name, user_email)
  VALUES (NEW.id, 'Add User Name', New.email);
  RETURN NEW;
END;$function$
;

CREATE OR REPLACE FUNCTION public.current_user_role()
 RETURNS public.user_role_enum
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
  r public.user_role_enum;
BEGIN
  SELECT role
    INTO r
    FROM public.profiles
   WHERE id = auth.uid();
  RETURN r;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.get_driver_current_job(driver_uuid uuid)
 RETURNS TABLE(job_id bigint, current_step text, progress_percentage integer, last_activity_at timestamp with time zone, total_trips integer, completed_trips integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_invoice_data_for_job(p_job_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$DECLARE
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
END;$function$
;

CREATE OR REPLACE FUNCTION public.get_invoice_data_for_pdf(p_job_id bigint)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_job_progress(job_id_param bigint)
 RETURNS TABLE(job_id bigint, current_step text, progress_percentage integer, total_trips integer, completed_trips integer, current_trip_index integer, job_status text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_notification_stats(user_uuid uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_quote_data_for_pdf(p_quote_id bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_trip_progress(job_id_param bigint)
 RETURNS TABLE(trip_index integer, status text, pickup_arrived_at timestamp with time zone, passenger_onboard_at timestamp with time zone, dropoff_arrived_at timestamp with time zone, completed_at timestamp with time zone, pickup_gps_lat numeric, pickup_gps_lng numeric, dropoff_gps_lat numeric, dropoff_gps_lng numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.get_voucher_data_for_job(p_job_id bigint)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$BEGIN
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
END;$function$
;

CREATE OR REPLACE FUNCTION public.get_voucher_data_for_pdf(p_voucher_id integer)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$DECLARE
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
END;$function$
;

CREATE OR REPLACE FUNCTION public.handle_notifications_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  -- Add your logic here. For example:
  -- If you want to suppress based on some condition:
  IF NEW.user_id IS NULL THEN
    -- mark as suppressed, or log externally
    UPDATE notifications SET suppressed = true WHERE id = NEW.id;
  END IF;

  RETURN NULL;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.http_post_for_cron(p_url text, p_headers jsonb DEFAULT '{}'::jsonb, p_body jsonb DEFAULT '{}'::jsonb, p_timeout_milliseconds integer DEFAULT 30000)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'net'
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.insert_notification(_user_id uuid, _body text)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.log_notification_created()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.mark_notifications_as_read(notification_ids uuid[])
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
  UPDATE public.app_notifications
  SET 
    is_read = true,
    read_at = NOW(),
    updated_at = NOW()
  WHERE id = ANY(notification_ids);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.notify_driver_progress()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.suppress_notifications_insert()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.update_driver_flow_activity()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.last_activity_at = NOW();
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.update_expired_quotes()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$BEGIN
  UPDATE public.quotes -- Use public.quotes if your table is in the public schema
  SET quote_status = 'Expired'
  WHERE
    quote_status = 'Open'
    AND quote_date < (NOW() - INTERVAL '24 hours');
END;$function$
;

CREATE OR REPLACE FUNCTION public.update_job_total(job_to_update uuid)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
;

CREATE OR REPLACE FUNCTION public.update_trip_progress_timestamp()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.updatelastmessage()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
begin
    update chats
    set 
        last_message = new.message_text,
        last_message_time = new.created_at
    where id = new.recipient_id;

    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.upsert_device_token(p_profile_id uuid, p_token text)
 RETURNS TABLE(profile_id uuid, token text, last_seen timestamp with time zone)
 LANGUAGE sql
AS $function$
  INSERT INTO public.device_tokens (profile_id, token, last_seen)
  VALUES (p_profile_id, p_token, NOW())
  ON CONFLICT (profile_id)
  DO UPDATE
    SET token     = EXCLUDED.token,
        last_seen = EXCLUDED.last_seen
  RETURNING profile_id, token, last_seen;
$function$
;

CREATE TRIGGER new_user_trigger AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION app_auth.create_user_profile();


  create policy "Allow authenticated access to vouchers 5pc552_0"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using (((bucket_id = 'pdfdocuments'::text) AND ('vouchers'::text = ANY (storage.foldername(name)))));



  create policy "Allow authenticated access to vouchers 5pc552_1"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'pdfdocuments'::text) AND ('vouchers'::text = ANY (storage.foldername(name)))));



  create policy "Allow authenticated access to vouchers 5pc552_2"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'pdfdocuments'::text) AND ('vouchers'::text = ANY (storage.foldername(name)))));



  create policy "Allow authenticated reads from invoices folder 5pc552_0"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using (((bucket_id = 'pdfdocuments'::text) AND (name ~~ 'invoices/%'::text)));



  create policy "Allow authenticated reads from invoices folder 5pc552_1"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'pdfdocuments'::text) AND (name ~~ 'invoices/%'::text)));



  create policy "Allow authenticated reads from invoices folder 5pc552_2"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'pdfdocuments'::text) AND (name ~~ 'invoices/%'::text)));



  create policy "Allow authenticated reads from quotes folder"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using (((bucket_id = 'pdfdocuments'::text) AND (name ~~ 'quotes/%'::text)));



  create policy "Allow authenticated updates in quotes folder"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using (((bucket_id = 'pdfdocuments'::text) AND (name ~~ 'quotes/%'::text)))
with check (((bucket_id = 'pdfdocuments'::text) AND (name ~~ 'quotes/%'::text)));



  create policy "Allow authenticated uploads to quotes folder"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check (((bucket_id = 'pdfdocuments'::text) AND (name ~~ 'quotes/%'::text)));



  create policy "Allow full Acess 1rdzryk_0"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'messages'::text));



  create policy "Allow full Acess 1rdzryk_1"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'messages'::text));



  create policy "Allow full Acess 1rdzryk_2"
  on "storage"."objects"
  as permissive
  for update
  to public
using ((bucket_id = 'messages'::text));



  create policy "Allow full Acess 1rdzryk_3"
  on "storage"."objects"
  as permissive
  for delete
  to public
using ((bucket_id = 'messages'::text));



  create policy "Allow full access 1kc463_0"
  on "storage"."objects"
  as permissive
  for select
  to public
using ((bucket_id = 'chats'::text));



  create policy "Allow full access 1kc463_1"
  on "storage"."objects"
  as permissive
  for insert
  to public
with check ((bucket_id = 'chats'::text));



  create policy "Allow full access 1kc463_2"
  on "storage"."objects"
  as permissive
  for update
  to public
using ((bucket_id = 'chats'::text));



  create policy "Allow full access 1kc463_3"
  on "storage"."objects"
  as permissive
  for delete
  to public
using ((bucket_id = 'chats'::text));



  create policy "CLC Photo Bucket Access 12vublp_0"
  on "storage"."objects"
  as permissive
  for select
  to authenticated
using ((bucket_id = 'clc_images'::text));



  create policy "CLC Photo Bucket Access 12vublp_1"
  on "storage"."objects"
  as permissive
  for insert
  to authenticated
with check ((bucket_id = 'clc_images'::text));



  create policy "CLC Photo Bucket Access 12vublp_2"
  on "storage"."objects"
  as permissive
  for update
  to authenticated
using ((bucket_id = 'clc_images'::text));



  create policy "CLC Photo Bucket Access 12vublp_3"
  on "storage"."objects"
  as permissive
  for delete
  to authenticated
using ((bucket_id = 'clc_images'::text));



