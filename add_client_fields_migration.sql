-- Migration script to add new fields to clients table
-- Fields: website_address, company_registration_number, vat_number

-- Add new columns to clients table
ALTER TABLE public.clients 
ADD COLUMN website_address text NULL,
ADD COLUMN company_registration_number text NULL,
ADD COLUMN vat_number text NULL;

-- Add comments for documentation
COMMENT ON COLUMN public.clients.website_address IS 'Client company website URL';
COMMENT ON COLUMN public.clients.company_registration_number IS 'Company registration number (CIPC/Companies House)';
COMMENT ON COLUMN public.clients.vat_number IS 'VAT registration number';

-- Create indexes for better query performance (optional)
CREATE INDEX IF NOT EXISTS idx_clients_website_address ON public.clients USING btree (website_address) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_clients_company_registration_number ON public.clients USING btree (company_registration_number) TABLESPACE pg_default;
CREATE INDEX IF NOT EXISTS idx_clients_vat_number ON public.clients USING btree (vat_number) TABLESPACE pg_default;

-- Verify the changes
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND column_name IN ('website_address', 'company_registration_number', 'vat_number');
