# Job Start Escalation Rules and Tests

**Date:** 2025-01-22  
**Status:** Audit Complete - Rules and Test Plan Ready  
**Objective:** Define exact escalation rules, idempotency strategy, and comprehensive test plan for job start deadline notifications.

---

## Executive Summary

**Current State:**
- ✅ RPC function `get_jobs_needing_start_deadline_notifications` exists
- ✅ Edge function `check-job-start-deadlines` exists and is deployed
- ⚠️ **Current thresholds:** 90min (manager) and 30min (administrator)
- ⚠️ **Required thresholds:** 90min (manager) and 60min (administrator/super_admin)
- ⚠️ **Manager scoping bug:** Queries all managers globally, not just `jobs.manager_id`
- ✅ **Deduplication:** Implemented (checks existing notifications by job_id + notification_type)
- ✅ **Admin global scope:** Recipient selection already global (no branch_id filter)

**Key Rules:**
1. **T-90 minutes:** Notify assigned manager ONLY if job not started
2. **T-60 minutes:** Notify ALL active admins/super_admins globally if job still not started
3. **Idempotency:** One notification per job + threshold + recipient (dedupe by job_id + notification_type)
4. **Started at 75 minutes:** Manager may have received 90-min warning, but admin/super_admin must NOT receive 60-min escalation

---

## 1. Exact Escalation Rules

### 1.1 Rule 1: T-90 Minutes (Manager Warning)

**Trigger Condition:**
- Job has `driver_id IS NOT NULL` (assigned to driver)
- Job has `manager_id IS NOT NULL` (assigned to manager)
- `driver_flow.job_started_at IS NULL` (job not started)
- `jobs.job_status NOT IN ('cancelled', 'completed', 'declined')`
- Earliest `transport.pickup_date` is between 85-90 minutes from current time (SA timezone)

**Recipient:**
- **ONLY** `jobs.manager_id` for that specific job
- ⚠️ **Current Bug:** Edge function queries ALL managers globally (incorrect)

**Notification Type:**
- `'job_start_deadline_warning_90min'`

**Message:**
- `"Warning job# {job_number} has not started with the driver {driver_name || 'assigned'}"`

**Priority:**
- `'high'`

**Action Data:**
```json
{
  "route": "/jobs/{job_id}/summary",
  "job_id": "{job_id}",
  "job_number": "{job_number}",
  "driver_name": "{driver_name}",
  "minutes_before_pickup": 90
}
```

---

### 1.2 Rule 2: T-60 Minutes (Admin/Super_Admin Escalation)

**Trigger Condition:**
- Job has `driver_id IS NOT NULL` (assigned to driver)
- `driver_flow.job_started_at IS NULL` (job not started)
- `jobs.job_status NOT IN ('cancelled', 'completed', 'declined')`
- Earliest `transport.pickup_date` is between 55-60 minutes from current time (SA timezone)
- ⚠️ **Current Implementation:** Uses 25-30 minutes (needs update to 55-60 minutes)

**Recipients:**
- **ALL** active administrators (`role = 'administrator'`)
- **ALL** active super_admins (`role = 'super_admin'`)
- ✅ **NO branch_id filter** - Global scope (national)
- ✅ **Current Implementation:** Already global (correct)

**Notification Type:**
- `'job_start_deadline_warning_60min'` (currently `'job_start_deadline_warning_30min'`)

**Message:**
- `"Warning job# {job_number} has not started with the driver {driver_name || 'assigned'}"`

**Priority:**
- `'high'`

**Action Data:**
```json
{
  "route": "/jobs/{job_id}/summary",
  "job_id": "{job_id}",
  "job_number": "{job_number}",
  "driver_name": "{driver_name}",
  "minutes_before_pickup": 60
}
```

---

### 1.3 Rule 3: Job Started Before Threshold

**Scenario: "Started at 75 minutes"**

**Timeline:**
- T-90 minutes: Job not started → Manager receives 90-min warning ✅
- T-75 minutes: Driver starts job → `driver_flow.job_started_at = NOW()` ✅
- T-60 minutes: Job already started → Admin/super_admin must NOT receive 60-min escalation ❌

**Enforcement:**
- RPC function checks: `driver_flow.job_started_at IS NULL`
- If job started before T-60, RPC function will NOT return the job for 60-min threshold
- Edge function will NOT create notifications for jobs that don't appear in RPC result

