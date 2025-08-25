-- Fix the invoice RPC function and add missing column
-- Run this in your Supabase SQL Editor

-- 1. Fix the RPC function with correct column name
CREATE OR REPLACE FUNCTION get_invoice_data_for_pdf(p_job_id int)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result json;
    job_record record;
    transport_data json;
    banking_details json;
BEGIN
    -- Check if user has access to this job
    -- This ensures tenant isolation and security
    IF NOT EXISTS (
        SELECT 1 FROM jobs j
        JOIN clients c ON j.client_id = c.id
        WHERE j.id = p_job_id
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
        j.pax as number_passengers,
        j.number_bags as luggage,
        p.display_name as driver_name,
        p.number as driver_contact,  -- Fixed: was p.phone, now p.number
        v.make || ' ' || v.model as vehicle_type,
        j.notes,
        j.amount as total_amount,
        COALESCE(j.amount * 0.15, 0) as tax_amount, -- 15% VAT
        COALESCE(j.amount * 0.85, 0) as subtotal -- Amount before tax
    INTO job_record
    FROM jobs j
    LEFT JOIN clients c ON j.client_id = c.id
    LEFT JOIN agents a ON j.agent_id = a.id
    LEFT JOIN profiles p ON j.driver_id = p.id
    LEFT JOIN vehicles v ON j.vehicle_id = v.id
    WHERE j.id = p_job_id;

    -- Get transport details for the job
    SELECT json_agg(
        json_build_object(
            'date', t.pickup_date,
            'time', to_char(t.pickup_date, 'HH24:MI'),
            'pickup_location', t.pickup_location,
            'dropoff_location', t.dropoff_location
        ) ORDER BY t.pickup_date
    ) INTO transport_data
    FROM transport t
    WHERE t.job_id = p_job_id;

    -- Get banking details (you can customize this based on your requirements)
    banking_details := json_build_object(
        'bank_name', 'Standard Bank',
        'account_name', 'Choice Lux Cars (Pty) Ltd',
        'account_number', '1234567890',
        'branch_code', '051001',
        'swift_code', 'SBZAZAJJ',
        'reference', 'INV-' || p_job_id
    );

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
        'number_passengers', COALESCE(job_record.number_passengers, 0),
        'luggage', COALESCE(job_record.luggage, 'Not specified'),
        'driver_name', COALESCE(job_record.driver_name, 'Not assigned'),
        'driver_contact', COALESCE(job_record.driver_contact, 'Not available'),
        'vehicle_type', COALESCE(job_record.vehicle_type, 'Not assigned'),
        'transport', COALESCE(transport_data, '[]'::json),
        'notes', COALESCE(job_record.notes, ''),
        'invoice_number', 'INV-' || p_job_id,
        'invoice_date', CURRENT_DATE,
        'due_date', CURRENT_DATE + INTERVAL '30 days',
        'subtotal', COALESCE(job_record.subtotal, 0),
        'tax_amount', COALESCE(job_record.tax_amount, 0),
        'total_amount', COALESCE(job_record.total_amount, 0),
        'currency', 'ZAR',
        'payment_terms', 'Payment due within 30 days',
        'banking_details', banking_details
    );

    RETURN result;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_invoice_data_for_pdf(int) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_invoice_data_for_pdf(int) IS 'Fetches complete invoice data for PDF generation including job details, client info, agent details, passenger info, driver/vehicle info, transport details, and banking information';

-- 2. Add invoice_pdf column to jobs table if it doesn't exist
DO $$
BEGIN
    -- Check if invoice_pdf column exists, if not add it
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'invoice_pdf'
    ) THEN
        ALTER TABLE jobs ADD COLUMN invoice_pdf text;
        
        -- Add comment for documentation
        COMMENT ON COLUMN jobs.invoice_pdf IS 'URL to the generated invoice PDF file stored in Supabase Storage';
    END IF;
END $$;

-- Add index for better query performance when filtering by invoice_pdf
CREATE INDEX IF NOT EXISTS idx_jobs_invoice_pdf ON jobs(invoice_pdf) WHERE invoice_pdf IS NOT NULL;
