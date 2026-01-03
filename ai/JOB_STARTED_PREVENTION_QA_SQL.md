# Job Started Prevention - QA SQL Steps

**Date:** 2026-01-04  
**Purpose:** Repeatable SQL steps to verify that started jobs do not generate deadline notifications

---

## Test Setup

### Step 1: Identify or Create Test Job

```sql
-- Find a job with driver, manager, transport, and not started
SELECT 
  j.id as job_id,
  j.driver_id,
  j.manager_id,
  j.job_status,
  df.job_id as driver_flow_exists,
  df.job_started_at,
  MIN(t.pickup_date) as earliest_pickup
FROM public.jobs j
LEFT JOIN public.driver_flow df ON j.id = df.job_id
LEFT JOIN public.transport t ON j.id = t.job_id
WHERE j.driver_id IS NOT NULL
AND j.manager_id IS NOT NULL
AND j.job_status NOT IN ('cancelled', 'completed', 'declined')
GROUP BY j.id, j.driver_id, j.manager_id, j.job_status, df.job_id, df.job_started_at
HAVING COUNT(t.id) > 0
ORDER BY j.id DESC
LIMIT 1;
```

**Expected:** Job with `driver_flow_exists IS NULL` or `job_started_at IS NULL`

---

### Step 2: Set Pickup Date to T-90 Window

```sql
-- Update earliest transport pickup_date to be 87 minutes from now (SA time)
-- Replace <job_id> and <transport_id> with actual values from Step 1
UPDATE public.transport
SET pickup_date = ((NOW() AT TIME ZONE 'UTC' + INTERVAL '2 hours') + INTERVAL '87 minutes')::timestamp without time zone
WHERE id = (
  SELECT id FROM public.transport 
  WHERE job_id = <job_id> 
  ORDER BY pickup_date ASC 
  LIMIT 1
)
RETURNING id, job_id, pickup_date;
```

**Expected:** Pickup date updated to ~87 minutes from current SA time

---

### Step 3: Verify RPC Returns Job (Before Starting)

```sql
-- Verify job is returned by RPC (not started yet)
SELECT 
  job_id,
  minutes_before,
  notification_type,
  recipient_role
FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
)
WHERE job_id = <job_id>;
```

**Expected:** 
- 1 row returned
- `minutes_before = 90`
- `notification_type = 'job_start_deadline_warning_90min'`
- `recipient_role = 'manager'`

---

### Step 4: Ensure driver_flow Row Exists

```sql
-- Check if driver_flow row exists for the job
SELECT job_id, job_started_at
FROM public.driver_flow
WHERE job_id = <job_id>;

-- If row doesn't exist, create it (without job_started_at)
INSERT INTO public.driver_flow (job_id, driver_user, current_step, progress_percentage)
SELECT 
  <job_id>,
  j.driver_id,
  'vehicle_collection',
  0
FROM public.jobs j
WHERE j.id = <job_id>
AND NOT EXISTS (SELECT 1 FROM public.driver_flow WHERE job_id = <job_id>)
RETURNING job_id, job_started_at;
```

**Expected:** 
- Row exists (created if missing)
- `job_started_at IS NULL`

---

### Step 5: Start the Job

```sql
-- Set job_started_at to mark job as started
UPDATE public.driver_flow
SET job_started_at = NOW()
WHERE job_id = <job_id>
RETURNING job_id, job_started_at;
```

**Expected:**
- 1 row updated
- `job_started_at IS NOT NULL` (current timestamp)

---

### Step 6: Verify RPC No Longer Returns Job

```sql
-- Verify job is NOT returned by RPC (job started)
SELECT 
  job_id,
  minutes_before,
  notification_type,
  recipient_role
FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
)
WHERE job_id = <job_id>;
```

**Expected:** 
- 0 rows returned (empty result set)
- Job excluded because `job_started_at IS NOT NULL`

---

### Step 7: Adjust Pickup Date to T-60 Window

```sql
-- Update pickup_date to T-60 window to test escalation prevention
UPDATE public.transport
SET pickup_date = ((NOW() AT TIME ZONE 'UTC' + INTERVAL '2 hours') + INTERVAL '57 minutes')::timestamp without time zone
WHERE id = (
  SELECT id FROM public.transport 
  WHERE job_id = <job_id> 
  ORDER BY pickup_date ASC 
  LIMIT 1
)
RETURNING id, job_id, pickup_date;
```

**Expected:** Pickup date updated to ~57 minutes from current SA time

---

### Step 8: Verify RPC Still Does Not Return Job

```sql
-- Verify job is still NOT returned (even in T-60 window)
SELECT 
  job_id,
  minutes_before,
  notification_type,
  recipient_role
FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
)
WHERE job_id = <job_id>;
```

**Expected:**
- 0 rows returned
- Job excluded from both T-90 and T-60 windows because `job_started_at IS NOT NULL`

---

### Step 9: Verify No Notifications Created

```sql
-- Check that no deadline notifications exist for this job
SELECT 
  id,
  user_id,
  job_id,
  notification_type,
  created_at
FROM public.app_notifications
WHERE job_id = '<job_id>'
AND notification_type IN ('job_start_deadline_warning_90min', 'job_start_deadline_warning_60min')
ORDER BY created_at DESC;
```

