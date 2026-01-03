# Job Start Deadline Notification Audit

**Date:** 2026-01-03  
**Status:** Audit Complete  
**Objective:** Comprehensive audit of job start deadline notification logic, thresholds, recipients, and deduplication

---

## Executive Summary

**Edge Function:** `check-job-start-deadlines`  
**RPC Function:** `get_jobs_needing_start_deadline_notifications`  
**Schedule:** Runs every 5 minutes (via GitHub Actions or Supabase cron)

**Current Thresholds:**
- **T-90 minutes:** Manager notification (85-90 minutes before pickup)
- **T-30 minutes:** Administrator notification (25-30 minutes before pickup)

**Key Findings:**
- ✅ Deduplication implemented (checks existing notifications)
- ✅ Job starting prevents escalation (RPC filters by `job_started_at IS NULL`)
- ⚠️ **Manager scoping bug:** Edge Function queries ALL managers globally, not just `jobs.manager_id`
- ⚠️ **Threshold mismatch:** Documentation mentions T-60, but implementation uses T-30

---

## 1. Edge Function Location

**File:** `supabase/functions/check-job-start-deadlines/index.ts`  
**Status:** ACTIVE  
**Invocation:** Scheduled (every 5 minutes) or manual

**Key Logic:**
1. Calls RPC `get_jobs_needing_start_deadline_notifications(p_current_time)`
2. For each job returned:
   - Checks for existing notification (deduplication)
   - Queries recipients by role
   - Creates `app_notifications` entries
   - Invokes `push-notifications` Edge Function for push delivery

---

## 2. Threshold Calculation

### 2.1 Time Calculation

**RPC Function Logic:**
```sql
v_current_sa_time := p_current_time + v_sa_offset;  -- SA time is UTC+2
v_minutes_until_pickup := earliest_pickup_date - v_current_sa_time
```

**Key Points:**
- Uses `transport.pickup_date` (timestamp without time zone, assumed SA time)
- Converts current UTC time to SA time (UTC+2)
- Calculates minutes until pickup: `earliest_pickup_date - current_sa_time`

### 2.2 T-90 Minutes Threshold

**Window:** 85-90 minutes before pickup (5-minute window for cron frequency)

**SQL Condition:**
```sql
(earliest_pickup_date - v_current_sa_time) <= INTERVAL '90 minutes'
AND (earliest_pickup_date - v_current_sa_time) >= INTERVAL '85 minutes'
```

**Purpose:** 5-minute window accounts for cron job running every 5 minutes, ensuring notification is sent once within the window.

### 2.3 T-30 Minutes Threshold

**Window:** 25-30 minutes before pickup (5-minute window for cron frequency)

**SQL Condition:**
```sql
(earliest_pickup_date - v_current_sa_time) <= INTERVAL '30 minutes'
AND (earliest_pickup_date - v_current_sa_time) >= INTERVAL '25 minutes'
```

**Note:** Documentation mentions T-60, but implementation uses T-30.

---

## 3. Role-Based Recipients

### 3.1 T-90 Minutes (Manager)

**RPC Returns:** `recipient_role = 'manager'`

**Edge Function Logic:**
```typescript
const rolesToQuery = recipient_role === 'administrator' 
  ? ['administrator', 'super_admin']
  : [recipient_role]  // For 'manager', this is just ['manager']

const { data: recipients } = await supabase
  .from('profiles')
  .select('id, role, notification_prefs')
  .in('role', rolesToQuery)
  .eq('status', 'active')
```

**⚠️ BUG IDENTIFIED:**
- Edge Function queries **ALL active managers globally**
- **Should query:** Only `jobs.manager_id` for the specific job
- **Current behavior:** All managers receive notifications for all jobs

**Expected Behavior:**
- Query: `profiles.id = jobs.manager_id` for the specific job
- Only the assigned manager should receive the notification

### 3.2 T-30 Minutes (Administrator)

**RPC Returns:** `recipient_role = 'administrator'`

**Edge Function Logic:**
```typescript
const rolesToQuery = recipient_role === 'administrator' 
  ? ['administrator', 'super_admin']  // Includes both roles
  : [recipient_role]

const { data: recipients } = await supabase
  .from('profiles')
  .select('id, role, notification_prefs')
  .in('role', rolesToQuery)
  .eq('status', 'active')
```