**Conclusion:** ✅ **CORRECT** - RPC function enforces "not started" check

---

### 1.4 Rule 4: Idempotency

**Requirement:**
- One notification per job + threshold + recipient
- No duplicate notifications if cron runs multiple times

**Current Implementation:**
- **Location:** `supabase/functions/check-job-start-deadlines/index.ts` (Lines 70-87)
- **Logic:**
  ```typescript
  // Check if notification already sent (deduplication)
  const { data: existingNotification } = await supabase
    .from('app_notifications')
    .select('id')
    .eq('job_id', job_id.toString())
    .eq('notification_type', notification_type)
    .maybeSingle()
  
  if (existingNotification) {
    console.log(`Notification already sent for job ${job_id} (${notification_type}), skipping`)
    continue
  }
  ```

**Event Key:**
- `job_id + notification_type` (unique per job per threshold)

**Analysis:**
- ✅ **Correct for:** Single recipient per job (manager at 90-min)
- ⚠️ **Issue for:** Multiple recipients per job (admins at 60-min)
  - Current dedupe checks if ANY notification exists for job_id + notification_type
  - If one admin already received notification, all other admins are skipped
  - **This is a bug** - should dedupe per recipient

**Required Fix:**
- Dedupe should check: `job_id + notification_type + user_id`
- Or: Create notification per recipient, then check per recipient

**Current Behavior:**
- First cron run: Creates notifications for all admins ✅
- Second cron run: Skips all admins (existing notification found) ❌
- **Result:** Works correctly (no duplicates), but logic is imprecise

**Conclusion:** ⚠️ **WORKS BUT IMPRECISE** - Should dedupe per recipient, not per job

---

## 2. Timeline Examples

### Example 1: Normal Escalation Flow

**Job Setup:**
- Job ID: 1001
- Manager ID: `manager-uuid-1`
- Driver ID: `driver-uuid-1`
- Pickup Date: `2026-01-22 14:00:00` (SA time)
- Job Status: `'assigned'`
- `driver_flow.job_started_at`: `NULL`

**Timeline (SA Time):**

| Time | Minutes Before Pickup | Action | Result |
|------|----------------------|--------|--------|
| 12:30 | 90 minutes | Cron runs | ✅ Manager receives 90-min warning |
| 12:35 | 85 minutes | Cron runs | ❌ Outside window (no notification) |
| 13:00 | 60 minutes | Cron runs | ✅ All admins/super_admins receive 60-min escalation |
| 13:05 | 55 minutes | Cron runs | ❌ Outside window (no notification) |
| 13:30 | 30 minutes | Cron runs | ❌ Job not started, but outside 60-min window (no notification) |
| 13:45 | 15 minutes | Driver starts job | `driver_flow.job_started_at = 13:45` |
| 14:00 | 0 minutes | Pickup time | Job started, no further notifications |

**Notifications Created:**
1. `job_start_deadline_warning_90min` → `manager-uuid-1` (at 12:30)
2. `job_start_deadline_warning_60min` → All active admins/super_admins (at 13:00)

**Verification:**
```sql
SELECT 
  an.id,
  an.user_id,
  an.notification_type,
  an.job_id,
  an.created_at,
  p.role
FROM public.app_notifications an
INNER JOIN public.profiles p ON an.user_id = p.id
WHERE an.job_id = '1001'
AND an.notification_type LIKE '%deadline%'
ORDER BY an.created_at;
```

**Expected:**
- 1 notification for manager (90-min)
- N notifications for admins/super_admins (60-min, where N = number of active admins)

---

### Example 2: Started at 75 Minutes

**Job Setup:**
- Job ID: 1002
- Manager ID: `manager-uuid-2`
- Driver ID: `driver-uuid-2`
- Pickup Date: `2026-01-22 14:00:00` (SA time)
- Job Status: `'assigned'`
- `driver_flow.job_started_at`: `NULL` initially

**Timeline (SA Time):**

| Time | Minutes Before Pickup | Action | Result |
|------|----------------------|--------|--------|
| 12:30 | 90 minutes | Cron runs | ✅ Manager receives 90-min warning |
| 12:45 | 75 minutes | Driver starts job | `driver_flow.job_started_at = 12:45` |
| 13:00 | 60 minutes | Cron runs | ❌ Job already started → NO admin escalation |

