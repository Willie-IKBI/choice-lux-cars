# Job Deadline Notification QA Checklist

**Date:** 2026-01-04  
**Purpose:** Validation queries and test steps for job start deadline notification fixes

---

## Pre-Test Setup

### 1. Verify Migration Applied

```sql
-- Check function signature includes manager_id
SELECT 
  proname as function_name,
  pg_get_function_result(oid) as return_type
FROM pg_proc
WHERE proname = 'get_jobs_needing_start_deadline_notifications';

-- Expected: return_type should include "manager_id uuid"
```

### 2. Verify Function Returns Correct Thresholds

```sql
-- Test with a mock time that would trigger 60min window
-- Adjust the test time to match your test scenario
SELECT * FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
);

-- Check that:
-- - minutes_before is either 90 or 60 (not 30)
-- - notification_type is either 'job_start_deadline_warning_90min' or 'job_start_deadline_warning_60min' (not 30min)
-- - manager_id is included in results
```

---

## Test Case 1: Manager Notification (T-90) - Correct Scoping

### Setup
```sql
-- Create or identify a test job:
-- - Has driver_id
-- - Has manager_id
-- - Has transport with pickup_date = NOW() + 87 minutes (SA time)
-- - driver_flow.job_started_at IS NULL
-- - job_status NOT IN ('cancelled', 'completed', 'declined')

-- Example: Find existing job or create test data
SELECT 
  j.id,
  j.job_number,
  j.driver_id,
  j.manager_id,
  j.job_status,
  df.job_started_at,
  MIN(t.pickup_date) as earliest_pickup
FROM public.jobs j
LEFT JOIN public.driver_flow df ON j.id = df.job_id
LEFT JOIN public.transport t ON j.id = t.job_id
WHERE j.driver_id IS NOT NULL
AND j.manager_id IS NOT NULL
AND df.job_started_at IS NULL
AND j.job_status NOT IN ('cancelled', 'completed', 'declined')
GROUP BY j.id, j.job_number, j.driver_id, j.manager_id, j.job_status, df.job_started_at
LIMIT 1;
```

### Validation Query
```sql
-- Simulate RPC call at T-87 minutes (within 85-90 window)
-- Replace <job_id> and <pickup_time> with actual values
-- pickup_time should be 87 minutes from current SA time
SELECT * FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
)
WHERE job_id = <job_id>;

-- Expected:
-- - minutes_before = 90
-- - notification_type = 'job_start_deadline_warning_90min'
-- - recipient_role = 'manager'
-- - manager_id = <expected_manager_id>
```

### Edge Function Test
```sql
-- After Edge Function runs, verify notification created:
SELECT 
  an.id,
  an.user_id,
  an.job_id,
  an.notification_type,
  an.message,
  p.role,
  p.display_name,
  j.manager_id
FROM public.app_notifications an
INNER JOIN public.profiles p ON an.user_id = p.id
INNER JOIN public.jobs j ON an.job_id::bigint = j.id
WHERE an.job_id = '<job_id>'
AND an.notification_type = 'job_start_deadline_warning_90min'
ORDER BY an.created_at DESC
LIMIT 5;

-- Expected:
-- - Exactly ONE notification
-- - an.user_id = j.manager_id (only the assigned manager)
-- - p.role = 'manager'
-- - No other managers received notification
```

### Pass Criteria
- [ ] RPC returns job with `minutes_before = 90` and `notification_type = 'job_start_deadline_warning_90min'`
- [ ] RPC returns `manager_id` matching the job's assigned manager
- [ ] Edge Function creates notification ONLY for `jobs.manager_id`
- [ ] No other managers receive notification for this job

---

## Test Case 2: Administrator Escalation (T-60) - Global Scope

