-- Driver trip ratings: per-trip 0-5 score for driver effectiveness.
-- Used for "last 10 trips" average on user card and driver insights.

BEGIN;

CREATE TABLE IF NOT EXISTS public.driver_trip_ratings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  job_id bigint NOT NULL,
  trip_index int NOT NULL,
  score numeric(3,2) NOT NULL CHECK (score >= 0 AND score <= 5),
  vehicle_fetch_score numeric(3,2),
  dropoff_ontime_score numeric(3,2),
  flow_complete_score numeric(3,2),
  confirmation_score numeric(3,2),
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (driver_id, job_id, trip_index)
);

COMMENT ON TABLE public.driver_trip_ratings IS 'Per-trip driver effectiveness score (0-5). Average of last 10 shown on user card and driver insights.';

CREATE INDEX IF NOT EXISTS idx_driver_trip_ratings_driver_created
  ON public.driver_trip_ratings (driver_id, created_at DESC);

ALTER TABLE public.driver_trip_ratings ENABLE ROW LEVEL SECURITY;

-- SELECT: driver can see own rows; admin/super_admin can see all
CREATE POLICY driver_trip_ratings_select ON public.driver_trip_ratings
  FOR SELECT TO authenticated
  USING (
    (driver_id = (SELECT auth.uid()))
    OR (EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (SELECT auth.uid())
      AND p.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
  );

-- INSERT: driver can insert for their own job (after close); admin can insert any
CREATE POLICY driver_trip_ratings_insert ON public.driver_trip_ratings
  FOR INSERT TO authenticated
  WITH CHECK (
    (EXISTS (
      SELECT 1 FROM jobs j
      WHERE j.id = job_id AND j.driver_id = (SELECT auth.uid())
    ))
    OR (EXISTS (
      SELECT 1 FROM profiles p
      WHERE p.id = (SELECT auth.uid())
      AND p.role = ANY (ARRAY['administrator'::user_role_enum, 'super_admin'::user_role_enum])
    ))
  );

COMMIT;
