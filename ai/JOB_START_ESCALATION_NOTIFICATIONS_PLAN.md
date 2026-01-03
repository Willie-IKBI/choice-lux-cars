# Job Start Escalation Notifications Plan

**Date:** 2025-01-22  
**Status:** Audit Complete - Implementation Plan Ready  
**Objective:** Implement escalation notifications for jobs due soon but not started

---

## Executive Summary

**Current State:**
- ✅ Edge function `check-job-start-deadlines` exists (version 1, ACTIVE)
- ✅ RPC function `get_jobs_needing_start_deadline_notifications` exists
- ⚠️ Current thresholds: 90min (manager) and 30min (administrator)
- ⚠️ **Requirement change:** Need 90min (manager) and 60min (admin + super_admin)

**Gap Analysis:**
- Existing function checks 30min, needs to be updated to 60min
- Existing function already handles manager (90min) correctly
- Existing function already handles admin + super_admin correctly
- ⚠️ **Preference mismatch:** Edge function checks `profiles.notification_prefs` (JSONB), but `user_notification_preferences` table exists separately
- Deduplication already implemented (checks existing notifications)

**Recommendation:**
- Update existing edge function and RPC to change 30min → 60min threshold
- Enhance notification preferences to support category-specific channels (push vs in-app)
- Ensure branch-scoping for admin/super_admin (if required)

---

## 1. Current State Audit

### 1.1 Job Due Datetime Fields

**Primary Field:** `transport.pickup_date` (timestamp without time zone)
- **Purpose:** Earliest pickup time for a job (from transport table)
- **Usage:** RPC function `get_jobs_needing_start_deadline_notifications` uses `MIN(transport.pickup_date)` per job
- **Location:** `public.transport` table

**Secondary Field:** `jobs.job_start_date` (date)
- **Purpose:** Scheduled start date (date only, no time)
- **Usage:** Used for job filtering and display
- **Location:** `public.jobs` table

**Evidence:**
```sql
-- RPC function uses transport.pickup_date
SELECT MIN(t.pickup_date) as earliest_pickup_date
FROM public.transport t
WHERE t.pickup_date IS NOT NULL
GROUP BY t.job_id
```

**Conclusion:** ✅ `transport.pickup_date` is the correct field for deadline calculations.

---

### 1.2 "Started" Definition

**Database Indicator:** `driver_flow.job_started_at` (timestamptz, nullable)

**Status-Based Indicator:** `jobs.job_status` values:
- ✅ `'started'` - Job has started
- ✅ `'in_progress'` - Job is in progress
- ❌ `'open'` - Job not started
- ❌ `'assigned'` - Job assigned but not started
- ❌ `'cancelled'` - Job cancelled (excluded from notifications)
- ❌ `'completed'` - Job completed (excluded from notifications)

**Current Logic (from RPC function):**
```sql
WHERE 
  j.driver_id IS NOT NULL
  AND (df.job_started_at IS NULL)  -- Job not started
  AND j.job_status NOT IN ('cancelled', 'completed')
```

**Flutter Model Logic:**
```dart
// lib/features/jobs/models/job.dart:327
bool get isStarted => status == 'started';
```

**Conclusion:** ✅ Job is "not started" when:
- `driver_flow.job_started_at IS NULL` **OR**
- `jobs.job_status IN ('open', 'assigned')`

**Recommended Check:** Use `driver_flow.job_started_at IS NULL` as primary indicator (more reliable than status alone).

---

### 1.3 Existing Notification Pipeline

#### A) Notification Storage

**Table:** `public.app_notifications`
- ✅ 14 columns including `id`, `user_id`, `message`, `notification_type`, `job_id`, `priority`, `action_data`
- ✅ RLS policies allow service_role inserts
- ✅ Realtime subscription active in Flutter app

**Schema:**
```sql
id (uuid, PK)
user_id (uuid, FK to profiles.id)
message (text)
notification_type (text)  -- e.g., 'job_start_deadline_warning_90min'
job_id (text, nullable)
priority (text, default 'normal')
action_data (jsonb, nullable)  -- Contains route, job_id, etc.
is_read (boolean, default false)
created_at (timestamptz, default now())
```

**Evidence:**
- ✅ 37,587 total notifications in database
- ✅ 0 notifications in last 24 hours (confirms server-side push not working, but in-app works)

---

#### B) Realtime Listeners

**Location:** `lib/features/notifications/providers/notification_provider.dart`

**Implementation:**
```dart
// Line 652-656
final stream = _supabase
    .from('app_notifications')
    .stream(primaryKey: ['id'])
    .eq('user_id', currentUser.id)
    .order('created_at', ascending: false);
```

**Status:** ✅ Working - Real-time updates appear in-app immediately

---

#### C) Edge Functions for Push

**Existing Functions:**
1. ✅ `push-notifications` (version 28, ACTIVE, `verify_jwt=false`)
   - Handles webhook payload format
   - Sends FCM push notifications
   - Logs to `notification_delivery_log`

2. ✅ `check-job-start-deadlines` (version 1, ACTIVE, `verify_jwt=false`)
   - Runs on schedule (cron)
   - Calls RPC `get_jobs_needing_start_deadline_notifications`
   - Creates notifications in `app_notifications`
   - Manually invokes `push-notifications` edge function

**Evidence:**
- Edge function exists and is deployed
- RPC function exists and is functional
- Current thresholds: 90min (manager) and 30min (administrator)

---

#### D) Delivery Logs