### Setup
```sql
-- Create or identify a test job:
-- - Has driver_id
-- - Has transport with pickup_date = NOW() + 57 minutes (SA time)
-- - driver_flow.job_started_at IS NULL
-- - job_status NOT IN ('cancelled', 'completed', 'declined')

-- Verify active administrators/super_admins exist
SELECT id, role, display_name, status
FROM public.profiles
WHERE role IN ('administrator', 'super_admin')
AND status = 'active';
```

### Validation Query
```sql
-- Simulate RPC call at T-57 minutes (within 55-60 window)
SELECT * FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
)
WHERE job_id = <job_id>;

-- Expected:
-- - minutes_before = 60
-- - notification_type = 'job_start_deadline_warning_60min'
-- - recipient_role = 'administrator'
```

### Edge Function Test
```sql
-- After Edge Function runs, verify notifications created:
SELECT 
  an.id,
  an.user_id,
  an.job_id,
  an.notification_type,
  an.message,
  p.role,
  p.display_name
FROM public.app_notifications an
INNER JOIN public.profiles p ON an.user_id = p.id
WHERE an.job_id = '<job_id>'
AND an.notification_type = 'job_start_deadline_warning_60min'
ORDER BY an.created_at DESC;

-- Expected:
-- - One notification per active administrator
-- - One notification per active super_admin
-- - p.role IN ('administrator', 'super_admin')
-- - All active admins/super_admins received notification (global scope)
```

### Pass Criteria
- [ ] RPC returns job with `minutes_before = 60` and `notification_type = 'job_start_deadline_warning_60min'`
- [ ] Edge Function creates notifications for ALL active administrators
- [ ] Edge Function creates notifications for ALL active super_admins
- [ ] No branch_id filtering applied (global scope)

---

## Test Case 3: Job Started Prevents Escalation

### Setup
```sql
-- Create or identify a test job:
-- - Has driver_id
-- - Has transport with pickup_date = NOW() + 87 minutes (SA time)
-- - driver_flow.job_started_at IS NOT NULL (job started)
-- - job_status NOT IN ('cancelled', 'completed', 'declined')
```

### Validation Query
```sql
-- Simulate RPC call - should NOT return started job
SELECT * FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
)
WHERE job_id = <job_id>;

-- Expected:
-- - Zero rows returned (job excluded because job_started_at IS NOT NULL)
```

### Edge Function Test
```sql
-- Verify no notifications created for started job
SELECT COUNT(*) as notification_count
FROM public.app_notifications
WHERE job_id = '<job_id>'
AND notification_type IN ('job_start_deadline_warning_90min', 'job_start_deadline_warning_60min')
AND created_at > NOW() - INTERVAL '1 hour';

-- Expected:
-- - notification_count = 0 (no notifications created)
```

### Pass Criteria
- [ ] RPC does NOT return job with `job_started_at IS NOT NULL`
- [ ] Edge Function does not create notifications for started jobs
- [ ] Both T-90 and T-60 notifications are prevented

---

## Test Case 4: Deduplication Works Across Multiple Runs

### Setup
```sql
-- Use a job from Test Case 1 or 2
-- Ensure notification was created in first run
```

### First Run
```sql
-- Run Edge Function (or simulate)
-- Verify notification created:
SELECT id, job_id, notification_type, created_at
FROM public.app_notifications
WHERE job_id = '<job_id>'
AND notification_type = 'job_start_deadline_warning_90min'
ORDER BY created_at DESC
LIMIT 1;
```

### Second Run (Within Same Window)
```sql
-- Run Edge Function again (within 85-90 minute window)
-- Verify deduplication:
SELECT 
  COUNT(*) as notification_count,
  MIN(created_at) as first_created,
  MAX(created_at) as last_created
FROM public.app_notifications
WHERE job_id = '<job_id>'
AND notification_type = 'job_start_deadline_warning_90min';

-- Expected:
-- - notification_count = 1 (only one notification exists)
-- - first_created = last_created (no new notification created)
```

