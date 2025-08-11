-- Create helper RPC function to get voucher_id from job_id
-- In this system, vouchers are essentially jobs, so voucher_id = job_id

CREATE OR REPLACE FUNCTION get_voucher_id_for_job(p_job_id int)
RETURNS int
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Check if job exists and user has access
    IF NOT EXISTS (
        SELECT 1 FROM jobs j
        JOIN clients c ON j.client_id = c.id
        WHERE j.id = p_job_id
        AND c.status = 'active'
    ) THEN
        RAISE EXCEPTION 'Access denied: Job not found or client inactive';
    END IF;

    -- In this system, voucher_id is the same as job_id
    RETURN p_job_id;
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION get_voucher_id_for_job(int) TO authenticated;

-- Add comment for documentation
COMMENT ON FUNCTION get_voucher_id_for_job(int) IS 'Returns voucher_id for a given job_id. In this system, voucher_id equals job_id.';

-- Also create a convenience function that directly gets voucher data by job_id
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

-- Add comment for documentation
COMMENT ON FUNCTION get_voucher_data_for_job(int) IS 'Convenience function to get voucher data directly by job_id';