**Table:** `public.notification_delivery_log`
- ✅ Tracks FCM delivery attempts
- ✅ 39,792 total attempts (24,947 success, 14,845 failed)
- ✅ 8 attempts in last 7 days, 0 in last 24 hours

**Schema:**
```sql
notification_id (uuid, FK to app_notifications.id)
user_id (uuid)
fcm_token (text, nullable)
fcm_response (jsonb, nullable)
sent_at (timestamptz)
success (boolean)
error_message (text, nullable)
retry_count (integer)
```

**Status:** ✅ Working - Delivery attempts are logged

---

### 1.4 Scheduled Edge Functions

**Existing Function:** `check-job-start-deadlines`
- ✅ **Status:** ACTIVE (version 1)
- ✅ **Schedule:** Configured via Supabase cron (frequency unknown from code)
- ✅ **Verify JWT:** `false` (allows cron invocation)
- ✅ **Location:** `supabase/functions/check-job-start-deadlines/index.ts`

**Current Implementation:**
- Calls RPC `get_jobs_needing_start_deadline_notifications(p_current_time)`
- Checks for existing notifications (deduplication)
- Creates notifications for managers (90min) and administrators (30min)
- Manually invokes `push-notifications` edge function

**Evidence:**
- Function is deployed and active
- Uses existing RPC function
- Handles deduplication correctly

---

### 1.5 pg_net Availability

**Status:** ✅ **CONFIRMED**

**Extension:** `pg_net` version 0.10.0
- **Schema:** `extensions`
- **Function:** `net.http_post()` available

**Conclusion:** ✅ `pg_net` is available if needed for trigger-based solutions (not required for scheduled edge function approach).

---

## 2. Root Cause Analysis

### 2.1 Current Implementation Analysis

**What Exists:**
- ✅ Edge function `check-job-start-deadlines` deployed
- ✅ RPC function `get_jobs_needing_start_deadline_notifications` functional
- ✅ Deduplication logic implemented
- ✅ Notification preferences table exists
- ✅ Push notification pipeline exists

**What Needs Change:**
- ⚠️ **Threshold mismatch:** Current function checks 30min, requirement is 60min
- ⚠️ **Preference filtering:** Current function checks `notification_prefs[notification_type]` but preferences table uses boolean columns per category
- ⚠️ **Branch scoping:** Current function doesn't filter admins by branch (may need to add)

**Gap:** The existing implementation is 90% complete but needs:
1. Update 30min threshold → 60min
2. Align preference checking with actual table schema
3. Add branch scoping for admin/super_admin (if required)

---

## 3. Recommended Fix Strategy

### Option A: Update Existing Edge Function + RPC (RECOMMENDED)

**Approach:**
1. Update RPC function `get_jobs_needing_start_deadline_notifications`:
   - Change 30min threshold → 60min
   - Update notification_type from `'job_start_deadline_warning_30min'` → `'job_start_deadline_warning_60min'`
   - Keep 90min threshold unchanged

2. Update edge function `check-job-start-deadlines`:
   - Align preference checking with `user_notification_preferences` table schema
   - Add branch scoping for admin/super_admin (if required)
   - Ensure proper category mapping

**Pros:**
- ✅ Minimal changes (update existing code)
- ✅ Reuses existing infrastructure
- ✅ No new migrations needed
- ✅ Low risk (incremental update)

**Cons:**
- ⚠️ Requires understanding existing preference schema
- ⚠️ May need to add branch filtering logic

---

### Option B: Create New Edge Function (NOT RECOMMENDED)

**Approach:**
- Create entirely new edge function and RPC
- Duplicate existing logic with new thresholds

**Pros:**
- ✅ Clean slate
- ✅ No risk to existing function

**Cons:**
- ❌ Code duplication
- ❌ Maintenance burden
- ❌ Unnecessary complexity

**Recommendation:** Use **Option A** - Update existing implementation.

---

## 4. Implementation Plan

### Phase 1: Observability / Verification

**Goal:** Understand current behavior and verify requirements.

**Tasks:**
1. **Verify current schedule:**
   - Check Supabase Dashboard → Edge Functions → Cron Jobs
   - Confirm `check-job-start-deadlines` schedule (likely every 5 minutes)
   - Document current frequency

2. **Test current function:**
   - Manually invoke `check-job-start-deadlines` edge function
   - Verify it calls RPC correctly
   - Check logs for any errors

3. **Verify preference schema:**
   - Query `user_notification_preferences` table structure
   - Understand how preferences map to notification types
   - Document default behavior (if row missing)

4. **Test notification creation:**
   - Create test job with pickup_date 90min from now
   - Wait for cron to run (or invoke manually)
   - Verify notification created in `app_notifications`
   - Verify push notification sent (if preferences allow)

**Deliverables:**
- Current schedule frequency documented
- Preference schema mapping documented
- Test results log

**Risk:** Low (read-only verification)

---

### Phase 2: Token Reliability (If Needed)

**Goal:** Ensure FCM tokens are valid for escalation recipients.

**Tasks:**
1. **Check token coverage:**
   - Query managers with FCM tokens
   - Query admins/super_admins with FCM tokens
   - Identify gaps

2. **Token validation:**
   - Add validation if tokens are missing/invalid
   - Log warnings for recipients without tokens

**Deliverables:**
- Token coverage report
- Validation logic (if needed)

