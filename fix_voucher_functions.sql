-- Fix both voucher RPC functions to ensure they work properly
-- Run this in your Supabase Dashboard SQL Editor

-- First, fix the main voucher data function
CREATE OR REPLACE FUNCTION get_voucher_data_for_pdf(p_voucher_id int)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result json;
    job_record record;
    transport_data json;
BEGIN
    -- Check if user has access to this voucher/job
    -- This ensures tenant isolation and security
    IF NOT EXISTS (
        SELECT 1 FROM jobs j
        JOIN clients c ON j.client_id = c.id
        WHERE j.id = p_voucher_id
        AND c.status = 'active'
    ) THEN
        RAISE EXCEPTION 'Access denied: Job not found or client inactive';
    END IF;

    -- Get job data with all related information
    SELECT 
        j.id as job_id,
        j.quote_no,
        j.order_date as quote_date,
        c.company_name,
        c.company_logo,
        a.agent_name,
        a.contact_number as agent_contact,
        j.passenger_name,
        j.passenger_contact,
        j.pax as number_passangers,
        j.number_bags as luggage,
        p.display_name as driver_name,
        v.make || ' ' || v.model as vehicle_type,
        j.notes
    INTO job_record
    FROM jobs j
    LEFT JOIN clients c ON j.client_id = c.id
    LEFT JOIN agents a ON j.agent_id = a.id
    LEFT JOIN profiles p ON j.driver_id = p.id
    LEFT JOIN vehicles v ON j.vehicle_id = v.id
    WHERE j.id = p_voucher_id;

    -- Get transport details for the job
    SELECT json_agg(
        json_build_object(
            'pickup_date', t.pickup_date,
            'pickup_time', to_char(t.pickup_date, 'HH24:MI'),
            'pickup_location', t.pickup_location,
            'dropoff_location', t.dropoff_location
        )
    ) INTO transport_data
    FROM transport t
    WHERE t.job_id = p_voucher_id
    ORDER BY t.pickup_date;

    -- Build the complete result
    result := json_build_object(
        'job_id', job_record.job_id,
        'quote_no', job_record.quote_no,
        'quote_date', job_record.quote_date,
        'company_name', COALESCE(job_record.company_name, 'Choice Lux Cars'),
        'company_logo', job_record.company_logo,
        'agent_name', COALESCE(job_record.agent_name, 'Not available'),
        'agent_contact', COALESCE(job_record.agent_contact, 'Not available'),
        'passenger_name', COALESCE(job_record.passenger_name, 'Not specified'),
        'passenger_contact', COALESCE(job_record.passenger_contact, 'Not specified'),
        'number_passangers', COALESCE(job_record.number_passangers, 0),
        'luggage', COALESCE(job_record.luggage, 'Not specified'),
        'driver_name', COALESCE(job_record.driver_name, 'Not assigned'),
        'vehicle_type', COALESCE(job_record.vehicle_type, 'Not assigned'),
        'transport', COALESCE(transport_data, '[]'::json),
        'notes', COALESCE(job_record.notes, '')
    );

    RETURN result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_voucher_data_for_pdf(int) TO authenticated;

-- Now fix the convenience function that calls the main function
CREATE OR REPLACE FUNCTION get_voucher_data_for_job(p_job_id int)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Simply call the existing function with job_id as voucher_id
    RETURN get_voucher_data_for_pdf(p_job_id);
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_voucher_data_for_job(int) TO authenticated;

-- Add comments for documentation
COMMENT ON FUNCTION get_voucher_data_for_pdf(int) IS 'Fetches complete voucher data for PDF generation including job details, client info, agent details, passenger info, driver/vehicle info, and transport details. Fixed pickup_time formatting.';
COMMENT ON FUNCTION get_voucher_data_for_job(int) IS 'Convenience function to get voucher data directly by job_id';