**Current Behavior:**
- ✅ Queries all active `administrator` and `super_admin` users globally
- ✅ No `branch_id` filtering (correct for global escalation)
- ✅ All admins/super_admins receive notifications for all jobs

**Expected Behavior:** ✅ Correct (global escalation for admins)

---

## 4. Deduplication Strategy

### 4.1 Implementation

**Location:** `check-job-start-deadlines/index.ts` (lines 70-87)

**Logic:**
```typescript
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

**Deduplication Key:**
- `job_id` + `notification_type`
- One notification per job per threshold (90min or 30min)

**Effectiveness:**
- ✅ Prevents duplicate notifications for the same job + threshold
- ✅ Works across multiple cron runs
- ⚠️ **Limitation:** If notification is deleted, it could be re-sent (unlikely in production)

---

## 5. Job Starting Prevention

### 5.1 RPC Function Filter

**SQL Condition:**
```sql
LEFT JOIN public.driver_flow df ON j.id = df.job_id
WHERE 
  j.driver_id IS NOT NULL
  AND (df.job_started_at IS NULL)  -- Job not started
  AND j.job_status NOT IN ('cancelled', 'completed')
```

**Key Point:**
- RPC function filters by `df.job_started_at IS NULL`
- If job starts (even between T-90 and T-30), it will **NOT** be returned by the RPC
- **Result:** Escalation notifications are prevented if job starts

### 5.2 Edge Function Behavior

**No Additional Check:**
- Edge Function does NOT re-check `job_started_at` after RPC call
- Relies entirely on RPC function filtering

**Potential Race Condition:**
- If job starts between RPC call and notification creation, notification may still be created
- **Mitigation:** RPC is called fresh on each cron run, so next run will exclude started jobs

---

## 6. Notification Type Mapping

| Threshold | Notification Type | Recipient Role (RPC) | Recipient Role (Edge Function) |
|-----------|------------------|---------------------|--------------------------------|
| T-90 min  | `job_start_deadline_warning_90min` | `manager` | `manager` (all active) |
| T-30 min  | `job_start_deadline_warning_30min` | `administrator` | `administrator` + `super_admin` (all active) |

---

## 7. Complete Notification Flow Table

| Condition | Trigger Time Window | Recipients | Notification Type | Deduplication |
|-----------|-------------------|------------|------------------|---------------|
| Job not started, 85-90 min before pickup | 85-90 minutes before `transport.pickup_date` | **ALL active managers globally** ⚠️ | `job_start_deadline_warning_90min` | `job_id` + `notification_type` |
| Job not started, 25-30 min before pickup | 25-30 minutes before `transport.pickup_date` | **ALL active administrators + super_admins globally** | `job_start_deadline_warning_30min` | `job_id` + `notification_type` |
| Job started before T-90 | N/A | None | N/A | N/A (job excluded from RPC) |
| Job started between T-90 and T-30 | N/A | None | N/A | N/A (job excluded from RPC) |
| Job started after T-30 | N/A | None | N/A | N/A (job excluded from RPC) |

---

## 8. Key Findings

### 8.1 ✅ Working Correctly

1. **Deduplication:** Prevents duplicate notifications via `job_id` + `notification_type` check
2. **Job Starting Prevention:** RPC filters by `job_started_at IS NULL`, preventing escalation if job starts
3. **Admin Global Scope:** Administrators and super_admins receive notifications for all jobs (correct)
4. **Time Window:** 5-minute windows (85-90, 25-30) account for cron frequency

### 8.2 ⚠️ Issues Identified

1. **Manager Scoping Bug:**
   - **Current:** All active managers receive notifications for all jobs
   - **Expected:** Only `jobs.manager_id` should receive notification for their assigned job
   - **Impact:** Managers receive notifications for jobs they don't manage
   - **Fix Required:** Edge Function should filter by `jobs.manager_id` for manager role

2. **Threshold Mismatch:**
   - **Current:** T-30 minutes for administrators
   - **Documentation mentions:** T-60 minutes
   - **Impact:** Administrators are notified later than documented (30min vs 60min)
   - **Fix Required:** Update RPC function to use 60-55 minute window instead of 30-25

3. **No Re-check After RPC:**
   - Edge Function does not re-verify `job_started_at` after RPC call
   - **Impact:** Minor race condition if job starts between RPC call and notification creation
   - **Mitigation:** Next cron run will exclude started jobs (acceptable)

---

## 9. RPC Function Details

**Function:** `get_jobs_needing_start_deadline_notifications(p_current_time timestamp with time zone)`

**Returns:**
- `job_id`
- `job_number`
- `driver_name`
- `pickup_date`
- `minutes_before` (90 or 30)
- `notification_type` (`job_start_deadline_warning_90min` or `job_start_deadline_warning_30min`)
- `recipient_role` (`manager` or `administrator`)

**Filters:**
- `driver_id IS NOT NULL` (job has driver)
- `df.job_started_at IS NULL` (job not started)
- `job_status NOT IN ('cancelled', 'completed')` (job is active)
- Time window: 85-90 minutes OR 25-30 minutes before pickup

**Time Calculation:**
- Converts UTC to SA time (UTC+2)
- Uses `MIN(transport.pickup_date)` per job as earliest pickup

---

## 10. Edge Function Details

**Function:** `check-job-start-deadlines`

**Steps:**
1. Get current UTC time
2. Call RPC `get_jobs_needing_start_deadline_notifications`
3. For each job:
   - Check for existing notification (deduplication)
   - Query recipients by role (⚠️ bug: queries all managers globally)
   - Create `app_notifications` entries
   - Invoke `push-notifications` Edge Function (if preferences allow)

**Recipient Selection:**
- **Manager:** All active `manager` role users (⚠️ should be only `jobs.manager_id`)
- **Administrator:** All active `administrator` + `super_admin` role users (✅ correct)

---

## 11. Verification Queries

### 11.1 Check Active Jobs Needing Notifications

```sql
-- Simulate RPC call for current time
SELECT * FROM public.get_jobs_needing_start_deadline_notifications(NOW());
```

### 11.2 Check Existing Notifications (Deduplication)

```sql
-- Check if notification already exists for a job
SELECT id, notification_type, created_at
FROM public.app_notifications
WHERE job_id = '123'::text
AND notification_type IN ('job_start_deadline_warning_90min', 'job_start_deadline_warning_30min');
```

### 11.3 Verify Job Starting Prevents Escalation

```sql
-- Check if job started prevents notification
SELECT 
  j.id,
  j.job_number,
  df.job_started_at,
  CASE 
    WHEN df.job_started_at IS NULL THEN 'Will be notified if in window'
    ELSE 'Will NOT be notified (job started)'
  END as notification_status
