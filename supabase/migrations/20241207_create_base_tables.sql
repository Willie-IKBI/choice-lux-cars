-- Create base tables for the application
-- This migration should run before other migrations that reference these tables

-- Create profiles table (if not exists)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    display_name TEXT,
    number TEXT,
    role TEXT DEFAULT 'driver' CHECK (role IN ('driver', 'manager', 'administrator')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create jobs table (if not exists)
CREATE TABLE IF NOT EXISTS jobs (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_number TEXT UNIQUE NOT NULL,
    client_id BIGINT,
    vehicle_id BIGINT,
    agent_id BIGINT,
    driver_id UUID REFERENCES profiles(id),
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    job_status TEXT DEFAULT 'assigned',
    amount NUMERIC,
    amount_collect BOOLEAN DEFAULT FALSE,
    passenger_name TEXT,
    passenger_contact TEXT,
    pax NUMERIC DEFAULT 1,
    number_bags TEXT,
    job_start_date DATE NOT NULL,
    notes TEXT,
    quote_no BIGINT,
    voucher_pdf TEXT,
    cancel_reason TEXT,
    location TEXT,
    created_by TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    driver_confirm_ind BOOLEAN DEFAULT FALSE,
    is_confirmed BOOLEAN DEFAULT FALSE,
    confirmed_at TIMESTAMP WITH TIME ZONE,
    confirmed_by UUID REFERENCES auth.users(id)
);

-- Create driver_flow table (if not exists)
CREATE TABLE IF NOT EXISTS driver_flow (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_id BIGINT REFERENCES jobs(id) ON DELETE CASCADE,
    driver_user UUID REFERENCES profiles(id),
    vehicle_collected BOOLEAN DEFAULT FALSE,
    vehicle_time TIMESTAMP WITH TIME ZONE,
    pdp_start_image TEXT,
    odo_start_reading NUMERIC(10,2),
    pickup_loc TEXT,
    pickup_arriver_time TIMESTAMP WITH TIME ZONE,
    pickup_ind BOOLEAN DEFAULT FALSE,
    payment_collected_ind BOOLEAN DEFAULT FALSE,
    transport_completed_ind BOOLEAN DEFAULT FALSE,
    job_closed_odo NUMERIC(10,2),
    job_closed_odo_img TEXT,
    job_closed_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create notifications table (if not exists)
CREATE TABLE IF NOT EXISTS notifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    job_id BIGINT REFERENCES jobs(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    notification_type VARCHAR(50) DEFAULT 'job_assignment',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_jobs_driver_id ON jobs(driver_id);
CREATE INDEX IF NOT EXISTS idx_jobs_status ON jobs(job_status);
CREATE INDEX IF NOT EXISTS idx_driver_flow_job_id ON driver_flow(job_id);
CREATE INDEX IF NOT EXISTS idx_driver_flow_user ON driver_flow(driver_user);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);

-- Enable Row Level Security
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE driver_flow ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can view jobs they are assigned to" ON jobs
    FOR SELECT USING (auth.uid() = driver_id);

-- Allow all operations for testing (temporary)
CREATE POLICY "Allow all operations for testing" ON profiles
    FOR ALL USING (true);

CREATE POLICY "Allow all operations for testing" ON jobs
    FOR ALL USING (true);

CREATE POLICY "Allow all operations for testing" ON driver_flow
    FOR ALL USING (true);

CREATE POLICY "Allow all operations for testing" ON notifications
    FOR ALL USING (true);