**Notifications Created:**
1. `job_start_deadline_warning_90min` → `manager-uuid-2` (at 12:30)
2. ❌ **NO** `job_start_deadline_warning_60min` notifications (job started before T-60)

**Verification:**
```sql
SELECT 
  an.id,
  an.user_id,
  an.notification_type,
  an.job_id,
  an.created_at
FROM public.app_notifications an
WHERE an.job_id = '1002'
AND an.notification_type LIKE '%deadline%'
ORDER BY an.created_at;
```

**Expected:**
- 1 notification for manager (90-min)
- 0 notifications for admins/super_admins (job started before T-60)

**RPC Function Check:**
```sql
-- At 13:00 (T-60), RPC should NOT return job 1002 because:
-- driver_flow.job_started_at IS NOT NULL (job started at 12:45)
SELECT *
FROM public.get_jobs_needing_start_deadline_notifications('2026-01-22 11:00:00+00'::timestamptz);
-- Expected: job_id = 1002 should NOT appear in result
```

---

### Example 3: Multiple Cron Runs (Idempotency)

**Job Setup:**
- Job ID: 1003
- Manager ID: `manager-uuid-3`
- Pickup Date: `2026-01-22 14:00:00` (SA time)
- Job Status: `'assigned'`
- `driver_flow.job_started_at`: `NULL`

**Timeline (SA Time):**

| Time | Minutes Before Pickup | Action | Result |
|------|----------------------|--------|--------|
| 12:30 | 90 minutes | Cron runs (1st) | ✅ Manager receives 90-min warning |
| 12:31 | 89 minutes | Cron runs (2nd) | ❌ Notification exists → Skipped (idempotent) |
| 12:32 | 88 minutes | Cron runs (3rd) | ❌ Notification exists → Skipped (idempotent) |
| 13:00 | 60 minutes | Cron runs (1st) | ✅ All admins receive 60-min escalation |
| 13:01 | 59 minutes | Cron runs (2nd) | ❌ Notification exists → Skipped (idempotent) |

**Notifications Created:**
1. `job_start_deadline_warning_90min` → `manager-uuid-3` (at 12:30, first cron run only)
2. `job_start_deadline_warning_60min` → All active admins/super_admins (at 13:00, first cron run only)

**Verification:**
```sql
-- Check for duplicates
SELECT 
  an.job_id,
  an.notification_type,
  COUNT(*) as notification_count,
  COUNT(DISTINCT an.user_id) as unique_recipients
FROM public.app_notifications an
WHERE an.job_id = '1003'
AND an.notification_type LIKE '%deadline%'
GROUP BY an.job_id, an.notification_type;
```

**Expected:**
- `job_start_deadline_warning_90min`: 1 notification (1 unique recipient = manager)
- `job_start_deadline_warning_60min`: N notifications (N unique recipients = all admins, no duplicates)

---

## 3. Idempotency Strategy

### 3.1 Current Implementation

**Location:** `supabase/functions/check-job-start-deadlines/index.ts` (Lines 70-87)

**Logic:**
```typescript
// Check if notification already sent (deduplication)
const { data: existingNotification } = await supabase
  .from('app_notifications')
  .select('id')
  .eq('job_id', job_id.toString())
  .eq('notification_type', notification_type)
  .maybeSingle()

if (existingNotification) {
  // Skip - already sent
  continue
}
```

**Event Key:** `job_id + notification_type`

**Analysis:**
- ✅ **Works for:** Preventing duplicate notifications per job per threshold
- ⚠️ **Issue:** Checks if ANY notification exists, not per recipient
- ⚠️ **Impact:** If one admin received notification, all other admins are skipped on subsequent runs

**Current Behavior:**
- **First cron run:** Creates notifications for all recipients ✅
- **Subsequent cron runs:** Skips all recipients (existing notification found) ✅
- **Result:** No duplicates, but logic is imprecise

---

### 3.2 Recommended Improvement

**Per-Recipient Deduplication:**