**Expected:**
- 0 rows returned (no notifications created)
- Job starting prevents all deadline notifications

---

## Complete Test Script (All Steps Combined)

```sql
-- ============================================
-- Complete Job Started Prevention Test
-- ============================================

-- Step 1: Create temp table and find test job
CREATE TEMP TABLE tmp_job_started_test (
  job_id bigint,
  driver_id uuid,
  manager_id uuid,
  transport_id bigint
);

INSERT INTO tmp_job_started_test (job_id, driver_id, manager_id, transport_id)
SELECT 
  j.id as job_id,
  j.driver_id,
  j.manager_id,
  MIN(t.id) as transport_id
FROM public.jobs j
INNER JOIN public.transport t ON j.id = t.job_id
WHERE j.driver_id IS NOT NULL
AND j.manager_id IS NOT NULL
AND j.job_status NOT IN ('cancelled', 'completed', 'declined')
AND NOT EXISTS (
  SELECT 1 FROM public.driver_flow df 
  WHERE df.job_id = j.id AND df.job_started_at IS NOT NULL
)
GROUP BY j.id, j.driver_id, j.manager_id
LIMIT 1;

-- Sanity check: Verify temp table has data
SELECT 
  job_id,
  driver_id,
  manager_id,
  transport_id
FROM tmp_job_started_test;

-- Step 2: Set pickup to T-90 window
UPDATE public.transport
SET pickup_date = ((NOW() AT TIME ZONE 'UTC' + INTERVAL '2 hours') + INTERVAL '87 minutes')::timestamp without time zone
WHERE id IN (SELECT transport_id FROM tmp_job_started_test)
RETURNING id, job_id, pickup_date;

-- Step 3: Verify RPC returns job (before starting)
SELECT 
  job_id,
  minutes_before,
  notification_type,
  recipient_role
FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
)
WHERE job_id IN (SELECT job_id FROM tmp_job_started_test);

-- Expected: 1 row with minutes_before = 90, notification_type = 'job_start_deadline_warning_90min'

-- Step 4: Ensure driver_flow row exists
INSERT INTO public.driver_flow (job_id, driver_user, current_step, progress_percentage)
SELECT 
  job_id,
  driver_id,
  'vehicle_collection',
  0
FROM tmp_job_started_test
WHERE NOT EXISTS (SELECT 1 FROM public.driver_flow WHERE job_id = tmp_job_started_test.job_id)
RETURNING job_id, job_started_at;

-- Step 5: Start the job
UPDATE public.driver_flow
SET job_started_at = NOW()
WHERE job_id IN (SELECT job_id FROM tmp_job_started_test)
RETURNING job_id, job_started_at;

-- Step 6: Verify RPC no longer returns job
SELECT 
  job_id,
  minutes_before,
  notification_type,
  recipient_role
FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
)
WHERE job_id IN (SELECT job_id FROM tmp_job_started_test);

-- Expected: 0 rows (job excluded because job_started_at IS NOT NULL)

-- Step 7: Adjust pickup date to T-60 window
UPDATE public.transport
SET pickup_date = ((NOW() AT TIME ZONE 'UTC' + INTERVAL '2 hours') + INTERVAL '57 minutes')::timestamp without time zone
WHERE id IN (SELECT transport_id FROM tmp_job_started_test)
RETURNING id, job_id, pickup_date;

-- Step 8: Verify RPC still does not return job (even in T-60 window)
SELECT 
  job_id,
  minutes_before,
  notification_type,
  recipient_role
FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
)
WHERE job_id IN (SELECT job_id FROM tmp_job_started_test);

-- Expected: 0 rows (job excluded from both T-90 and T-60 windows)

-- Cleanup: Drop temp table (optional, will be dropped automatically at session end)
DROP TABLE IF EXISTS tmp_job_started_test;
```

---

## Behavior Summary

**Option A (Implemented):** Treat missing `driver_flow` row as "not started yet"

**Logic:**
- `LEFT JOIN public.driver_flow df ON j.id = df.job_id`
- Filter: `AND (df.job_started_at IS NULL)`
- **Result:**
  - If `driver_flow` row doesn't exist → `df.job_started_at IS NULL` → **INCLUDED** (not started)
  - If `driver_flow` row exists but `job_started_at IS NULL` → **INCLUDED** (not started)
  - If `driver_flow` row exists and `job_started_at IS NOT NULL` → **EXCLUDED** (started)

**Rationale:**
- Safer approach: prevents false negatives (missing notifications for jobs that haven't started)
- `driver_flow` row is created when job starts, so missing row = not started
- If row exists but `job_started_at` is NULL, job hasn't started yet

---

## Edge Function Logging

The Edge Function now includes a comment noting that:
- RPC already filters by `job_started_at IS NULL`
- Jobs returned by RPC are guaranteed to be not started
- If a job has started, it won't be in `jobsNeedingNotifications`

**No additional logging needed** - the RPC filtering is sufficient and explicit.

---

**End of QA SQL Steps**