### Edge Function Log Check
```sql
-- Check Edge Function logs for deduplication message:
-- Expected log: "Notification already sent for job <job_id> (job_start_deadline_warning_90min), skipping"
```

### Pass Criteria
- [ ] First run creates notification
- [ ] Second run (same window) does NOT create duplicate notification
- [ ] Edge Function logs "already sent, skipping" message
- [ ] Only one notification exists per job + notification_type

---

## Test Case 5: Job Starting Between T-90 and T-60

### Setup
```sql
-- Create or identify a test job:
-- - Has driver_id
-- - Has manager_id
-- - Has transport with pickup_date = NOW() + 75 minutes (SA time)
-- - driver_flow.job_started_at IS NULL initially
```

### Step 1: T-90 Window (Job Not Started)
```sql
-- Simulate time at T-87 minutes
-- Run RPC and Edge Function
-- Expected: Manager receives T-90 notification
```

### Step 2: Start Job
```sql
-- Update driver_flow to mark job as started
UPDATE public.driver_flow
SET job_started_at = NOW()
WHERE job_id = <job_id>;
```

### Step 3: T-60 Window (Job Now Started)
```sql
-- Simulate time at T-57 minutes
-- Run RPC and Edge Function
-- Expected: RPC does NOT return job (job_started_at IS NOT NULL)
-- Expected: No administrator notifications created
```

### Validation Query
```sql
-- Verify notifications:
SELECT 
  notification_type,
  COUNT(*) as count,
  MIN(created_at) as first_sent
FROM public.app_notifications
WHERE job_id = '<job_id>'
AND notification_type IN ('job_start_deadline_warning_90min', 'job_start_deadline_warning_60min')
GROUP BY notification_type;

-- Expected:
-- - Only 'job_start_deadline_warning_90min' exists (manager received it)
-- - 'job_start_deadline_warning_60min' does NOT exist (job started before T-60)
```

### Pass Criteria
- [ ] Manager receives T-90 notification when job not started
- [ ] Job starting between T-90 and T-60 prevents T-60 escalation
- [ ] No administrator notifications created after job starts
- [ ] RPC correctly filters out started jobs

---

## Test Case 6: Manager Scoping Verification

### Setup
```sql
-- Create or identify TWO test jobs:
-- - Job A: manager_id = <manager_1_id>
-- - Job B: manager_id = <manager_2_id>
-- - Both in T-90 window (85-90 minutes before pickup)
-- - Both have driver_id and job_started_at IS NULL
```

### Validation Query
```sql
-- Run RPC for both jobs
SELECT 
  job_id,
  job_number,
  manager_id,
  notification_type,
  recipient_role
FROM public.get_jobs_needing_start_deadline_notifications(
  (NOW() AT TIME ZONE 'UTC')::timestamp with time zone
)
WHERE job_id IN (<job_a_id>, <job_b_id>);

-- Expected:
-- - Job A: manager_id = <manager_1_id>
-- - Job B: manager_id = <manager_2_id>
```

### Edge Function Test
```sql
-- After Edge Function runs, verify scoping:
SELECT 
  an.job_id,
  an.user_id,
  an.notification_type,
  j.manager_id,
  p.display_name as recipient_name,
  p.role
FROM public.app_notifications an
INNER JOIN public.jobs j ON an.job_id::bigint = j.id
INNER JOIN public.profiles p ON an.user_id = p.id
WHERE an.job_id IN ('<job_a_id>', '<job_b_id>')
AND an.notification_type = 'job_start_deadline_warning_90min'
ORDER BY an.job_id, an.created_at DESC;

-- Expected:
-- - Job A: Only manager_1 received notification (an.user_id = j.manager_id for Job A)
-- - Job B: Only manager_2 received notification (an.user_id = j.manager_id for Job B)
-- - No cross-contamination (manager_1 did NOT receive Job B notification)
```

### Pass Criteria
- [ ] Each job's notification goes ONLY to its assigned manager
- [ ] Manager 1 does NOT receive Job B notification
- [ ] Manager 2 does NOT receive Job A notification
- [ ] Correct manager receives correct job notification

