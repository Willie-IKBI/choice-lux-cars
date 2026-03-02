-- Migration: Branch-based RLS policies
-- Date: 2026-03-02
-- Purpose: Update RLS policies for proper branch-based access control
--          - Admin/Super Admin: see all jobs
--          - Manager: see only jobs in their branch
--          - Driver Manager: see jobs they created OR are assigned to
--          - Driver: see only assigned jobs

BEGIN;

-- ============================================
-- JOBS TABLE RLS POLICIES
-- ============================================

-- Drop existing jobs_select_policy
DROP POLICY IF EXISTS jobs_select_policy ON public.jobs;

-- Create new jobs_select_policy with proper branch-based access
CREATE POLICY jobs_select_policy ON public.jobs
FOR SELECT TO authenticated
USING (
    -- Admin/super_admin: see all jobs
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('administrator', 'super_admin')
    )
    OR
    -- Manager: see jobs in their branch only (using branch_id for proper type matching)
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role = 'manager' 
        AND p.branch_id IS NOT NULL 
        AND jobs.branch_id = p.branch_id
    )
    OR
    -- Driver Manager: see jobs they created OR are assigned to
    (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'driver_manager'
        )
        AND (
            created_by = (auth.uid())::text 
            OR driver_id = auth.uid()
        )
    )
    OR
    -- Driver: see only jobs assigned to them
    (
        driver_id = auth.uid() 
        AND EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'driver'
        )
    )
);

COMMENT ON POLICY jobs_select_policy ON public.jobs IS
'Branch-based SELECT policy: admins see all; managers see branch jobs (branch_id match); driver_managers see created/assigned jobs; drivers see assigned jobs only.';

-- ============================================
-- VEHICLES TABLE RLS POLICIES
-- ============================================

-- Drop existing vehicle policies that are too permissive
DROP POLICY IF EXISTS vehicle_details_policy ON public.vehicles;
DROP POLICY IF EXISTS vehicles_select_policy ON public.vehicles;

-- Enable RLS on vehicles if not already enabled
ALTER TABLE public.vehicles ENABLE ROW LEVEL SECURITY;

-- Create branch-based vehicles_select_policy
CREATE POLICY vehicles_select_policy ON public.vehicles
FOR SELECT TO authenticated
USING (
    -- Admin/super_admin: see all vehicles
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('administrator', 'super_admin')
    )
    OR
    -- Manager: see vehicles in their branch only
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role = 'manager' 
        AND p.branch_id IS NOT NULL 
        AND vehicles.branch_id = p.branch_id
    )
    OR
    -- Driver Manager: see vehicles in their branch
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role = 'driver_manager' 
        AND p.branch_id IS NOT NULL 
        AND vehicles.branch_id = p.branch_id
    )
    OR
    -- Driver: see vehicles in their branch (needed for job display)
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role = 'driver' 
        AND p.branch_id IS NOT NULL 
        AND vehicles.branch_id = p.branch_id
    )
);

COMMENT ON POLICY vehicles_select_policy ON public.vehicles IS
'Branch-based SELECT policy: admins see all vehicles; managers/driver_managers/drivers see only vehicles in their branch.';

-- Vehicles INSERT policy (admins only can create vehicles)
CREATE POLICY vehicles_insert_policy ON public.vehicles
FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('administrator', 'super_admin')
    )
);

-- Vehicles UPDATE policy (admins only can update vehicles)
CREATE POLICY vehicles_update_policy ON public.vehicles
FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('administrator', 'super_admin')
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('administrator', 'super_admin')
    )
);

-- Vehicles DELETE policy (admins only can delete vehicles)
CREATE POLICY vehicles_delete_policy ON public.vehicles
FOR DELETE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE profiles.id = auth.uid() 
        AND profiles.role IN ('administrator', 'super_admin')
    )
);

-- ============================================
-- PROFILES TABLE - Add branch-based visibility for drivers
-- ============================================

-- Create a policy for viewing drivers in same branch (for job assignment dropdowns)
DROP POLICY IF EXISTS profiles_branch_drivers_select ON public.profiles;

CREATE POLICY profiles_branch_drivers_select ON public.profiles
FOR SELECT TO authenticated
USING (
    -- Users can always see their own profile
    id = auth.uid()
    OR
    -- Admin/super_admin: see all profiles
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role IN ('administrator', 'super_admin')
    )
    OR
    -- Manager: see profiles in their branch (drivers, driver_managers)
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role = 'manager' 
        AND p.branch_id IS NOT NULL 
        AND profiles.branch_id = p.branch_id
        AND profiles.role IN ('driver', 'driver_manager', 'manager')
    )
    OR
    -- Driver Manager: see drivers in their branch
    EXISTS (
        SELECT 1 FROM public.profiles p 
        WHERE p.id = auth.uid() 
        AND p.role = 'driver_manager' 
        AND p.branch_id IS NOT NULL 
        AND profiles.branch_id = p.branch_id
        AND profiles.role IN ('driver', 'driver_manager')
    )
);

COMMENT ON POLICY profiles_branch_drivers_select ON public.profiles IS
'Branch-based SELECT for profiles: admins see all; managers see branch staff; driver_managers see branch drivers.';

COMMIT;
