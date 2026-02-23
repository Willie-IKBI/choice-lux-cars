-- Allow driver (and admin) to insert trip_progress rows when starting a job (so map can receive GPS later)
DROP POLICY IF EXISTS trip_progress_insert_policy ON public.trip_progress;
CREATE POLICY trip_progress_insert_policy ON public.trip_progress
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = trip_progress.job_id AND jobs.driver_id = (SELECT auth.uid())
    )
    OR EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = (SELECT auth.uid())
      AND profiles.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    )
  );
