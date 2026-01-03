# Job Deadline Notification Implementation Summary

**Date:** 2026-01-04  
**Status:** Implementation Complete  
**Purpose:** Fix job start deadline notifications to match requirements (T-60 threshold, manager scoping)

---

## Changes Summary

### 1. Database Migration
**File:** `supabase/migrations/20260104000000_fix_job_deadline_notifications.sql`

**Changes:**
- ✅ Updated RPC function `get_jobs_needing_start_deadline_notifications`:
  - Added `manager_id uuid` to return type
  - Changed admin threshold from T-30 (25-30 min) to T-60 (55-60 min)
  - Updated `notification_type` from `job_start_deadline_warning_30min` to `job_start_deadline_warning_60min`
  - Updated `minutes_before` from 30 to 60 for admin notifications
  - Updated function comment to reflect 60-minute threshold

**Key SQL Changes:**
```sql
-- Before: 30-25 minutes window
WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '30 minutes'
     AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '25 minutes'
THEN 30

-- After: 60-55 minutes window
WHEN (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) <= INTERVAL '60 minutes'
     AND (jwd.earliest_pickup_date::timestamp with time zone - v_current_sa_time) >= INTERVAL '55 minutes'
THEN 60
```

**Return Type:**
```sql
RETURNS TABLE (
  job_id bigint,
  job_number text,
  driver_name text,
  manager_id uuid,  -- NEW: Added for manager scoping
  pickup_date timestamp without time zone,
  minutes_before integer,
  notification_type text,
  recipient_role text
)
```

---

### 2. Edge Function Updates
**File:** `supabase/functions/check-job-start-deadlines/index.ts`

**Changes:**
- ✅ Extract `manager_id` from RPC result
- ✅ **Fixed manager scoping:** Query only `jobs.manager_id` (not all managers globally)
- ✅ **Preserved admin global scope:** Query all active administrators + super_admins
- ✅ Updated comment to reflect 60-minute threshold

**Key Code Changes:**

**Before (Lines 89-99):**
```typescript
// Get all users with the target role (including notification preferences)
// For administrator role, also include super_admin
const rolesToQuery = recipient_role === 'administrator' 
  ? ['administrator', 'super_admin']
  : [recipient_role]

const { data: recipients, error: recipientsError } = await supabase
  .from('profiles')
  .select('id, role, notification_prefs')
  .in('role', rolesToQuery)
  .eq('status', 'active')
```

**After (Lines 89-130):**
```typescript
// Get recipients based on role
let recipients: any[] = []
let recipientsError: any = null

if (recipient_role === 'manager') {
  // Manager notification: ONLY the assigned manager for this job
  if (!manager_id) {
    console.log(`Job ${job_id} has no manager_id, skipping manager notification`)
    continue
  }
  
  const { data: managerProfile, error: managerError } = await supabase
    .from('profiles')
    .select('id, role, notification_prefs')
    .eq('id', manager_id)
    .eq('role', 'manager')  // Defense-in-depth: verify role
    .eq('status', 'active')
    .maybeSingle()

  if (managerError) {
    console.error(`Error fetching manager ${manager_id} for job ${job_id}:`, managerError)
    errors.push(`Job ${job_id}: ${managerError.message}`)
    continue
  }

  if (!managerProfile) {
    console.log(`Manager ${manager_id} not found or not active for job ${job_id}`)
    continue
  }

  recipients = [managerProfile]
} else if (recipient_role === 'administrator') {
  // Administrator escalation: ALL active administrators + super_admins globally
  const { data: adminRecipients, error: adminError } = await supabase
    .from('profiles')
    .select('id, role, notification_prefs')
    .in('role', ['administrator', 'super_admin'])
    .eq('status', 'active')

  recipientsError = adminError
  recipients = adminRecipients || []
} else {
  console.error(`Unknown recipient_role: ${recipient_role} for job ${job_id}`)
  errors.push(`Job ${job_id}: Unknown recipient_role ${recipient_role}`)
  continue
}
```

**Comment Update (Line 34):**
```typescript
// Before: "Check if we're 90 minutes before or 30 minutes before pickup"
// After: "Check if we're 90 minutes before (manager) or 60 minutes before (administrator) pickup"
```

---

### 3. Flutter Constants Updates
**File:** `lib/core/constants/notification_constants.dart`

**Changes:**
- ✅ Replaced `jobStartDeadlineWarning30min` with `jobStartDeadlineWarning60min`
- ✅ Updated `allNotificationTypes` list
- ✅ Updated `getNotificationTypeDisplayName()` switch case
- ✅ Updated `getNotificationTypeDescription()` switch case

**Key Changes:**

