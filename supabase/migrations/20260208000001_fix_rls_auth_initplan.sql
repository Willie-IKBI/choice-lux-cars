-- Fix RLS Auth InitPlan: Wrap auth.uid() in (select auth.uid()) so it is evaluated once per query
-- instead of per row. Affected tables: profiles, driver_flow, expenses, expense_audit_log,
-- trip_progress, app_notifications, jobs.
-- See: https://supabase.com/docs/guides/database/database-linter

-- app_notifications
DROP POLICY IF EXISTS allow_select_recent_inserts ON public.app_notifications;
CREATE POLICY allow_select_recent_inserts ON public.app_notifications
  FOR SELECT TO authenticated
  USING ((user_id = (select auth.uid())) OR (created_at > (now() - '00:01:00'::interval)));

DROP POLICY IF EXISTS allow_users_update_own ON public.app_notifications;
CREATE POLICY allow_users_update_own ON public.app_notifications
  FOR UPDATE TO authenticated
  USING (user_id = (select auth.uid()))
  WITH CHECK (user_id = (select auth.uid()));

DROP POLICY IF EXISTS allow_users_view_own ON public.app_notifications;
CREATE POLICY allow_users_view_own ON public.app_notifications
  FOR SELECT TO authenticated
  USING (user_id = (select auth.uid()));

-- driver_flow
DROP POLICY IF EXISTS driver_flow_admin_update ON public.driver_flow;
CREATE POLICY driver_flow_admin_update ON public.driver_flow
  FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = (select auth.uid())
    AND p.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = (select auth.uid())
    AND p.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
  ));

-- expense_audit_log
DROP POLICY IF EXISTS expense_audit_log_select_policy ON public.expense_audit_log;
CREATE POLICY expense_audit_log_select_policy ON public.expense_audit_log
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM profiles
    WHERE profiles.id = (select auth.uid())
    AND profiles.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
  ));

-- expenses
DROP POLICY IF EXISTS expenses_delete_policy ON public.expenses;
CREATE POLICY expenses_delete_policy ON public.expenses
  FOR DELETE TO authenticated
  USING (
    (driver_id = (select auth.uid()) AND approved_by IS NULL
    AND EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = expenses.job_id AND jobs.driver_id = (select auth.uid())
    ))
  );

DROP POLICY IF EXISTS expenses_insert_policy ON public.expenses;
CREATE POLICY expenses_insert_policy ON public.expenses
  FOR INSERT TO authenticated
  WITH CHECK (
    (driver_id = (select auth.uid())
    AND EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = expenses.job_id AND jobs.driver_id = (select auth.uid())
    ))
  );

DROP POLICY IF EXISTS expenses_select_policy ON public.expenses;
CREATE POLICY expenses_select_policy ON public.expenses
  FOR SELECT TO authenticated
  USING (
    (EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = expenses.job_id
      AND ((jobs.driver_id = (select auth.uid())) OR (jobs.manager_id = (select auth.uid())))
    ))
    OR (EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = (select auth.uid())
      AND profiles.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
  );

DROP POLICY IF EXISTS expenses_update_policy ON public.expenses;
CREATE POLICY expenses_update_policy ON public.expenses
  FOR UPDATE TO authenticated
  USING (
    (driver_id = (select auth.uid()) AND approved_by IS NULL
    AND EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = expenses.job_id AND jobs.driver_id = (select auth.uid())
    ))
  )
  WITH CHECK (
    (driver_id = (select auth.uid()) AND approved_by IS NULL
    AND EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = expenses.job_id AND jobs.driver_id = (select auth.uid())
    ))
  );

-- jobs
DROP POLICY IF EXISTS jobs_select_policy ON public.jobs;
CREATE POLICY jobs_select_policy ON public.jobs
  FOR SELECT TO authenticated
  USING (
    (EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = (select auth.uid())
      AND profiles.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
    OR (EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = (select auth.uid())
      AND profiles.role = 'manager'::user_role_enum
    ))
    OR ((driver_id = (select auth.uid()) AND EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = (select auth.uid())
      AND profiles.role = 'driver'::user_role_enum
    )))
    OR ((EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = (select auth.uid())
      AND profiles.role = 'driver_manager'::user_role_enum
    )) AND (
      created_by = ((select auth.uid())::text)
      OR driver_id = (select auth.uid())
    ))
  );

DROP POLICY IF EXISTS jobs_update_policy ON public.jobs;
CREATE POLICY jobs_update_policy ON public.jobs
  FOR UPDATE TO authenticated
  USING (
    (EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (select auth.uid())
      AND p.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
    OR (driver_id = (select auth.uid()))
  )
  WITH CHECK (
    (EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (select auth.uid())
      AND p.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
    OR (driver_id = (select auth.uid()))
  );

-- profiles
DROP POLICY IF EXISTS profiles_update_consolidated ON public.profiles;
CREATE POLICY profiles_update_consolidated ON public.profiles
  FOR UPDATE TO authenticated
  USING (((select auth.uid()) = id) OR is_admin_or_super_admin())
  WITH CHECK (((select auth.uid()) = id) OR is_admin_or_super_admin());

-- trip_progress
DROP POLICY IF EXISTS trip_progress_select_policy ON public.trip_progress;
CREATE POLICY trip_progress_select_policy ON public.trip_progress
  FOR SELECT TO authenticated
  USING (
    (EXISTS (
      SELECT 1 FROM jobs
      WHERE jobs.id = trip_progress.job_id
      AND ((jobs.driver_id = (select auth.uid())) OR (jobs.manager_id = (select auth.uid())))
    ))
    OR (EXISTS (
      SELECT 1 FROM profiles
      WHERE profiles.id = (select auth.uid())
      AND profiles.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
  );

DROP POLICY IF EXISTS trip_progress_update_policy ON public.trip_progress;
CREATE POLICY trip_progress_update_policy ON public.trip_progress
  FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM jobs
    WHERE jobs.id = trip_progress.job_id AND jobs.driver_id = (select auth.uid())
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM jobs
    WHERE jobs.id = trip_progress.job_id AND jobs.driver_id = (select auth.uid())
  ));