**Option A: Check Per Recipient (Recommended)**
```typescript
// For each recipient, check if they already received this notification
for (const recipient of recipients) {
  const { data: existingNotification } = await supabase
    .from('app_notifications')
    .select('id')
    .eq('job_id', job_id.toString())
    .eq('notification_type', notification_type)
    .eq('user_id', recipient.id)  // ← Check per recipient
    .maybeSingle()
  
  if (existingNotification) {
    console.log(`Notification already sent to user ${recipient.id} for job ${job_id}, skipping`)
    continue
  }
  
  // Create notification for this recipient
  await createNotification(recipient.id, ...)
}
```

**Pros:**
- ✅ Precise deduplication per recipient
- ✅ Handles edge cases (e.g., new admin added after first run)
- ✅ More accurate logging

**Cons:**
- ⚠️ More database queries (one per recipient)
- ⚠️ Slightly more complex logic

**Recommendation:** ✅ **Implement Option A** - More precise and handles edge cases

---

**Option B: Timestamp-Based Deduplication**

**Approach:**
- Add `jobs.escalation_notified_90min_at` and `jobs.escalation_notified_60min_at` columns
- Update these columns when notifications are sent
- Check columns instead of querying `app_notifications`

**Pros:**
- ✅ Faster lookup (no query needed)
- ✅ Clear audit trail on jobs table

**Cons:**
- ❌ Doesn't track per-recipient notifications
- ❌ Doesn't handle new admins added after first run
- ❌ Requires schema migration

**Recommendation:** ❌ **NOT RECOMMENDED** - Less flexible, doesn't handle per-recipient cases

---

### 3.3 Current Strategy Summary

**Status:** ✅ **WORKS** - Prevents duplicates correctly

**Limitation:** ⚠️ Logic is imprecise (checks per job, not per recipient)

**Recommendation:** Improve to per-recipient deduplication (Option A) for precision and edge case handling

---

## 4. Test Plan

### 4.1 Test 1: Manager 90-Minute Warning (Job-Scoped)

**Setup:**
- Create job with:
  - `driver_id = 'driver-uuid-1'`
  - `manager_id = 'manager-uuid-1'`
  - `pickup_date = NOW() + 90 minutes` (earliest transport pickup)
  - `driver_flow.job_started_at = NULL`
  - `job_status = 'assigned'`

**Steps:**
1. Wait for cron to run (or invoke edge function manually at T-90)
2. Check `app_notifications`:
   ```sql
   SELECT 
     an.id,
     an.user_id,
     an.notification_type,
     an.job_id,
     p.role
   FROM public.app_notifications an
   INNER JOIN public.profiles p ON an.user_id = p.id
   WHERE an.job_id = '<job_id>'
   AND an.notification_type = 'job_start_deadline_warning_90min';
   ```
3. Verify push notification sent (check `notification_delivery_log`)

**Expected:**
- ✅ **ONLY** `manager-uuid-1` receives notification
- ✅ Notification type = `'job_start_deadline_warning_90min'`
- ✅ Push notification sent (if preferences enabled)
- ✅ In-app notification appears for manager
- ❌ **Other managers do NOT receive notification**

**Current Bug:**
- ⚠️ Edge function queries ALL managers globally
- ⚠️ **Expected:** Only `jobs.manager_id` should receive notification

---

### 4.2 Test 2: Admin 60-Minute Escalation (Global)

**Setup:**
- Create job with:
  - `driver_id = 'driver-uuid-2'`
  - `pickup_date = NOW() + 60 minutes`
  - `driver_flow.job_started_at = NULL`
  - `job_status = 'assigned'`
- Ensure at least 2 active administrators exist
- Ensure at least 1 active super_admin exists

**Steps:**
1. Wait for cron to run (or invoke edge function manually at T-60)
2. Check `app_notifications`:
   ```sql
   SELECT 
     an.id,
     an.user_id,
     an.notification_type,
     an.job_id,
     p.role,
     p.branch_id
   FROM public.app_notifications an
   INNER JOIN public.profiles p ON an.user_id = p.id
   WHERE an.job_id = '<job_id>'
   AND an.notification_type = 'job_start_deadline_warning_60min'
   ORDER BY p.role, p.branch_id;
   ```
3. Verify push notifications sent

**Expected:**
- ✅ **ALL** active administrators receive notification (regardless of branch_id)
- ✅ **ALL** active super_admins receive notification (regardless of branch_id)
- ✅ Notification type = `'job_start_deadline_warning_60min'`
- ✅ Push notifications sent (if preferences enabled)
- ✅ In-app notifications appear for all admins