**Line 14:**
```dart
// Before:
static const String jobStartDeadlineWarning30min = 'job_start_deadline_warning_30min';

// After:
static const String jobStartDeadlineWarning60min = 'job_start_deadline_warning_60min';
```

**Line 29:**
```dart
// Before:
jobStartDeadlineWarning30min,

// After:
jobStartDeadlineWarning60min,
```

**Line 97-98:**
```dart
// Before:
case jobStartDeadlineWarning30min:
  return 'Job Start Warning (30 min)';

// After:
case jobStartDeadlineWarning60min:
  return 'Job Start Warning (60 min)';
```

**Line 132-133:**
```dart
// Before:
case jobStartDeadlineWarning30min:
  return 'Receive push notifications 30 minutes before pickup if job hasn\'t started';

// After:
case jobStartDeadlineWarning60min:
  return 'Receive push notifications 60 minutes before pickup if job hasn\'t started';
```

---

### 4. Edge Function Notification Type Updates
**Files:**
- `supabase/functions/push-notifications/index.ts`
- `supabase/functions/push-notifications-poller/index.ts`

**Changes:**
- ✅ Updated `getNotificationTitle()` to handle `job_start_deadline_warning_60min`
- ✅ Updated `getActionFromNotificationType()` to handle `job_start_deadline_warning_60min`

**Key Changes in `push-notifications/index.ts`:**

**Lines 445-475:**
```typescript
// Before:
case 'job_start_deadline_warning_30min':
  return 'Job Start Urgent Warning'

// After:
case 'job_start_deadline_warning_60min':
  return 'Job Start Urgent Warning'
```

**Lines 497-499:**
```typescript
// Before:
case 'job_start_deadline_warning_30min':

// After:
case 'job_start_deadline_warning_60min':
```

**Key Changes in `push-notifications-poller/index.ts`:**

**Lines 118-149:**
```typescript
// Before:
case 'job_start_deadline_warning_30min':
case 'job_start_deadline_warning_60min':
  return 'Job Start Urgent Warning'

// After:
case 'job_start_deadline_warning_60min':
  return 'Job Start Urgent Warning'
```

**Lines 171-173:**
```typescript
// Already includes job_start_deadline_warning_60min (no change needed)
case 'job_start_deadline_warning_60min':
  return 'job_status_changed'
```

---

## Verification

### Migration Applied
✅ Migration `20260104000000_fix_job_deadline_notifications.sql` applied successfully

### RPC Function Verified
✅ Function signature includes `manager_id uuid`:
```sql
RETURNS TABLE (
  job_id bigint,
  job_number text,
  driver_name text,
  manager_id uuid,  -- ✅ Present
  pickup_date timestamp without time zone,
  minutes_before integer,
  notification_type text,
  recipient_role text
)
```

---

## Behavior Changes

### Before
1. **Manager notifications:** All active managers globally received notifications for all jobs
2. **Admin threshold:** T-30 minutes (25-30 minute window)
3. **Notification type:** `job_start_deadline_warning_30min`

### After
1. **Manager notifications:** Only `jobs.manager_id` receives notification for their assigned job
2. **Admin threshold:** T-60 minutes (55-60 minute window)
3. **Notification type:** `job_start_deadline_warning_60min`

---

## Preserved Behaviors

✅ **Deduplication:** Still uses `job_id` + `notification_type` check  
✅ **Job started prevention:** RPC still filters by `df.job_started_at IS NULL`  
✅ **Cron window logic:** 5-minute windows preserved (85-90, 55-60)  
✅ **Admin global scope:** Administrators and super_admins still receive notifications globally (no branch_id filter)

---

## Files Modified

1. ✅ `supabase/migrations/20260104000000_fix_job_deadline_notifications.sql` (NEW)
2. ✅ `supabase/functions/check-job-start-deadlines/index.ts`
3. ✅ `lib/core/constants/notification_constants.dart`
4. ✅ `supabase/functions/push-notifications/index.ts`
5. ✅ `supabase/functions/push-notifications-poller/index.ts`

---

## Next Steps

1. **Deploy Edge Function:**
   ```bash
   supabase functions deploy check-job-start-deadlines
   ```

2. **Run QA Checklist:**
   - See `ai/JOB_DEADLINE_NOTIFICATION_QA_CHECKLIST.md`
   - Test manager scoping (only assigned manager receives notification)
   - Test admin escalation (all admins receive notification at T-60)
   - Test job started prevention (no notifications if job started)
   - Test deduplication (no duplicate notifications)

3. **Monitor:**
   - Check Edge Function logs for correct recipient selection
   - Verify notification types in database are `job_start_deadline_warning_60min` (not 30min)
   - Confirm manager notifications go only to assigned managers

---

**End of Implementation Summary**