**Risk:** Low (doesn't break existing flow)

---

### Phase 3: Update RPC Function

**Goal:** Change 30min threshold to 60min.

**Migration:** `supabase/migrations/20250122_update_job_start_deadline_rpc_60min.sql`

**Changes Required:**
1. Update time window check:
   - FROM: `<= INTERVAL '30 minutes' AND >= INTERVAL '25 minutes'`
   - TO: `<= INTERVAL '60 minutes' AND >= INTERVAL '55 minutes'`

2. Update notification_type:
   - FROM: `'job_start_deadline_warning_30min'`
   - TO: `'job_start_deadline_warning_60min'`

3. Keep recipient_role as `'administrator'` (already includes super_admin in edge function)

**SQL Pseudo-Code:**
```sql
-- Update the CASE statement in get_jobs_needing_start_deadline_notifications
CASE 
  WHEN (earliest_pickup_date - current_sa_time) <= INTERVAL '90 minutes'
       AND (earliest_pickup_date - current_sa_time) >= INTERVAL '85 minutes'
  THEN 90
  WHEN (earliest_pickup_date - current_sa_time) <= INTERVAL '60 minutes'  -- CHANGED FROM 30
       AND (earliest_pickup_date - current_sa_time) >= INTERVAL '55 minutes'  -- CHANGED FROM 25
  THEN 60  -- CHANGED FROM 30
  ELSE NULL
END as minutes_before,

CASE 
  WHEN ... (90min case unchanged) ...
  WHEN (earliest_pickup_date - current_sa_time) <= INTERVAL '60 minutes'  -- CHANGED
       AND (earliest_pickup_date - current_sa_time) >= INTERVAL '55 minutes'  -- CHANGED
  THEN 'job_start_deadline_warning_60min'  -- CHANGED FROM 30min
  ELSE NULL
END as notification_type,
```

**Deliverables:**
- Updated RPC function migration
- Verification queries

**Risk:** Low (only changes threshold, logic unchanged)

---

### Phase 4: Update Edge Function

**Goal:** Align preference checking and add branch scoping (if needed).

**File:** `supabase/functions/check-job-start-deadlines/index.ts`

**Changes Required:**

1. **Preference Checking:**
   - Current: Checks `notification_prefs[notification_type]` (JSONB field)
   - **Issue:** `user_notification_preferences` table uses boolean columns per category
   - **Fix:** Map notification_type to preference column:
     - `'job_start_deadline_warning_90min'` → Check `system_alerts` OR `job_status_changes`
     - `'job_start_deadline_warning_60min'` → Check `system_alerts` OR `job_status_changes`

2. **Branch Scoping (If Required):**
   - Current: Queries all admins/super_admins
   - **Enhancement:** Filter by `profiles.branch_id = jobs.branch_id` (if branch-scoped escalation required)
   - **Decision Required:** Should admins only see escalations for their branch?

3. **Channel Filtering:**
   - Current: Checks `push_notifications` preference
   - **Enhancement:** Check both `push_notifications` AND `in_app_notifications`
   - **Default:** If preference row missing, assume enabled (opt-out model)

**Pseudo-Code:**
```typescript
// Get recipients with preferences
const { data: recipients } = await supabase
  .from('profiles')
  .select(`
    id, 
    role, 
    branch_id,
    user_notification_preferences (
      system_alerts,
      job_status_changes,
      push_notifications,
      in_app_notifications
    )
  `)
  .in('role', rolesToQuery)
  .eq('status', 'active')
  // Add branch filter if required:
  // .eq('branch_id', job.branch_id)

// Filter by preferences
for (const recipient of recipients) {
  const prefs = recipient.user_notification_preferences?.[0]
  
  // Check category preference (system_alerts or job_status_changes)
  const categoryEnabled = 
    prefs?.system_alerts === true || 
    prefs?.job_status_changes === true ||
    prefs === null  // Default: enabled if no preference row
  
  if (!categoryEnabled) continue
  
  // Create notification (always create in-app)
  const notification = await createNotification(...)
  
  // Check push preference
  const pushEnabled = 
    prefs?.push_notifications === true ||
    prefs === null  // Default: enabled
  
  if (pushEnabled) {
    await invokePushNotification(notification)
  }
}
```

**Deliverables:**
- Updated edge function code
- Preference mapping documentation
- Branch scoping decision documented

**Risk:** Medium (changes preference logic, needs testing)

---

### Phase 5: Validation & Deduplication

**Goal:** Ensure notifications are sent exactly once per job per threshold.

**Current Deduplication:**
```typescript
// Check if notification already sent
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

**Strategy:** ✅ **ALREADY IMPLEMENTED**

**Event Key Approach (Alternative):**
- Could use `job_id + notification_type` as composite key
- Current approach (query existing notifications) is sufficient

**Enhancement (Optional):**
- Add `jobs.escalation_notified_90min_at` and `jobs.escalation_notified_60min_at` timestamps
- Faster lookup than querying `app_notifications`
- **Recommendation:** Keep current approach (simpler, no schema changes)

**Deliverables:**
- Deduplication verification tests
- Performance check (if needed)

**Risk:** Low (deduplication already works)

---

### Phase 6: QA Checklist

#### Test 1: Manager 90-Minute Notification

**Setup:**
- Create job with `pickup_date` = 90 minutes from now
- Assign manager to job
- Ensure `driver_flow.job_started_at IS NULL`
- Ensure manager has `system_alerts = true` in preferences

**Steps:**
1. Wait for cron to run (or invoke edge function manually)
2. Check `app_notifications` for new notification
3. Verify notification type = `'job_start_deadline_warning_90min'`
4. Verify recipient = manager_id
5. Verify push notification sent (if `push_notifications = true`)
6. Verify in-app notification appears (realtime)

**Expected:**
- ✅ Notification created
- ✅ Manager receives push (if enabled)
- ✅ Manager sees in-app notification
- ✅ No duplicate notifications on subsequent cron runs

---

#### Test 2: Admin 60-Minute Notification

**Setup:**
- Create job with `pickup_date` = 60 minutes from now
- Ensure `driver_flow.job_started_at IS NULL`
- Ensure admin has `system_alerts = true` in preferences

**Steps:**
1. Wait for cron to run (or invoke edge function manually)
2. Check `app_notifications` for new notification
3. Verify notification type = `'job_start_deadline_warning_60min'`
4. Verify recipients include all active admins and super_admins
5. Verify push notifications sent (if enabled)
6. Verify in-app notifications appear

**Expected:**
- ✅ Notifications created for all admins/super_admins
- ✅ Push notifications sent (if enabled)
- ✅ In-app notifications appear
- ✅ No duplicate notifications

---

#### Test 3: Preference Filtering

**Setup:**
- Create job with `pickup_date` = 90 minutes from now
- Manager has `system_alerts = false` in preferences

**Steps:**
1. Invoke edge function
2. Check `app_notifications` for manager's notification

**Expected:**
- ❌ No notification created (preference disabled)
- ✅ Job still processes for other recipients

---

#### Test 4: Job Started (No Notification)

**Setup:**
- Create job with `pickup_date` = 90 minutes from now
- Set `driver_flow.job_started_at = NOW()`

**Steps:**
1. Invoke edge function
2. Check `app_notifications`

**Expected:**
- ❌ No notification created (job already started)

---

#### Test 5: Branch Scoping (If Implemented)

**Setup:**
- Create job with `branch_id = 1`
- Admin A has `branch_id = 1`
- Admin B has `branch_id = 2`

**Steps:**
1. Invoke edge function for 60min threshold
2. Check notifications

**Expected:**
- ✅ Admin A receives notification (same branch)
- ❌ Admin B does NOT receive notification (different branch)

---

## 5. SQL / Supabase Verification Queries

### 5.1 Verify Triggers Exist

```sql
-- Check for triggers on app_notifications (should be none for this feature)
SELECT tgname, pg_get_triggerdef(oid)
FROM pg_trigger
WHERE tgrelid = 'public.app_notifications'::regclass
AND NOT tgisinternal;
```

**Expected:** Zero triggers (scheduled edge function approach, not trigger-based)

---

### 5.2 Verify Delivery Attempts

```sql
-- Check recent delivery attempts for escalation notifications
SELECT 
  COUNT(*) as total_attempts,
  COUNT(CASE WHEN success = true THEN 1 END) as successful,
  COUNT(CASE WHEN success = false THEN 1 END) as failed,
  COUNT(CASE WHEN sent_at > NOW() - INTERVAL '24 hours' THEN 1 END) as last_24h
FROM public.notification_delivery_log ndl
INNER JOIN public.app_notifications an ON ndl.notification_id = an.id
WHERE an.notification_type IN (
  'job_start_deadline_warning_90min',
  'job_start_deadline_warning_60min'
);
```

---

### 5.3 Verify Failures

```sql
-- Check failed delivery attempts with error messages
SELECT 
  ndl.notification_id,
  an.notification_type,
  an.job_id,
  ndl.error_message,
  ndl.sent_at
FROM public.notification_delivery_log ndl
INNER JOIN public.app_notifications an ON ndl.notification_id = an.id
WHERE ndl.success = false
AND an.notification_type IN (
  'job_start_deadline_warning_90min',
  'job_start_deadline_warning_60min'
)
AND ndl.sent_at > NOW() - INTERVAL '7 days'
ORDER BY ndl.sent_at DESC;
```

---

### 5.4 Test Jobs Needing Notifications

```sql
-- Manually test RPC function
SELECT *
FROM public.get_jobs_needing_start_deadline_notifications(NOW());
```

**Expected:** Returns jobs within 85-90min or 55-60min windows that haven't started

---

### 5.5 Verify Preference Coverage

```sql
-- Check preference coverage for managers and admins
SELECT 
  p.role,
  COUNT(*) as total_users,
  COUNT(UNP.id) as users_with_preferences,
  COUNT(CASE WHEN UNP.system_alerts = true THEN 1 END) as system_alerts_enabled,
  COUNT(CASE WHEN UNP.push_notifications = true THEN 1 END) as push_enabled
FROM public.profiles p
LEFT JOIN public.user_notification_preferences UNP ON p.id = UNP.user_id
WHERE p.role IN ('manager', 'administrator', 'super_admin')
AND p.status = 'active'
GROUP BY p.role;
```

---

## 6. Notification Preferences Model

### 6.1 Current Schema

**Table:** `public.user_notification_preferences`

**Columns:**
- `id` (uuid, PK)
- `user_id` (uuid, FK to profiles.id, UNIQUE)
- `job_assignments` (boolean, nullable)
- `job_reassignments` (boolean, nullable)
- `job_status_changes` (boolean, nullable)
- `job_cancellations` (boolean, nullable)
- `payment_reminders` (boolean, nullable)
- `system_alerts` (boolean, nullable) ← **Relevant for escalations**
- `push_notifications` (boolean, nullable) ← **Channel preference**
- `in_app_notifications` (boolean, nullable) ← **Channel preference**
- `email_notifications` (boolean, nullable)
- `sound_enabled` (boolean, nullable)
- `vibration_enabled` (boolean, nullable)
- `high_priority_only` (boolean, nullable)
- `quiet_hours_enabled` (boolean, nullable)
- `quiet_hours_start` (time, nullable)
- `quiet_hours_end` (time, nullable)
- `created_at` (timestamptz)
- `updated_at` (timestamptz)

**Current Coverage:**
- Total preference rows in `user_notification_preferences` table: 0 (table exists but empty)
- Profiles with JSONB preferences: 47/47 (100% coverage via `profiles.notification_prefs`)

**Current Implementation:**
- Edge function uses `profiles.notification_prefs` (JSONB column) ✅
- Flutter app uses `profiles.notification_prefs` (JSONB column) ✅
- `user_notification_preferences` table exists but is unused (legacy or future use)

**Conclusion:** Current JSONB approach is working. No changes needed to preference storage mechanism.

---

### 6.2 Proposed Preference Mapping

**Category Mapping:**
- `'job_start_deadline_warning_90min'` → Check `system_alerts` OR `job_status_changes`
- `'job_start_deadline_warning_60min'` → Check `system_alerts` OR `job_status_changes`

**Channel Mapping:**
- **In-app:** Always create notification (unless category disabled)
- **Push:** Only if `push_notifications = true` (or null/default enabled)

**Default Behavior:**
- **If preference row missing:** Assume enabled (opt-out model)
  - `system_alerts = true` (default)
  - `push_notifications = true` (default)
  - `in_app_notifications = true` (default)

**Rationale:**
- Escalation notifications are critical (operational alerts)
- Opt-out model ensures important alerts aren't missed
- Users can disable if they don't want them

---

### 6.3 Preference Filtering Logic

**Pseudo-Code:**
```typescript
// Get recipient with preferences (already fetched in edge function)
const prefs = recipient.notification_prefs as Record<string, boolean> | null

// Check category preference (map notification_type to category)
const categoryEnabled = 
  prefs?.['system_alerts'] === true || 
  prefs?.['job_status_changes'] === true ||
  prefs === null ||  // Default: enabled if no preferences
  prefs[notification_type] !== false  // Current logic: opt-out per type

if (!categoryEnabled) {
  // Skip this recipient
  continue
}

// Create in-app notification (always, if category enabled)
const notification = await createNotification(...)

// Check push preference
const pushEnabled = 
  prefs?.['push_notifications'] === true ||
  prefs === null ||  // Default: enabled
  prefs[notification_type] !== false  // Current logic: opt-out per type

if (pushEnabled) {
  await invokePushNotification(notification)
}
```

**Note:** Current edge function uses `prefs?.[notification_type] !== false` which is an opt-out model (defaults to enabled). This works correctly.

---

## 7. Exact Job Status Definitions and Time Fields

### 7.1 Job Status Values

**From Database Query:**
- `'open'` - Job created, not assigned
- `'assigned'` - Job assigned to driver
- `'started'` - Job has started (driver began work)
- `'in_progress'` - Job in progress
- `'ready_to_close'` - Job ready for closure
- `'review'` - Job submitted for review
- `'completed'` - Job completed
- `'declined'` - Job declined by manager
- `'cancelled'` - Job cancelled

**"Not Started" Definition:**
- ✅ `driver_flow.job_started_at IS NULL` (primary indicator)
- ✅ `jobs.job_status IN ('open', 'assigned')` (secondary indicator)

**"Started" Definition:**
- ✅ `driver_flow.job_started_at IS NOT NULL` (primary indicator)
- ✅ `jobs.job_status IN ('started', 'in_progress', 'ready_to_close', 'review', 'completed')` (secondary indicator)

---

### 7.2 Time Fields

**Primary Field for Deadline Calculation:**
- `transport.pickup_date` (timestamp without time zone)
  - **Usage:** `MIN(transport.pickup_date)` per job (earliest pickup)
  - **Calculation:** `pickup_date - NOW() = minutes_until_pickup`

**Secondary Field:**
- `jobs.job_start_date` (date only, no time)
  - **Usage:** Job filtering and display
  - **Not used for:** Deadline calculations (no time component)

**Start Indicator:**
- `driver_flow.job_started_at` (timestamptz)
  - **Usage:** Primary indicator that job has started
  - **Check:** `IS NULL` = not started, `IS NOT NULL` = started

---

## 8. SQL-Like Pseudo Queries for Stage A and B

### Stage A: Manager 90-Minute Warning

**Pseudo-Query:**
```sql
WITH job_earliest_pickup AS (
  SELECT 
    t.job_id,
    MIN(t.pickup_date) as earliest_pickup_date
  FROM public.transport t
  WHERE t.pickup_date IS NOT NULL
  GROUP BY t.job_id
),
jobs_with_driver AS (
  SELECT 
    j.id as job_id,
    j.job_number,
    j.manager_id,
    j.driver_id,
    j.job_status,
    jep.earliest_pickup_date,
    df.job_started_at
  FROM public.jobs j
  INNER JOIN job_earliest_pickup jep ON j.id = jep.job_id
  LEFT JOIN public.driver_flow df ON j.id = df.job_id
  WHERE 
    j.driver_id IS NOT NULL
    AND j.manager_id IS NOT NULL
    AND df.job_started_at IS NULL  -- Job not started
    AND j.job_status NOT IN ('cancelled', 'completed', 'declined')
    -- 90-minute window: 85-90 minutes before pickup
    AND (jep.earliest_pickup_date::timestamp with time zone - (NOW() + INTERVAL '2 hours')) 
        <= INTERVAL '90 minutes'
    AND (jep.earliest_pickup_date::timestamp with time zone - (NOW() + INTERVAL '2 hours')) 
        >= INTERVAL '85 minutes'
)
SELECT 
  job_id,
  job_number,
  manager_id as recipient_id,
  'manager' as recipient_role,
  'job_start_deadline_warning_90min' as notification_type,
  90 as minutes_before_pickup
FROM jobs_with_driver;
```

---

### Stage B: Admin/Super_Admin 60-Minute Warning

**Pseudo-Query:**
```sql
WITH job_earliest_pickup AS (
  SELECT 
    t.job_id,
    MIN(t.pickup_date) as earliest_pickup_date
  FROM public.transport t
  WHERE t.pickup_date IS NOT NULL
  GROUP BY t.job_id
),
jobs_with_driver AS (
  SELECT 
    j.id as job_id,
    j.job_number,
    j.driver_id,
    j.branch_id,  -- For branch scoping (if required)
    j.job_status,
    jep.earliest_pickup_date,
    df.job_started_at
  FROM public.jobs j
  INNER JOIN job_earliest_pickup jep ON j.id = jep.job_id
  LEFT JOIN public.driver_flow df ON j.id = df.job_id
  WHERE 
    j.driver_id IS NOT NULL
    AND df.job_started_at IS NULL  -- Job not started
    AND j.job_status NOT IN ('cancelled', 'completed', 'declined')
    -- 60-minute window: 55-60 minutes before pickup
    AND (jep.earliest_pickup_date::timestamp with time zone - (NOW() + INTERVAL '2 hours')) 
        <= INTERVAL '60 minutes'
    AND (jep.earliest_pickup_date::timestamp with time zone - (NOW() + INTERVAL '2 hours')) 
        >= INTERVAL '55 minutes'
),
admin_recipients AS (
  SELECT 
    p.id as recipient_id,
    p.role,
    p.branch_id
  FROM public.profiles p
  WHERE p.role IN ('administrator', 'super_admin')
    AND p.status = 'active'
    -- Optional: Add branch filter if required
    -- AND (p.branch_id = jobs_with_driver.branch_id OR p.branch_id IS NULL)
)
SELECT 
  jwd.job_id,
  jwd.job_number,
  ar.recipient_id,
  ar.role as recipient_role,
  'job_start_deadline_warning_60min' as notification_type,
  60 as minutes_before_pickup
FROM jobs_with_driver jwd
CROSS JOIN admin_recipients ar;
```

**Note:** Cross join creates notification for each admin/super_admin. If branch scoping is required, add `WHERE ar.branch_id = jwd.branch_id OR ar.branch_id IS NULL`.

---

## 9. Deduplication Strategy

### Current Strategy: Query Existing Notifications

**Implementation:**
```typescript
// Check if notification already sent
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

**Pros:**
- ✅ Simple and reliable
- ✅ No schema changes needed
- ✅ Works across multiple recipients (per-user notifications)

**Cons:**
- ⚠️ Requires query on each cron run (minimal overhead)

**Recommendation:** ✅ **KEEP CURRENT APPROACH**

---

### Alternative: Timestamp Columns on Jobs Table

**Approach:**
- Add `jobs.escalation_notified_90min_at` (timestamptz, nullable)
- Add `jobs.escalation_notified_60min_at` (timestamptz, nullable)
- Update these columns when notification sent
- Check columns instead of querying `app_notifications`

**Pros:**
- ✅ Faster lookup (no query needed)
- ✅ Clear audit trail on jobs table

**Cons:**
- ❌ Requires schema migration
- ❌ Doesn't track per-recipient notifications
- ❌ More complex (need to update multiple recipients)

**Recommendation:** ❌ **NOT RECOMMENDED** (current approach is sufficient)

---

## 10. Edge Function Schedule + High-Level Pseudocode

### 10.1 Schedule Configuration

**Recommended:** Every 5 minutes

**Rationale:**
- 5-minute window ensures notifications are sent within the 85-90min and 55-60min windows
- Balances timely delivery with resource usage
- Matches typical cron job patterns

**Supabase Cron Syntax:**
```
*/5 * * * *  -- Every 5 minutes
```

**Configuration:**
- Supabase Dashboard → Edge Functions → Cron Jobs
- Function: `check-job-start-deadlines`
- Schedule: `*/5 * * * *`

---

### 10.2 High-Level Pseudocode

```typescript
serve(async (req) => {
  // 1. Initialize Supabase client (service role)
  const supabase = createClient(url, serviceKey)
  
  // 2. Get current time (UTC)
  const now = new Date()
  
  // 3. Call RPC to get jobs needing notifications
  const jobsNeedingNotifications = await supabase.rpc(
    'get_jobs_needing_start_deadline_notifications',
    { p_current_time: now.toISOString() }
  )
  
  // 4. For each job needing notification:
  for (const job of jobsNeedingNotifications) {
    // 4a. Check deduplication (existing notification)
    const existing = await checkExistingNotification(
      job.job_id, 
      job.notification_type
    )
    if (existing) continue
    
    // 4b. Get recipients based on role
    const recipients = await getRecipients(
      job.recipient_role,  // 'manager' or 'administrator'
      job.branch_id  // For branch scoping (if required)
    )
    
    // 4c. For each recipient:
    for (const recipient of recipients) {
      // 4c.1. Check preferences
      const prefs = await getPreferences(recipient.id)
      const categoryEnabled = checkCategoryPreference(
        prefs, 
        job.notification_type
      )
      if (!categoryEnabled) continue
      
      // 4c.2. Create in-app notification
      const notification = await createNotification({
        user_id: recipient.id,
        message: buildMessage(job),
        notification_type: job.notification_type,
        job_id: job.job_id.toString(),
        priority: 'high',
        action_data: {
          route: `/jobs/${job.job_id}/summary`,
          job_id: job.job_id.toString(),
          job_number: job.job_number,
          minutes_before_pickup: job.minutes_before
        }
      })
      
      // 4c.3. Check push preference and send if enabled
      const pushEnabled = checkPushPreference(prefs)
      if (pushEnabled) {
        await invokePushNotification(notification)
      }
    }
  }
  
  // 5. Return summary
  return {
    success: true,
    checked: jobsNeedingNotifications.length,
    notified: notifiedCount
  }
})
```

---

## 11. Minimal Schema Changes

### 11.1 Required Changes

**NONE** - Current schema supports the requirements.

**Existing Tables:**
- ✅ `app_notifications` - Supports all required fields
- ✅ `user_notification_preferences` - Supports category and channel preferences
- ✅ `jobs` - Has all required fields (`job_id`, `manager_id`, `branch_id`)
- ✅ `profiles` - Has all required fields (`id`, `role`, `branch_id`)
- ✅ `transport` - Has `pickup_date` field
- ✅ `driver_flow` - Has `job_started_at` field

---

### 11.2 Optional Enhancements (Not Required)

**Option 1: Add Notification Category Column**
- Add `category` column to `app_notifications` (e.g., 'escalation', 'assignment', 'status_change')
- **Rationale:** Better filtering and reporting
- **Recommendation:** Not needed for MVP

**Option 2: Add Escalation Timestamps to Jobs**
- Add `escalation_notified_90min_at` and `escalation_notified_60min_at`
- **Rationale:** Faster deduplication
- **Recommendation:** Not needed (current approach sufficient)

---

## 12. Test Plan

### 12.1 Driver Role Tests

**Test D-1: Driver Does NOT Receive Escalation Notifications**

**Setup:**
- Driver assigned to job
- Job due in 90 minutes, not started

**Expected:**
- ❌ Driver does NOT receive notification (escalations are for managers/admins only)

**Verification:**
- Query `app_notifications` where `user_id = driver_id`
- Confirm no escalation notifications

---

### 12.2 Manager Role Tests

**Test M-1: Manager Receives 90-Minute Warning**

**Setup:**
- Manager assigned to job (`jobs.manager_id`)
- Job due in 90 minutes (`transport.pickup_date`)
- Job not started (`driver_flow.job_started_at IS NULL`)
- Manager has `system_alerts = true` in preferences

**Steps:**
1. Invoke edge function manually
2. Check `app_notifications` for manager's notification
3. Verify notification type = `'job_start_deadline_warning_90min'`
4. Verify push notification sent (if `push_notifications = true`)
5. Verify in-app notification appears

**Expected:**
- ✅ Notification created
- ✅ Push notification sent (if enabled)
- ✅ In-app notification appears
- ✅ No duplicate on subsequent runs

---

**Test M-2: Manager Preference Disabled**

**Setup:**
- Manager assigned to job
- Job due in 90 minutes, not started
- Manager has `system_alerts = false` in preferences

**Expected:**
- ❌ No notification created

---

**Test M-3: Manager Not Assigned**

**Setup:**
- Job has no `manager_id`
- Job due in 90 minutes, not started

**Expected:**
- ❌ No notification created (no manager to notify)

---

### 12.3 Admin/Super_Admin Role Tests

**Test A-1: Admin Receives 60-Minute Warning**

**Setup:**
- Admin user (role = 'administrator')
- Job due in 60 minutes, not started
- Admin has `system_alerts = true` in preferences

**Steps:**
1. Invoke edge function manually
2. Check `app_notifications` for admin's notification
3. Verify notification type = `'job_start_deadline_warning_60min'`
4. Verify push notification sent (if enabled)

**Expected:**
- ✅ Notification created
- ✅ Push notification sent (if enabled)
- ✅ In-app notification appears

---

**Test A-2: Super_Admin Receives 60-Minute Warning**

**Setup:**
- Super_Admin user (role = 'super_admin')
- Job due in 60 minutes, not started
- Super_Admin has `system_alerts = true` in preferences

**Expected:**
- ✅ Notification created (same as admin)

---

**Test A-3: Branch Scoping (If Implemented)**

**Setup:**
- Job with `branch_id = 1`
- Admin A with `branch_id = 1`
- Admin B with `branch_id = 2`
- Job due in 60 minutes, not started

**Expected:**
- ✅ Admin A receives notification (same branch)
- ❌ Admin B does NOT receive notification (different branch)

---

**Test A-4: All Admins Receive (If Branch Scoping NOT Implemented)**

**Setup:**
- Job with `branch_id = 1`
- Admin A with `branch_id = 1`
- Admin B with `branch_id = 2`
- Job due in 60 minutes, not started

**Expected:**
- ✅ Admin A receives notification
- ✅ Admin B receives notification (no branch filter)

---

### 12.4 Edge Cases

**Test E-1: Job Started Before Notification**

**Setup:**
- Job due in 90 minutes
- Set `driver_flow.job_started_at = NOW()` (job started)

**Expected:**
- ❌ No notification created (job already started)

---

**Test E-2: Job Cancelled**

**Setup:**
- Job with `job_status = 'cancelled'`
- Job due in 90 minutes

**Expected:**
- ❌ No notification created (cancelled jobs excluded)

---

**Test E-3: No Transport Rows**

**Setup:**
- Job with no `transport` rows (no `pickup_date`)

**Expected:**
- ❌ No notification created (no pickup date to calculate)

---

**Test E-4: Multiple Transport Rows (Earliest Used)**

**Setup:**
- Job with multiple transport rows:
  - Transport 1: `pickup_date = NOW() + 90 minutes`
  - Transport 2: `pickup_date = NOW() + 120 minutes`

**Expected:**
- ✅ Uses earliest pickup_date (90 minutes)
- ✅ Notification created at 90-minute threshold

---

**Test E-5: Time Window Edge Cases**

**Setup:**
- Job due in exactly 90 minutes (on the boundary)
- Job due in exactly 60 minutes (on the boundary)
- Job due in 89 minutes (just outside 90min window)
- Job due in 59 minutes (just outside 60min window)

**Expected:**
- ✅ 90-minute job: Notification created (within 85-90min window)
- ✅ 60-minute job: Notification created (within 55-60min window)
- ❌ 89-minute job: No notification (outside window)
- ❌ 59-minute job: No notification (outside window)

---

## 13. Explicit NON-GOALS

### 13.1 What Will NOT Be Changed

**DO NOT Modify:**
- ❌ Flutter client code (notification creation, realtime subscriptions)
- ❌ `push-notifications` edge function (works correctly)
- ❌ `app_notifications` table schema (supports requirements)
- ❌ `user_notification_preferences` table schema (supports requirements)
- ❌ RLS policies on `app_notifications` (working correctly)
- ❌ Realtime subscription logic (working correctly)

**DO NOT Add:**
- ❌ New database triggers (using scheduled edge function approach)
- ❌ New notification tables (existing schema sufficient)
- ❌ New preference categories (existing `system_alerts` covers escalations)

**DO NOT Remove:**
- ❌ Existing `check-job-start-deadlines` edge function (will be updated, not replaced)
- ❌ Existing `get_jobs_needing_start_deadline_notifications` RPC (will be updated, not replaced)

---

### 13.2 Scope Limitations

**This Plan Does NOT Cover:**
- ❌ Other escalation thresholds (e.g., 30min, 15min)
- ❌ Escalation for other job states (e.g., overdue jobs, incomplete jobs)
- ❌ Email notifications (push and in-app only)
- ❌ SMS notifications
- ❌ Notification batching/aggregation
- ❌ Escalation to external systems (e.g., Slack, PagerDuty)

**Future Enhancements (Out of Scope):**
- Multiple escalation levels (e.g., 90min → 60min → 30min → 15min)
- Escalation chains (e.g., manager → admin → super_admin)
- Custom escalation rules per branch/client
- Escalation history/audit trail

---

## 14. Implementation Checklist

### Pre-Implementation

- [ ] Verify current cron schedule for `check-job-start-deadlines`
- [ ] Test existing RPC function with current thresholds
- [ ] Document preference schema mapping
- [ ] Decide on branch scoping requirement (yes/no)

### Phase 1: Update RPC Function

- [ ] Create migration: `20250122_update_job_start_deadline_rpc_60min.sql`
- [ ] Update 30min threshold → 60min in RPC function
- [ ] Update notification_type from `30min` → `60min`
- [ ] Test RPC function with sample data
- [ ] Verify RPC returns correct jobs

### Phase 2: Update Edge Function

- [ ] Update preference checking logic
- [ ] Map notification types to preference categories
- [ ] Add branch scoping (if required)
- [ ] Test edge function manually
- [ ] Verify notifications created correctly
- [ ] Verify push notifications sent (if enabled)

### Phase 3: Testing

- [ ] Test manager 90-minute notification
- [ ] Test admin 60-minute notification
- [ ] Test preference filtering
- [ ] Test deduplication
- [ ] Test edge cases (job started, cancelled, etc.)

### Phase 4: Deployment

- [ ] Apply RPC migration
- [ ] Deploy updated edge function
- [ ] Verify cron schedule is active
- [ ] Monitor logs for first 24 hours
- [ ] Verify delivery logs show attempts

---

## 15. Summary

### Current State
- ✅ Edge function exists and is deployed
- ✅ RPC function exists and is functional
- ✅ Notification pipeline works (in-app + push)
- ⚠️ Threshold mismatch: 30min vs required 60min
- ⚠️ Preference checking may need alignment

### Required Changes
1. **Update RPC function:** Change 30min → 60min threshold
2. **Update edge function:** Align preference checking with table schema
3. **Add branch scoping:** If required (decision needed)

### Risk Assessment
- **Low Risk:** Incremental update to existing working code
- **Low Risk:** No schema changes required
- **Medium Risk:** Preference logic changes (needs testing)

### Success Criteria
- ✅ Managers receive 90-minute warnings
- ✅ Admins/super_admins receive 60-minute warnings
- ✅ Preferences are respected (category + channel)
- ✅ No duplicate notifications
- ✅ Push notifications work (if enabled)
- ✅ In-app notifications appear (realtime)

---

**End of Plan Document**