**Verification:**
- Count should equal: `COUNT(active administrators) + COUNT(active super_admins)`
- All recipients should have `role IN ('administrator', 'super_admin')`
- Branch_id values may vary (global scope)

---

### 4.3 Test 3: Started at 75 Minutes (No Admin Escalation)

**Setup:**
- Create job with:
  - `driver_id = 'driver-uuid-3'`
  - `manager_id = 'manager-uuid-3'`
  - `pickup_date = NOW() + 90 minutes`
  - `driver_flow.job_started_at = NULL`
  - `job_status = 'assigned'`

**Steps:**
1. Wait for cron to run at T-90 → Manager receives 90-min warning ✅
2. Manually set `driver_flow.job_started_at = NOW()` (simulate driver starting at T-75)
3. Wait for cron to run at T-60
4. Check `app_notifications`:
   ```sql
   SELECT 
     an.id,
     an.user_id,
     an.notification_type,
     an.job_id,
     an.created_at
   FROM public.app_notifications an
   WHERE an.job_id = '<job_id>'
   AND an.notification_type LIKE '%deadline%'
   ORDER BY an.created_at;
   ```

**Expected:**
- ✅ Manager receives 90-min warning (at T-90)
- ❌ **NO** admin/super_admin receives 60-min escalation (job started before T-60)
- ✅ Only 1 notification exists (manager's 90-min warning)

**RPC Function Verification:**
```sql
-- At T-60, RPC should NOT return this job
SELECT *
FROM public.get_jobs_needing_start_deadline_notifications(NOW());
-- Expected: job_id should NOT appear in result (job_started_at IS NOT NULL)
```

---

### 4.4 Test 4: Idempotency (Multiple Cron Runs)

**Setup:**
- Create job with:
  - `driver_id = 'driver-uuid-4'`
  - `manager_id = 'manager-uuid-4'`
  - `pickup_date = NOW() + 90 minutes`
  - `driver_flow.job_started_at = NULL`

**Steps:**
1. Invoke edge function manually at T-90 (first run)
2. Check notifications created
3. Invoke edge function manually again at T-90 (second run, 1 minute later)
4. Check notifications created
5. Repeat for T-60 escalation

**Expected:**
- ✅ First run: Creates notifications for all recipients
- ✅ Second run: Skips all recipients (existing notifications found)
- ✅ No duplicate notifications created

**Verification:**
```sql
-- Check for duplicates
SELECT 
  an.job_id,
  an.notification_type,
  an.user_id,
  COUNT(*) as duplicate_count
FROM public.app_notifications an
WHERE an.job_id = '<job_id>'
AND an.notification_type LIKE '%deadline%'
GROUP BY an.job_id, an.notification_type, an.user_id
HAVING COUNT(*) > 1;
-- Expected: 0 rows (no duplicates)
```

---

### 4.5 Test 5: Time Window Boundaries

**Setup:**
- Create multiple jobs with pickup dates at different times:
  - Job A: `pickup_date = NOW() + 91 minutes` (just outside 90-min window)
  - Job B: `pickup_date = NOW() + 89 minutes` (just inside 90-min window)
  - Job C: `pickup_date = NOW() + 61 minutes` (just outside 60-min window)
  - Job D: `pickup_date = NOW() + 59 minutes` (just inside 60-min window)

**Steps:**
1. Invoke edge function manually
2. Check which jobs trigger notifications

**Expected:**
- ❌ Job A: No notification (outside 85-90min window)
- ✅ Job B: Manager receives 90-min warning (inside 85-90min window)
- ❌ Job C: No notification (outside 55-60min window)
- ✅ Job D: All admins receive 60-min escalation (inside 55-60min window)

**Verification:**
```sql
SELECT 
  j.id as job_id,
  j.job_number,
  MIN(t.pickup_date) as pickup_date,
  EXTRACT(EPOCH FROM (MIN(t.pickup_date)::timestamp with time zone - (NOW() + INTERVAL '2 hours'))) / 60 as minutes_until_pickup
FROM public.jobs j
LEFT JOIN public.transport t ON j.id = t.job_id
WHERE j.id IN (<job_ids>)
GROUP BY j.id, j.job_number;
```

---

### 4.6 Test 6: Branch Independence (Admin Global Scope)

**Setup:**
- Create job with `branch_id = 1`
- Ensure admin A has `branch_id = 1`
- Ensure admin B has `branch_id = 2` (different branch)
- Ensure admin C has `branch_id = NULL` (no branch)
- Create job with `pickup_date = NOW() + 60 minutes`

**Steps:**
1. Invoke edge function manually at T-60
2. Check notifications for all three admins

**Expected:**
- ✅ Admin A receives notification (same branch as job, but global scope)
- ✅ Admin B receives notification (different branch, but global scope)
- ✅ Admin C receives notification (no branch, global scope)
- ✅ All admins receive notifications regardless of branch_id

**Verification:**
```sql
SELECT 
  an.user_id,
  an.notification_type,
  p.role,
  p.branch_id,
  j.branch_id as job_branch_id
FROM public.app_notifications an
INNER JOIN public.profiles p ON an.user_id = p.id
INNER JOIN public.jobs j ON an.job_id::bigint = j.id
WHERE an.job_id = '<job_id>'
AND an.notification_type = 'job_start_deadline_warning_60min'
ORDER BY p.branch_id;
```

---

## 5. SQL Verification Queries

### 5.1 Verify Jobs Needing Notifications

```sql
-- Test RPC function with current time
SELECT *
FROM public.get_jobs_needing_start_deadline_notifications(NOW())
ORDER BY pickup_date ASC;
```

**Expected Output:**
- Jobs within 85-90 minutes: `recipient_role = 'manager'`, `notification_type = 'job_start_deadline_warning_90min'`
- Jobs within 55-60 minutes: `recipient_role = 'administrator'`, `notification_type = 'job_start_deadline_warning_60min'` (after update)
- Jobs outside windows: Not returned
- Jobs already started: Not returned

---

### 5.2 Verify Notification Creation

```sql
-- Check recent escalation notifications
SELECT 
  an.id,
  an.user_id,
  an.notification_type,
  an.job_id,
  an.created_at,
  p.role,
  p.branch_id,
  j.manager_id,
  j.branch_id as job_branch_id
FROM public.app_notifications an
INNER JOIN public.profiles p ON an.user_id = p.id
LEFT JOIN public.jobs j ON an.job_id::bigint = j.id
WHERE an.notification_type IN (
  'job_start_deadline_warning_90min',
  'job_start_deadline_warning_60min',
  'job_start_deadline_warning_30min'
)
AND an.created_at > NOW() - INTERVAL '7 days'
ORDER BY an.created_at DESC
LIMIT 50;
```

**Expected:**
- 90-min notifications: `p.role = 'manager'` AND `p.id = j.manager_id`
- 60-min notifications: `p.role IN ('administrator', 'super_admin')` (all active, regardless of branch_id)

---

### 5.3 Verify Deduplication

```sql
-- Check for duplicate notifications (same job + type + user)
SELECT 
  an.job_id,
  an.notification_type,
  an.user_id,
  COUNT(*) as duplicate_count,
  MIN(an.created_at) as first_created,
  MAX(an.created_at) as last_created
FROM public.app_notifications an
WHERE an.notification_type IN (
  'job_start_deadline_warning_90min',
  'job_start_deadline_warning_60min',
  'job_start_deadline_warning_30min'
)
GROUP BY an.job_id, an.notification_type, an.user_id
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;
```

**Expected:**
- 0 rows (no duplicates per job + type + user)

---

### 5.4 Verify Manager Scoping

```sql
-- Check if managers receive notifications for jobs they don't manage
SELECT 
  an.id,
  an.job_id,
  an.user_id as notified_manager_id,
  j.manager_id as job_manager_id,
  CASE 
    WHEN an.user_id = j.manager_id THEN 'CORRECT'
    ELSE 'ERROR: Wrong manager notified'
  END as scoping_status
FROM public.app_notifications an
INNER JOIN public.jobs j ON an.job_id::bigint = j.id
WHERE an.notification_type = 'job_start_deadline_warning_90min'
AND an.created_at > NOW() - INTERVAL '7 days';
```

**Expected:**
- All rows should have `scoping_status = 'CORRECT'`
- If any row has `scoping_status = 'ERROR'`, manager scoping bug exists

---

### 5.5 Verify Admin Global Scope

```sql
-- Check admin notifications across different branches
SELECT 
  an.job_id,
  an.notification_type,
  COUNT(DISTINCT an.user_id) as unique_admin_recipients,
  COUNT(DISTINCT p.branch_id) as unique_branches,
  STRING_AGG(DISTINCT p.branch_id::text, ', ') as branch_ids
FROM public.app_notifications an
INNER JOIN public.profiles p ON an.user_id = p.id
WHERE an.notification_type = 'job_start_deadline_warning_60min'
AND p.role IN ('administrator', 'super_admin')
AND an.created_at > NOW() - INTERVAL '7 days'
GROUP BY an.job_id, an.notification_type;
```

**Expected:**
- `unique_admin_recipients` = Total active admins/super_admins
- `unique_branches` = Number of branches with active admins (or NULL if admins have no branch)
- All active admins receive notifications regardless of branch_id

---

### 5.6 Verify "Started at 75 Minutes" Rule

```sql
-- Find jobs that received 90-min warning but NOT 60-min escalation
-- (indicating job started between T-90 and T-60)
WITH jobs_with_90min_warning AS (
  SELECT DISTINCT job_id
  FROM public.app_notifications
  WHERE notification_type = 'job_start_deadline_warning_90min'
  AND created_at > NOW() - INTERVAL '7 days'
),
jobs_with_60min_escalation AS (
  SELECT DISTINCT job_id
  FROM public.app_notifications
  WHERE notification_type IN ('job_start_deadline_warning_60min', 'job_start_deadline_warning_30min')
  AND created_at > NOW() - INTERVAL '7 days'
)
SELECT 
  j.id as job_id,
  j.job_number,
  df.job_started_at,
  CASE 
    WHEN df.job_started_at IS NOT NULL THEN 'Job started (correct: no 60-min escalation)'
    ELSE 'ERROR: Job not started but no 60-min escalation'
  END as status
FROM jobs_with_90min_warning j90
INNER JOIN public.jobs j ON j90.job_id::bigint = j.id
LEFT JOIN public.driver_flow df ON j.id = df.job_id
LEFT JOIN jobs_with_60min_escalation j60 ON j90.job_id = j60.job_id
WHERE j60.job_id IS NULL  -- No 60-min escalation
ORDER BY df.job_started_at DESC;
```

**Expected:**
- All jobs should have `job_started_at IS NOT NULL` (job started before T-60)
- If any job has `job_started_at IS NULL`, it's an error (should have received 60-min escalation)

---

## 6. Observability Plan

### 6.1 Delivery Logs

**Table:** `public.notification_delivery_log`

**Columns:**
- `notification_id` (uuid, FK to app_notifications.id)
- `user_id` (uuid)
- `fcm_token` (text, nullable)
- `fcm_response` (jsonb, nullable)
- `sent_at` (timestamptz)
- `success` (boolean)
- `error_message` (text, nullable)
- `retry_count` (integer)

**Queries:**

**A) Escalation Notification Delivery Rate:**
```sql
SELECT 
  an.notification_type,
  COUNT(DISTINCT an.id) as notifications_created,
  COUNT(DISTINCT ndl.notification_id) as delivery_attempts,
  COUNT(CASE WHEN ndl.success = true THEN 1 END) as successful_deliveries,
  COUNT(CASE WHEN ndl.success = false THEN 1 END) as failed_deliveries,
  ROUND(100.0 * COUNT(CASE WHEN ndl.success = true THEN 1 END) / NULLIF(COUNT(DISTINCT ndl.notification_id), 0), 2) as success_rate_pct
FROM public.app_notifications an
LEFT JOIN public.notification_delivery_log ndl ON an.id = ndl.notification_id
WHERE an.notification_type IN (
  'job_start_deadline_warning_90min',
  'job_start_deadline_warning_60min',
  'job_start_deadline_warning_30min'
)
AND an.created_at > NOW() - INTERVAL '7 days'
GROUP BY an.notification_type;
```

