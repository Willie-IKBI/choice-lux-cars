-- Ensure voucher_pdf column exists in jobs table
-- This column stores the URL to the generated voucher PDF

DO $$
BEGIN
    -- Check if voucher_pdf column exists, if not add it
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'voucher_pdf'
    ) THEN
        ALTER TABLE jobs ADD COLUMN voucher_pdf text;
        
        -- Add comment for documentation
        COMMENT ON COLUMN jobs.voucher_pdf IS 'URL to the generated voucher PDF file stored in Supabase Storage';
    END IF;
END $$;

-- Add index for better query performance when filtering by voucher_pdf
CREATE INDEX IF NOT EXISTS idx_jobs_voucher_pdf ON jobs(voucher_pdf) WHERE voucher_pdf IS NOT NULL;
