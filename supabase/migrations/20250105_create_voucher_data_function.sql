-- =====================================================
-- CREATE VOUCHER DATA FUNCTION
-- Choice Lux Cars - Voucher PDF Data Function
-- Includes client logo support
-- =====================================================

-- Create or replace the function to get voucher data for PDF generation
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

  -- Return the complete voucher data with client branding
  RETURN (
    SELECT
      jsonb_build_object(
        -- job fields
        'job_id',             j.id,
        'job_date',           to_char(j.job_start_date, 'YYYY-MM-DD'),
        'job_title',          '',
        'job_description',    coalesce(j.notes, ''),
        'passenger_name',     coalesce(j.passenger_name, ''),
        'passenger_contact',  coalesce(j.passenger_contact, ''),
        'vehicle_type',       coalesce(concat(v.make, ' ', v.model), ''),
        'number_passangers',  coalesce(j.pax, 0),
        'luggage',            coalesce(j.number_bags, ''),
        'amount',             coalesce(j.amount, 0),
        'notes',              coalesce(j.notes, ''),

        -- client & agent with logo support
        'company_name',       coalesce(c.company_name, ''),
        'company_logo',       coalesce(c.company_logo, ''),
        'client_website',     coalesce(c.website_address, ''),
        'client_contact_phone', coalesce(c.contact_number, ''),
        'client_contact_email', coalesce(c.contact_email, ''),
        'client_registration', coalesce(c.company_registration_number, ''),
        'client_vat_number',  coalesce(c.vat_number, ''),
        'agent_name',         coalesce(a.agent_name, ''),
        'agent_contact',      coalesce(a.contact_number, ''),

        -- driver information
        'driver_name',        coalesce(p.display_name, 'Not assigned'),
        'driver_contact',     coalesce(p.number, 'Not available'),

        -- transport details
        'transport_details', (
          SELECT coalesce(
            jsonb_agg(
              jsonb_build_object(
                'pickup_date',      t.pickup_date,
                'pickup_time',      t.pickup_date,
                'pickup_location',  replace(replace(coalesce(t.pickup_location, ''), chr(8211), '-'), chr(8212), '-'),
                'dropoff_location', replace(replace(coalesce(t.dropoff_location, ''), chr(8211), '-'), chr(8212), '-'),
                'amount',           coalesce(t.amount, 0),
                'notes',            coalesce(t.notes, '')
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
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_voucher_data_for_job(bigint) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_voucher_data_for_job(bigint) IS 'Fetches complete voucher data for PDF generation including client branding, logo, contact info, and driver information';

-- =====================================================
-- FUNCTION CREATED SUCCESSFULLY
-- =====================================================