**B) Failed Delivery Analysis:**
```sql
SELECT 
  an.notification_type,
  ndl.error_message,
  COUNT(*) as failure_count
FROM public.notification_delivery_log ndl
INNER JOIN public.app_notifications an ON ndl.notification_id = an.id
WHERE ndl.success = false
AND an.notification_type IN (
  'job_start_deadline_warning_90min',
  'job_start_deadline_warning_60min',
  'job_start_deadline_warning_30min'
)
AND ndl.sent_at > NOW() - INTERVAL '7 days'
GROUP BY an.notification_type, ndl.error_message
ORDER BY failure_count DESC;
```

---

### 6.2 Error Logging

**Edge Function Logs:**
- **Location:** Supabase Dashboard → Edge Functions → `check-job-start-deadlines` → Logs
- **Key Events:**
  - Jobs checked count
  - Notifications created count
  - Errors encountered
  - Deduplication skips

**Key Log Messages:**
- `"Found X jobs needing deadline notifications"`
- `"Processing job Y: notification_type for recipient_role"`
- `"Notification already sent for job Y, skipping"`
- `"Successfully notified X recipient_role users for job Y"`
- `"Error processing job Y: error_message"`

**Monitoring:**
- Check logs after each cron run
- Alert on high error rates
- Track delivery success rates

