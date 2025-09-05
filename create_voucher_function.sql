-- Create voucher data function with client logo support
CREATE OR REPLACE FUNCTION get_voucher_data_for_job(p_job_id bigint)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Check if user has access to this voucher/job
  IF NOT EXISTS (
    SELECT 1 FROM jobs j
    JOIN clients c ON j.client_id = c.id
    WHERE j.id = p_job_id
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

        -- client & agent with logo support
        'company_name',       coalesce(cd.company_name,     ''),
        'company_logo',       coalesce(cd.logo_url,         ''),  -- ADDED: Client logo URL
        'agent_name',         coalesce(ad.agent_name,       ''),
        'agent_contact',      coalesce(ad.contact_number,   ''),  -- ADDED: Agent contact

        -- driver information
        'driver_name',        coalesce(pd.full_name,        'Not assigned'),
        'driver_contact',     coalesce(pd.phone,            'Not available'),

        -- trip lines
        'transport_details', (
          SELECT coalesce(
            jsonb_agg(
              jsonb_build_object(
                'pickup_date',      td.pickup_date,
                'pickup_time',      td.pickup_date,
                'pickup_location',  coalesce(td.pickup_location,  ''),
                'dropoff_location', coalesce(td.dropoff_location, ''),
                'amount',           coalesce(td.amount,           0)
              )
              ORDER BY td.pickup_date ASC
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
    LEFT JOIN public.profiles pd ON pd.id = j.driver_id
    WHERE j.id = p_job_id
  );
END;
$$;

-- Grant execute permission
GRANT EXECUTE ON FUNCTION get_voucher_data_for_job(bigint) TO authenticated;