FROM public.jobs j
LEFT JOIN public.driver_flow df ON j.id = df.job_id
WHERE j.driver_id IS NOT NULL
AND j.job_status NOT IN ('cancelled', 'completed');
```

---

## 12. Recommendations

### 12.1 Critical Fixes

1. **Fix Manager Scoping:**
   - Update Edge Function to query only `jobs.manager_id` for manager role
   - Pass `manager_id` from RPC to Edge Function
   - Filter recipients: `profiles.id = jobs.manager_id`

2. **Update Threshold to T-60:**
   - Change RPC function: 30-25 minutes → 60-55 minutes
   - Update notification type: `job_start_deadline_warning_30min` → `job_start_deadline_warning_60min`
   - Update Edge Function to handle new notification type

### 12.2 Enhancements

1. **Add Re-check After RPC:**
   - Re-verify `job_started_at` before creating notification (defense-in-depth)

2. **Add Run ID:**
   - Include `run_id` in logs for traceability (similar to push-notifications-poller)

3. **Add Summary Logging:**
   - Log summary of jobs checked, notifications created, skipped (deduplication)

---

## 13. Conclusion

**Current State:**
- ✅ Deduplication works correctly
- ✅ Job starting prevents escalation (via RPC filter)
- ⚠️ Manager scoping bug (all managers receive all notifications)
- ⚠️ Threshold mismatch (T-30 instead of T-60)

**Priority Fixes:**
1. Fix manager scoping to use `jobs.manager_id` only
2. Update threshold from T-30 to T-60 for administrators

**No Breaking Changes Required:**
- Core logic is sound
- Deduplication is effective
- Job starting prevention works correctly

---

**End of Audit**