---

### 6.3 Metrics Dashboard (Future)

**Recommended Metrics:**
1. **Escalation Rate:**
   - Jobs triggering 90-min warnings (per day/week)
   - Jobs triggering 60-min escalations (per day/week)
   - Jobs started before escalation (prevention rate)

2. **Delivery Rate:**
   - Push notification success rate (per notification type)
   - In-app notification delivery (always 100% if RLS allows)

3. **Response Time:**
   - Average time from escalation to job start
   - Average time from escalation to manager/admin action

4. **Recipient Coverage:**
   - Managers with active tokens (90-min warnings)
   - Admins with active tokens (60-min escalations)
   - Token refresh rates

---

## 7. Implementation Checklist

### Pre-Implementation
- [ ] Review current RPC function thresholds (90min, 30min)
- [ ] Verify manager scoping bug (queries all managers vs job.manager_id)
- [ ] Test current deduplication logic
- [ ] Document current behavior vs expected behavior

### Phase 1: Update Thresholds
- [ ] Update RPC function: Change 30min → 60min
- [ ] Update notification type: `job_start_deadline_warning_30min` → `job_start_deadline_warning_60min`
- [ ] Update Flutter constants: `NotificationConstants.jobStartDeadlineWarning30min` → `60min`
- [ ] Update UI preferences screen: Display 60min instead of 30min

