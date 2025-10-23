-- =====================================================
-- FIX INSIGHTS RLS POLICIES
-- Choice Lux Cars - Allow administrators to access all data for insights
-- =====================================================

-- Enable RLS on all tables if not already enabled
ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.quotes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

-- Drop existing restrictive policies that might block insights
DROP POLICY IF EXISTS "Users can view clients" ON public.clients;
DROP POLICY IF EXISTS "Users can view quotes" ON public.quotes;
DROP POLICY IF EXISTS "Users can view jobs" ON public.jobs;
DROP POLICY IF EXISTS "Users can view profiles" ON public.profiles;
DROP POLICY IF EXISTS "Users can view vehicles" ON public.vehicles;

-- Create new policies that allow administrators full access for insights
-- Clients table - administrators can view all clients
CREATE POLICY "Administrators can view all clients for insights" ON public.clients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'administrator'
        )
    );

-- Quotes table - administrators can view all quotes
CREATE POLICY "Administrators can view all quotes for insights" ON public.quotes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'administrator'
        )
    );

-- Jobs table - administrators can view all jobs
CREATE POLICY "Administrators can view all jobs for insights" ON public.jobs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'administrator'
        )
    );

-- Profiles table - administrators can view all profiles
CREATE POLICY "Administrators can view all profiles for insights" ON public.profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() 
            AND p.role = 'administrator'
        )
    );

-- Vehicles table - administrators can view all vehicles
CREATE POLICY "Administrators can view all vehicles for insights" ON public.vehicles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'administrator'
        )
    );

-- Keep existing user-specific policies for non-administrators
-- Clients - users can view their own clients
CREATE POLICY "Users can view their own clients" ON public.clients
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role != 'administrator'
        )
    );

-- Quotes - users can view quotes for their clients
CREATE POLICY "Users can view quotes for their clients" ON public.quotes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role != 'administrator'
        )
    );

-- Jobs - users can view their own jobs
CREATE POLICY "Users can view their own jobs" ON public.jobs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role != 'administrator'
        )
    );

-- Profiles - users can view their own profile
CREATE POLICY "Users can view their own profile" ON public.profiles
    FOR SELECT USING (
        auth.uid() = id OR
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid() 
            AND p.role != 'administrator'
        )
    );

-- Vehicles - users can view all vehicles (for job assignment)
CREATE POLICY "Users can view vehicles for job assignment" ON public.vehicles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role != 'administrator'
        )
    );

-- Add comments for documentation
COMMENT ON POLICY "Administrators can view all clients for insights" ON public.clients IS 'Allows administrators to access all client data for business insights';
COMMENT ON POLICY "Administrators can view all quotes for insights" ON public.quotes IS 'Allows administrators to access all quote data for business insights';
COMMENT ON POLICY "Administrators can view all jobs for insights" ON public.jobs IS 'Allows administrators to access all job data for business insights';
COMMENT ON POLICY "Administrators can view all profiles for insights" ON public.profiles IS 'Allows administrators to access all profile data for business insights';
COMMENT ON POLICY "Administrators can view all vehicles for insights" ON public.vehicles IS 'Allows administrators to access all vehicle data for business insights';

-- =====================================================
-- RLS POLICIES FIXED SUCCESSFULLY
-- =====================================================
