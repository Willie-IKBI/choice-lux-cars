-- Production Database Schema Update for Driver Flow
-- Run this script in Supabase Dashboard SQL Editor
-- This will add all the missing columns and functions needed for the driver flow

-- 1. Add missing columns to jobs table
DO $$
BEGIN
    -- Add job_number column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'job_number'
    ) THEN
        ALTER TABLE jobs ADD COLUMN job_number TEXT UNIQUE;
        RAISE NOTICE 'Added job_number column to jobs table';
    END IF;
    
    -- Add pax column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'pax'
    ) THEN
        ALTER TABLE jobs ADD COLUMN pax NUMERIC DEFAULT 1;
        RAISE NOTICE 'Added pax column to jobs table';
    END IF;
    
    -- Add other missing columns
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'client_id'
    ) THEN
        ALTER TABLE jobs ADD COLUMN client_id BIGINT;
        RAISE NOTICE 'Added client_id column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'vehicle_id'
    ) THEN
        ALTER TABLE jobs ADD COLUMN vehicle_id BIGINT;
        RAISE NOTICE 'Added vehicle_id column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'agent_id'
    ) THEN
        ALTER TABLE jobs ADD COLUMN agent_id BIGINT;
        RAISE NOTICE 'Added agent_id column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'order_date'
    ) THEN
        ALTER TABLE jobs ADD COLUMN order_date DATE NOT NULL DEFAULT CURRENT_DATE;
        RAISE NOTICE 'Added order_date column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'amount'
    ) THEN
        ALTER TABLE jobs ADD COLUMN amount NUMERIC;
        RAISE NOTICE 'Added amount column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'amount_collect'
    ) THEN
        ALTER TABLE jobs ADD COLUMN amount_collect BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added amount_collect column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'passenger_name'
    ) THEN
        ALTER TABLE jobs ADD COLUMN passenger_name TEXT;
        RAISE NOTICE 'Added passenger_name column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'passenger_contact'
    ) THEN
        ALTER TABLE jobs ADD COLUMN passenger_contact TEXT;
        RAISE NOTICE 'Added passenger_contact column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'number_bags'
    ) THEN
        ALTER TABLE jobs ADD COLUMN number_bags TEXT;
        RAISE NOTICE 'Added number_bags column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'job_start_date'
    ) THEN
        ALTER TABLE jobs ADD COLUMN job_start_date DATE NOT NULL DEFAULT CURRENT_DATE;
        RAISE NOTICE 'Added job_start_date column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'notes'
    ) THEN
        ALTER TABLE jobs ADD COLUMN notes TEXT;
        RAISE NOTICE 'Added notes column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'quote_no'
    ) THEN
        ALTER TABLE jobs ADD COLUMN quote_no BIGINT;
        RAISE NOTICE 'Added quote_no column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'voucher_pdf'
    ) THEN
        ALTER TABLE jobs ADD COLUMN voucher_pdf TEXT;
        RAISE NOTICE 'Added voucher_pdf column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'cancel_reason'
    ) THEN
        ALTER TABLE jobs ADD COLUMN cancel_reason TEXT;
        RAISE NOTICE 'Added cancel_reason column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'location'
    ) THEN
        ALTER TABLE jobs ADD COLUMN location TEXT;
        RAISE NOTICE 'Added location column to jobs table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'jobs' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE jobs ADD COLUMN created_by TEXT;
        RAISE NOTICE 'Added created_by column to jobs table';
    END IF;
END $$;

-- 2. Add missing columns to profiles table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'display_name'
    ) THEN
        ALTER TABLE profiles ADD COLUMN display_name TEXT;
        RAISE NOTICE 'Added display_name column to profiles table';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'profiles' 
        AND column_name = 'number'
    ) THEN
        ALTER TABLE profiles ADD COLUMN number TEXT;
        RAISE NOTICE 'Added number column to profiles table';
    END IF;
END $$;

-- 3. Add missing columns to notifications table
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'notifications' 
        AND column_name = 'is_hidden'
    ) THEN
        ALTER TABLE notifications ADD COLUMN is_hidden BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'Added is_hidden column to notifications table';
    END IF;
END $$;

-- 4. Create job status enum if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'job_status_enum') THEN
        CREATE TYPE job_status_enum AS ENUM (
            'assigned',      -- Job assigned to driver
            'started',       -- Driver started the job
            'in_progress',   -- Vehicle collected, trips in progress
            'ready_to_close', -- All trips completed, ready for vehicle return
            'completed',     -- Job fully completed
            'cancelled'      -- Job cancelled
        );
        RAISE NOTICE 'Created job_status_enum type';
    END IF;
END $$;

-- 5. Create notification type enum if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'notification_type_enum') THEN
        CREATE TYPE notification_type_enum AS ENUM (
            'job_assignment',
            'job_started',
            'passenger_onboard',
            'job_completed',
            'job_stalled',
            'driver_inactive'
        );
        RAISE NOTICE 'Created notification_type_enum type';
    END IF;
END $$;

-- 6. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_jobs_job_number ON jobs(job_number);
CREATE INDEX IF NOT EXISTS idx_jobs_pax ON jobs(pax);
CREATE INDEX IF NOT EXISTS idx_jobs_client_id ON jobs(client_id);
CREATE INDEX IF NOT EXISTS idx_jobs_vehicle_id ON jobs(vehicle_id);
CREATE INDEX IF NOT EXISTS idx_jobs_agent_id ON jobs(agent_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_hidden ON notifications(is_hidden);

-- 7. Update existing job records to have job_number if they don't have one
UPDATE jobs 
SET job_number = 'JOB-' || id::text 
WHERE job_number IS NULL;

-- 8. Update existing job records to have pax if they don't have one
UPDATE jobs 
SET pax = 1 
WHERE pax IS NULL;

-- 9. Update existing job records to have order_date if they don't have one
UPDATE jobs 
SET order_date = created_at::date 
WHERE order_date IS NULL;

-- 10. Update existing job records to have job_start_date if they don't have one
UPDATE jobs 
SET job_start_date = created_at::date 
WHERE job_start_date IS NULL;

-- Success message
SELECT 'Production database schema updated successfully!' as status;