### Phase 2: Fix Manager Scoping
- [ ] Update RPC function: Return `manager_id` in result set for 90-min threshold
- [ ] Update edge function: Filter by `jobs.manager_id` for manager role
- [ ] Test manager receives notification only for their assigned jobs

### Phase 3: Improve Deduplication
- [ ] Update edge function: Check deduplication per recipient (job_id + notification_type + user_id)
- [ ] Test idempotency with multiple cron runs
- [ ] Test edge case: New admin added after first run

### Phase 4: Testing
- [ ] Run all test scenarios (Test 1-6)
- [ ] Verify SQL queries return expected results
- [ ] Check delivery logs for success rates
- [ ] Monitor edge function logs for errors

### Phase 5: Observability
- [ ] Set up delivery log queries (automated or manual)
- [ ] Document monitoring procedures
- [ ] Create alert thresholds (if applicable)

---

## 8. Summary

### Current State
- ✅ RPC function exists and works
- ✅ Edge function exists and is deployed
- ✅ Deduplication implemented (works but imprecise)
- ✅ Admin recipient selection is global (correct)
- ⚠️ Threshold mismatch: 30min vs required 60min
- ⚠️ Manager scoping bug: Queries all managers globally

### Required Changes
1. **Update 30min → 60min:** RPC function, notification type, Flutter constants, UI
2. **Fix manager scoping:** Filter by `jobs.manager_id` for 90-min warnings
3. **Improve deduplication:** Check per recipient (optional but recommended)

### Test Coverage
- ✅ Manager 90-min warning (job-scoped)
- ✅ Admin 60-min escalation (global)
- ✅ "Started at 75 minutes" rule (no admin escalation)
- ✅ Idempotency (multiple cron runs)
- ✅ Time window boundaries
- ✅ Branch independence (admin global scope)

---

**End of Escalation Rules and Tests Document**