---

## Test Case 7: Notification Type Consistency

### Validation Query
```sql
-- Check all existing notifications use correct types
SELECT 
  notification_type,
  COUNT(*) as count
FROM public.app_notifications
WHERE notification_type LIKE '%deadline%'
GROUP BY notification_type
ORDER BY notification_type;

-- Expected:
-- - 'job_start_deadline_warning_90min' (exists)
-- - 'job_start_deadline_warning_60min' (exists, new)
-- - 'job_start_deadline_warning_30min' (should NOT exist in new notifications)
```

### Flutter Constants Check
```dart
// Verify lib/core/constants/notification_constants.dart:
// - jobStartDeadlineWarning90min = 'job_start_deadline_warning_90min' ✅
// - jobStartDeadlineWarning60min = 'job_start_deadline_warning_60min' ✅
// - jobStartDeadlineWarning30min should be removed or deprecated
```

### Pass Criteria
- [ ] No new notifications use 'job_start_deadline_warning_30min'
- [ ] All new notifications use 'job_start_deadline_warning_60min'
- [ ] Flutter constants updated to use 60min

---

## Summary Validation Queries

### 1. Verify RPC Function Signature
```sql
SELECT pg_get_function_result(oid) as return_type
FROM pg_proc
WHERE proname = 'get_jobs_needing_start_deadline_notifications';
-- Should include: manager_id uuid
```

### 2. Verify Thresholds in RPC
```sql
-- Check function definition for 60-55 minute window (not 30-25)
SELECT pg_get_functiondef(oid) as function_definition
FROM pg_proc
WHERE proname = 'get_jobs_needing_start_deadline_notifications';
-- Should contain: INTERVAL '60 minutes' and INTERVAL '55 minutes'
-- Should NOT contain: INTERVAL '30 minutes' or INTERVAL '25 minutes'
```

### 3. Verify Edge Function Manager Scoping
```sql
-- Check Edge Function code (manual review):
-- Should query: profiles.id = manager_id AND role = 'manager' AND status = 'active'
-- Should NOT query: all managers globally
```

### 4. Verify Notification Types in Database
```sql
-- Check recent notifications (last 24 hours)
SELECT 
  notification_type,
  COUNT(*) as count,
  MIN(created_at) as first_seen,
  MAX(created_at) as last_seen
FROM public.app_notifications
WHERE notification_type LIKE '%deadline%'
AND created_at > NOW() - INTERVAL '24 hours'
GROUP BY notification_type
ORDER BY notification_type;
```

---

## Manual Test Steps

### 1. Manager Notification Test
1. Create test job with `pickup_date = NOW() + 87 minutes` (SA time)
2. Assign manager to job (`jobs.manager_id`)
3. Ensure `driver_flow.job_started_at IS NULL`
4. Run Edge Function manually or wait for scheduled run
5. Verify: Only assigned manager receives notification
6. Verify: No other managers receive notification

### 2. Administrator Escalation Test
1. Create test job with `pickup_date = NOW() + 57 minutes` (SA time)
2. Ensure `driver_flow.job_started_at IS NULL`
3. Run Edge Function manually or wait for scheduled run
4. Verify: All active administrators receive notification
5. Verify: All active super_admins receive notification
6. Verify: Notification type is 'job_start_deadline_warning_60min'

### 3. Job Started Prevention Test
1. Create test job in T-90 window
2. Start job: `UPDATE driver_flow SET job_started_at = NOW() WHERE job_id = X`
3. Run Edge Function
4. Verify: No notifications created (job excluded from RPC)

### 4. Deduplication Test
1. Create test job in T-90 window
2. Run Edge Function (creates notification)
3. Run Edge Function again immediately (same window)
4. Verify: Only one notification exists (deduplication works)

---

**End of QA Checklist**

