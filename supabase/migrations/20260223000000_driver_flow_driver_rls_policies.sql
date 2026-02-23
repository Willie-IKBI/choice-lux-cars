-- Add driver (and manager) SELECT/UPDATE/INSERT policies for driver_flow
-- so drivers can read and update their own job progress; admin policy remains.
-- Use (select auth.uid()) for initplan consistency (see 20260208000001).

-- driver_flow: SELECT for driver, manager, and admin
CREATE POLICY driver_flow_driver_select ON public.driver_flow
  FOR SELECT TO authenticated
  USING (
    (EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = driver_flow.job_id
      AND ((jobs.driver_id = (select auth.uid())) OR (jobs.manager_id = (select auth.uid())))
    ))
    OR (EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (select auth.uid())
      AND p.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
  );

-- driver_flow: UPDATE for driver (own job) and admin
CREATE POLICY driver_flow_driver_update ON public.driver_flow
  FOR UPDATE TO authenticated
  USING (
    (EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = driver_flow.job_id AND jobs.driver_id = (select auth.uid())
    ))
    OR (EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (select auth.uid())
      AND p.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
  )
  WITH CHECK (
    (EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = driver_flow.job_id AND jobs.driver_id = (select auth.uid())
    ))
    OR (EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (select auth.uid())
      AND p.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
  );

-- driver_flow: INSERT for driver (startJob upsert) and admin
CREATE POLICY driver_flow_driver_insert ON public.driver_flow
  FOR INSERT TO authenticated
  WITH CHECK (
    (EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = driver_flow.job_id AND jobs.driver_id = (select auth.uid())
    ))
    OR (EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (select auth.uid())
      AND p.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
  );
