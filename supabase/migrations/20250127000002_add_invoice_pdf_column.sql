-- Add invoice_pdf column to jobs table
-- This column stores the URL to the generated invoice PDF

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
