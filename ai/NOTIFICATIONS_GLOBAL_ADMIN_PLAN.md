# Global Admin Notifications Implementation Plan

**Date:** 2025-01-22  
**Status:** Audit Complete - Implementation Plan Ready  
**Objective:** Ensure administrators and super_admins receive notifications globally (no branch_id restrictions), while managers remain job/assignment scoped.

---

## Executive Summary

**Current State:**
- ✅ Edge function `check-job-start-deadlines` queries recipients without branch filtering
- ✅ RPC function `get_jobs_needing_start_deadline_notifications` does not filter by branch
- ✅ Edge function recipient query: `.in('role', ['administrator', 'super_admin']).eq('status', 'active')` - **NO branch_id filter**
- ⚠️ **RLS Policy:** `allow_users_view_own` restricts SELECT to `user_id = auth.uid()` - **BLOCKS global admin visibility**
- ✅ Flutter app queries notifications with `user_id` filter (RLS enforced)

**Key Finding:**
- **Recipient Selection:** ✅ Already global (no branch_id filter in edge function)
- **RLS Visibility:** ❌ **BLOCKED** - Admins can only see their own notifications, not all notifications

**Required Changes:**
1. **RLS Policy Update:** Add policy to allow admins/super_admin to SELECT all notifications
2. **Verification:** Confirm no branch_id filters exist in recipient queries
3. **Flutter Query (Optional):** May need to update if admin-specific queries are needed

---

## 1. Audit Results

### 1.1 Recipient Selection in Edge Functions

#### A) `check-job-start-deadlines` Edge Function

**File:** `supabase/functions/check-job-start-deadlines/index.ts`

**Current Code (Lines 89-99):**
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

**Analysis:**
- ✅ **NO branch_id filter** - Queries all active administrators and super_admins globally
- ✅ **Correct role handling** - Includes both 'administrator' and 'super_admin' for 60-min escalation
- ✅ **Manager handling** - For 90-min warning, queries only 'manager' role (job-scoped via `jobs.manager_id`)

**Conclusion:** ✅ **ALREADY GLOBAL** - No changes needed to recipient selection.

---

#### B) RPC Function `get_jobs_needing_start_deadline_notifications`

**Current Logic:**
- Returns `recipient_role = 'manager'` for 90-min threshold
- Returns `recipient_role = 'administrator'` for 30-min threshold (to be updated to 60-min)

**Analysis:**
- ✅ **NO branch_id filtering** in RPC function
- ✅ Returns role name only, not specific user IDs
- ✅ Edge function handles recipient selection (already global)

**Conclusion:** ✅ **NO CHANGES NEEDED** - RPC function does not filter by branch.

---

#### C) `push-notifications` Edge Function

**File:** `supabase/functions/push-notifications/index.ts`

**Current Code (Lines 205-209):**
```typescript
// Get user's FCM tokens and notification preferences from profiles table
const { data: profile, error: profileError } = await supabase
  .from('profiles')
  .select('fcm_token, fcm_token_web, display_name, notification_prefs')
  .eq('id', notification.user_id)
  .single()
```

**Analysis:**
- ✅ **NO branch_id filtering** - Fetches profile by `user_id` only
- ✅ Works for any user (admin, manager, driver)
- ✅ FCM tokens retrieved globally

**Conclusion:** ✅ **NO CHANGES NEEDED** - Push function already works globally.

---

### 1.2 Current Escalation Logic

#### 90-Minute Warning (Manager)

**Current Implementation:**
- **RPC Function:** Returns `recipient_role = 'manager'`
- **Edge Function:** Queries `profiles` where `role = 'manager'` and `status = 'active'`
- **Issue:** This queries ALL managers globally, not just the job's manager

**Expected Behavior:**
- ✅ **Manager should be job-scoped** - Only notify `jobs.manager_id` for that specific job
- ❌ **Current bug:** Edge function queries all managers, not just the assigned manager

**Required Fix:**
- For 90-min warning, query should filter by `jobs.manager_id` (job-scoped)
- Edge function should use `job.manager_id` from RPC result, not query all managers

**Evidence:**
- RPC function does NOT return `manager_id` in result set
- Edge function queries all managers globally (incorrect for 90-min warning)

---

#### 60-Minute Escalation (Admin/Super_Admin)

**Current Implementation:**
- **RPC Function:** Returns `recipient_role = 'administrator'` (30-min currently, to be updated to 60-min)
- **Edge Function:** Queries `profiles` where `role IN ('administrator', 'super_admin')` and `status = 'active'`
- ✅ **NO branch_id filter** - Already global

**Expected Behavior:**
- ✅ **Admins should be global** - All active administrators and super_admins receive notifications
- ✅ **Current implementation is correct** - No branch filtering

**Conclusion:** ✅ **ALREADY GLOBAL** - No changes needed for 60-min escalation recipient selection.

---

### 1.3 RLS and Visibility

#### A) RLS Policies on `app_notifications`

**Current Policies:**
1. `allow_authenticated_insert` - Any authenticated user can INSERT
2. `allow_service_role_all` - Service role has full access
3. `allow_anon_insert` - Anonymous can INSERT (for webhooks)
4. `allow_users_view_own` - Users can SELECT their own (`user_id = auth.uid()`)
5. `allow_users_update_own` - Users can UPDATE their own

**Critical Finding:**
- ❌ **`allow_users_view_own`** restricts SELECT to `user_id = auth.uid()`
- ❌ **NO policy exists** for admins/super_admin to SELECT all notifications
- ❌ **Admins can only see their own notifications**, not all notifications globally

**Required Fix:**
- Add new RLS policy: `allow_admins_view_all`
- Policy should allow `role IN ('administrator', 'super_admin')` to SELECT all rows
- Policy should use `profiles.role` check via JOIN or subquery

---

#### B) Flutter Notification Queries

**File:** `lib/features/notifications/services/notification_service.dart`

**Current Code (Lines 32-40):**
```dart
final response = await _supabase
    .from('app_notifications')
    .select()
    .eq('user_id', currentUser.id)  // ← Filters by current user
    .order('created_at', descending: true)
    .limit(limit);
```

**Analysis:**
- ✅ **Correct for regular users** - Filters by `user_id`
- ⚠️ **May need admin override** - Admins should see all notifications if RLS allows
- ⚠️ **Current query enforces user_id filter** - Even if RLS allows global access, query restricts it

**Required Fix:**
- Check user role in Flutter
- If role is 'administrator' or 'super_admin', remove `.eq('user_id', ...)` filter
- Rely on RLS policy to enforce security

---

### 1.4 FCM Token Retrieval Logic

**Current Implementation:**
- `push-notifications` edge function fetches profile by `user_id` only
- ✅ **NO branch_id filtering** - Works globally
- ✅ **FCM tokens retrieved correctly** for any user

**Conclusion:** ✅ **NO CHANGES NEEDED** - Token retrieval already works globally.

---

## 2. Root Cause Analysis

### 2.1 Recipient Selection

**Status:** ✅ **ALREADY GLOBAL**

**Evidence:**
- Edge function queries: `.in('role', ['administrator', 'super_admin']).eq('status', 'active')`
- No `.eq('branch_id', ...)` filter present
- All active admins/super_admins are selected globally

**Conclusion:** No changes needed to recipient selection logic.

---

### 2.2 RLS Visibility

**Status:** ❌ **BLOCKED**

**Root Cause:**
- `allow_users_view_own` policy restricts SELECT to `user_id = auth.uid()`
- No policy exists for admins to SELECT all notifications
- Admins can only see notifications where `user_id = auth.uid()`

**Impact:**
- Admins receive notifications (created by edge function with their `user_id`)
- Admins can see their own notifications
- ❌ **Admins cannot see notifications for other users** (even if they should have global visibility)

**Required Fix:**
- Add RLS policy to allow admins/super_admin to SELECT all rows
- Update Flutter query to remove `user_id` filter for admins

---

### 2.3 Manager Scoping Issue

**Status:** ⚠️ **BUG IDENTIFIED**

**Root Cause:**
- Edge function queries ALL managers globally for 90-min warning
- Should only notify `jobs.manager_id` for that specific job
- RPC function does not return `manager_id` in result set

**Impact:**
- All managers receive 90-min warnings for all jobs (incorrect)
- Should only notify the assigned manager for each job

**Required Fix:**
- Update RPC function to return `manager_id` for 90-min threshold
- Update edge function to filter by `manager_id` for manager role

**Note:** This is a separate bug fix, not part of global admin requirements.

---

## 3. Implementation Plan

### Phase 1: Add RLS Policy for Global Admin Visibility

**Goal:** Allow administrators and super_admins to SELECT all notifications.

**Migration File:** `supabase/migrations/20250122_add_admin_global_notification_rls.sql`

**SQL:**
```sql
BEGIN;

-- Add RLS policy to allow admins/super_admin to SELECT all notifications
CREATE POLICY "allow_admins_view_all_notifications"
ON public.app_notifications
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('administrator', 'super_admin')
    AND profiles.status = 'active'
  )
);

COMMENT ON POLICY "allow_admins_view_all_notifications" ON public.app_notifications IS 
'Allows administrators and super_admins to view all notifications globally, regardless of user_id';

COMMIT;
```

**Verification Query:**
```sql
-- Verify policy exists
SELECT policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public' 
AND tablename = 'app_notifications'
AND policyname = 'allow_admins_view_all_notifications';

-- Expected: 1 row with cmd = 'SELECT', roles = '{authenticated}'
```

**Files to Create:**
- `supabase/migrations/20250122_add_admin_global_notification_rls.sql`

**Risk:** Low (additive policy, doesn't break existing behavior)

---

### Phase 2: Update Flutter Notification Query

**Goal:** Remove `user_id` filter for admins/super_admin in Flutter queries.

**File:** `lib/features/notifications/services/notification_service.dart`

**Current Code (Lines 32-40):**
```dart
final response = await _supabase
    .from('app_notifications')
    .select()
    .eq('user_id', currentUser.id)  // ← Always filters by user_id
    .order('created_at', descending: true)
    .limit(limit);
```

**Updated Code:**
```dart
// Get current user profile to check role
final profileResponse = await _supabase
    .from('profiles')
    .select('role')
    .eq('id', currentUser.id)
    .single();

final userRole = profileResponse['role'] as String?;
final isAdmin = userRole == 'administrator' || userRole == 'super_admin';

// Build query
var query = _supabase
    .from('app_notifications')
    .select()
    .order('created_at', descending: true)
    .limit(limit);

// Only filter by user_id if not admin (admins see all via RLS)
if (!isAdmin) {
  query = query.eq('user_id', currentUser.id);
}

final response = await query;
```

**Alternative Approach (Cache Role):**
- Cache user role in app state (already available in user profile provider)
- Use cached role to determine query filter
- Avoids extra database query on each notification fetch

**Files to Modify:**
- `lib/features/notifications/services/notification_service.dart` (Lines 32-40, and similar queries)

**Risk:** Medium (changes query logic, needs testing)

---

### Phase 3: Verify No Branch Filtering

**Goal:** Confirm no branch_id filters exist in recipient queries.

**Verification Steps:**
1. ✅ **Edge Function:** Already verified - no branch_id filter (Line 95-99)
2. ✅ **RPC Function:** Already verified - no branch_id filter
3. ✅ **Push Function:** Already verified - no branch_id filter
4. ✅ **Flutter Queries:** Already verified - no branch_id filter

**Conclusion:** ✅ **NO CHANGES NEEDED** - No branch filtering exists.

---

### Phase 4: Fix Manager Scoping (Separate Bug)

**Goal:** Ensure 90-min warnings only notify the assigned manager, not all managers.

**Note:** This is a separate bug fix, not part of global admin requirements. Documented here for completeness.

**Required Changes:**
1. Update RPC function to return `manager_id` for 90-min threshold
2. Update edge function to filter by `manager_id` for manager role

**Files to Modify:**
- `supabase/migrations/20250122_fix_manager_notification_scoping.sql` (new migration)
- `supabase/functions/check-job-start-deadlines/index.ts` (update recipient query)

**Implementation:**
```typescript
// In edge function, for manager role:
if (recipient_role === 'manager') {
  // Get manager_id from job (should be returned by RPC)
  const { data: job } = await supabase
    .from('jobs')
    .select('manager_id')
    .eq('id', job_id)
    .single();
  
  if (!job?.manager_id) {
    console.log(`No manager assigned to job ${job_id}, skipping`)
    continue
  }
  
  // Query only the assigned manager
  const { data: recipients } = await supabase
    .from('profiles')
    .select('id, role, notification_prefs')
    .eq('id', job.manager_id)
    .eq('status', 'active')
    .maybeSingle()
  
  if (!recipients) {
    console.log(`Manager ${job.manager_id} not found or inactive`)
    continue
  }
  
  // Process single manager
  recipients = [recipients]
} else {
  // For admin/super_admin: query all globally (existing logic)
  const { data: recipients } = await supabase
    .from('profiles')
    .select('id, role, notification_prefs')
    .in('role', rolesToQuery)
    .eq('status', 'active')
}
```

**Risk:** Medium (changes manager notification logic)

---

## 4. Exact File Changes

### 4.1 Database Migration

**File:** `supabase/migrations/20250122_add_admin_global_notification_rls.sql`

**Content:**
```sql
BEGIN;

-- Add RLS policy to allow admins/super_admin to SELECT all notifications
CREATE POLICY "allow_admins_view_all_notifications"
ON public.app_notifications
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM public.profiles
    WHERE profiles.id = auth.uid()
    AND profiles.role IN ('administrator', 'super_admin')
    AND profiles.status = 'active'
  )
);

COMMENT ON POLICY "allow_admins_view_all_notifications" ON public.app_notifications IS 
'Allows administrators and super_admins to view all notifications globally, regardless of user_id';

COMMIT;
```

---

### 4.2 Flutter Service Update

**File:** `lib/features/notifications/services/notification_service.dart`

**Method:** `getNotifications({int limit = 50})`

**Before (Lines 32-40):**
```dart
final response = await _supabase
    .from('app_notifications')
    .select()
    .eq('user_id', currentUser.id)
    .order('created_at', descending: true)
    .limit(limit);
```

**After:**
```dart
// Check if user is admin/super_admin
final profileResponse = await _supabase
    .from('profiles')
    .select('role')
    .eq('id', currentUser.id)
    .single();

final userRole = profileResponse['role'] as String?;
final isAdmin = userRole == 'administrator' || userRole == 'super_admin';

// Build query - admins see all, others see only their own
var query = _supabase
    .from('app_notifications')
    .select()
    .order('created_at', descending: true)
    .limit(limit);

if (!isAdmin) {
  query = query.eq('user_id', currentUser.id);
}

final response = await query;
```

**Alternative (Using Cached Profile):**
If user profile is already cached in app state:
```dart
// Get role from cached profile (if available)
final userProfile = ref.read(userProfileProvider).value;
final isAdmin = userProfile?.role == 'administrator' || userProfile?.role == 'super_admin';

var query = _supabase
    .from('app_notifications')
    .select()
    .order('created_at', descending: true)
    .limit(limit);

if (!isAdmin) {
  query = query.eq('user_id', currentUser.id);
}

final response = await query;
```

**Other Methods to Update:**
- `getNotificationsStream()` (Line 653) - Real-time subscription
- `getUnreadNotifications()` (if exists)
- Any other notification query methods

---

## 5. Verification SQL Queries

### 5.1 Verify RLS Policy Exists

```sql
-- Check policy exists
SELECT 
  policyname,
  cmd as command_type,
  roles,
  CASE WHEN qual IS NOT NULL THEN 'HAS USING' ELSE 'NO USING' END as has_using
FROM pg_policies
WHERE schemaname = 'public' 
AND tablename = 'app_notifications'
AND policyname = 'allow_admins_view_all_notifications';

-- Expected: 1 row
-- policyname: 'allow_admins_view_all_notifications'
-- cmd: 'SELECT'
-- roles: '{authenticated}'
-- has_using: 'HAS USING'
```

---

### 5.2 Verify Admin Users

```sql
-- Count active admins/super_admins
SELECT 
  role,
  COUNT(*) as total,
  COUNT(CASE WHEN status = 'active' THEN 1 END) as active_count,
  COUNT(CASE WHEN branch_id IS NOT NULL THEN 1 END) as with_branch,
  COUNT(CASE WHEN branch_id IS NULL THEN 1 END) as without_branch
FROM public.profiles
WHERE role IN ('administrator', 'super_admin')
GROUP BY role;

-- Expected: Should show all admins are active and may have branch_id (but notifications are global)
```

---

### 5.3 Verify Notification Creation (Edge Function)

```sql
-- Check recent escalation notifications
SELECT 
  an.id,
  an.user_id,
  an.notification_type,
  an.job_id,
  an.created_at,
  p.role,
  p.branch_id
FROM public.app_notifications an
INNER JOIN public.profiles p ON an.user_id = p.id
WHERE an.notification_type IN (
  'job_start_deadline_warning_90min',
  'job_start_deadline_warning_60min',
  'job_start_deadline_warning_30min'
)
AND an.created_at > NOW() - INTERVAL '7 days'
ORDER BY an.created_at DESC
LIMIT 20;

-- Expected: Should show notifications for admins/super_admins from various branches
-- (if branch_id is set, but notifications are still global)
```

---

### 5.4 Test RLS Policy (As Admin User)

```sql
-- Run as admin user (via Supabase client with admin JWT)
-- Should return all notifications, not just admin's own
SELECT 
  COUNT(*) as total_notifications,
  COUNT(DISTINCT user_id) as unique_users,
  COUNT(CASE WHEN notification_type LIKE '%deadline%' THEN 1 END) as escalation_notifications
FROM public.app_notifications;

-- Expected: Admin should see all notifications (not just their own)
-- If policy works, count should be > 0 and include notifications for other users
```

---

### 5.5 Verify No Branch Filtering in Edge Function

**Manual Code Review:**
- ✅ `supabase/functions/check-job-start-deadlines/index.ts` Line 95-99: No `.eq('branch_id', ...)` filter
- ✅ RPC function: No branch_id filtering
- ✅ Push function: No branch_id filtering

**SQL Verification:**
```sql
-- Check if any notifications were created with branch filtering
-- (This is a sanity check - code review is primary verification)
SELECT 
  COUNT(*) as total_escalation_notifications,
  COUNT(DISTINCT user_id) as unique_recipients,
  COUNT(DISTINCT 
    (SELECT branch_id FROM public.profiles WHERE id = an.user_id)
  ) as unique_branches
FROM public.app_notifications an
WHERE an.notification_type IN (
  'job_start_deadline_warning_90min',
  'job_start_deadline_warning_60min',
  'job_start_deadline_warning_30min'
)
AND an.created_at > NOW() - INTERVAL '30 days';

-- Expected: unique_branches should match number of branches with active admins
-- (If admins are from different branches, all should receive notifications)
```

---

## 6. Manual QA Steps

### Test 1: Admin Receives 60-Minute Escalation (Global)

**Setup:**
- Create job with `pickup_date` = 60 minutes from now
- Ensure `driver_flow.job_started_at IS NULL`
- Ensure at least 2 active administrators exist (from different branches if possible)
- Ensure admins have `system_alerts = true` in preferences

**Steps:**
1. Invoke `check-job-start-deadlines` edge function manually
2. Check `app_notifications` table:
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
   WHERE an.notification_type = 'job_start_deadline_warning_60min'
   AND an.job_id = '<job_id>'
   ORDER BY an.created_at DESC;
   ```
3. Verify push notifications sent (check `notification_delivery_log`)
4. Login as admin in Flutter app
5. Check notification list - should see escalation notification

**Expected:**
- ✅ All active administrators receive notification (regardless of branch_id)
- ✅ All active super_admins receive notification (regardless of branch_id)
- ✅ Push notifications sent (if preferences enabled)
- ✅ In-app notifications appear for all admins
- ✅ Admin can see notification in Flutter app

---

### Test 2: Admin Can See All Notifications (RLS)

**Setup:**
- Create test notifications for different users (driver, manager, admin)
- Login as administrator in Flutter app

**Steps:**
1. Open notification list in Flutter app
2. Verify admin sees:
   - Their own notifications
   - Notifications for other users (if RLS allows)
3. Check notification count - should be > admin's own notifications

**Expected:**
- ✅ Admin sees all notifications (not just their own)
- ✅ Notification count includes notifications for other users
- ✅ RLS policy allows global access

**If Test Fails:**
- Check RLS policy exists: `allow_admins_view_all_notifications`
- Check Flutter query removes `user_id` filter for admins
- Verify admin role in `profiles` table

---

### Test 3: Manager Receives 90-Minute Warning (Job-Scoped)

**Setup:**
- Create job with `pickup_date` = 90 minutes from now
- Assign manager to job (`jobs.manager_id`)
- Ensure `driver_flow.job_started_at IS NULL`
- Ensure manager has `system_alerts = true` in preferences

**Steps:**
1. Invoke `check-job-start-deadlines` edge function manually
2. Check `app_notifications` table:
   ```sql
   SELECT 
     an.id,
     an.user_id,
     an.notification_type,
     an.job_id,
     p.role
   FROM public.app_notifications an
   INNER JOIN public.profiles p ON an.user_id = p.id
   WHERE an.notification_type = 'job_start_deadline_warning_90min'
   AND an.job_id = '<job_id>'
   ORDER BY an.created_at DESC;
   ```
3. Verify only the assigned manager receives notification

**Expected:**
- ✅ Only `jobs.manager_id` receives notification
- ✅ Other managers do NOT receive notification
- ✅ Manager can see notification in Flutter app

**Note:** This test verifies manager scoping (separate bug fix).

---

### Test 4: Super_Admin Receives 60-Minute Escalation (Global)

**Setup:**
- Create job with `pickup_date` = 60 minutes from now
- Ensure `driver_flow.job_started_at IS NULL`
- Ensure at least 1 active super_admin exists
- Ensure super_admin has `system_alerts = true` in preferences

**Steps:**
1. Invoke `check-job-start-deadlines` edge function manually
2. Check `app_notifications` table for super_admin
3. Login as super_admin in Flutter app
4. Check notification list

**Expected:**
- ✅ Super_admin receives notification (regardless of branch_id)
- ✅ Super_admin can see all notifications (RLS allows)
- ✅ Push notification sent (if enabled)

---

### Test 5: Driver Does NOT Receive Escalation

**Setup:**
- Create job with `pickup_date` = 60 minutes from now
- Assign driver to job
- Ensure `driver_flow.job_started_at IS NULL`

**Steps:**
1. Invoke `check-job-start-deadlines` edge function manually
2. Check `app_notifications` table for driver's user_id

**Expected:**
- ❌ Driver does NOT receive escalation notification
- ✅ Only managers (90-min) and admins/super_admins (60-min) receive notifications

---

### Test 6: Branch Independence (Global Admin)

**Setup:**
- Create job with `branch_id = 1`
- Ensure admin A has `branch_id = 1`
- Ensure admin B has `branch_id = 2` (different branch)
- Ensure admin C has `branch_id = NULL` (no branch)
- Create job with `pickup_date` = 60 minutes from now

**Steps:**
1. Invoke `check-job-start-deadlines` edge function manually
2. Check `app_notifications` for all three admins

**Expected:**
- ✅ Admin A receives notification (same branch as job)
- ✅ Admin B receives notification (different branch - **GLOBAL**)
- ✅ Admin C receives notification (no branch - **GLOBAL**)
- ✅ All admins receive notifications regardless of branch_id

---

## 7. Summary of Changes

### Files to Create:
1. `supabase/migrations/20250122_add_admin_global_notification_rls.sql` - RLS policy for global admin visibility

### Files to Modify:
1. `lib/features/notifications/services/notification_service.dart` - Remove `user_id` filter for admins in queries

### Files to Verify (No Changes):
1. `supabase/functions/check-job-start-deadlines/index.ts` - ✅ Already global (no branch filter)
2. `supabase/functions/push-notifications/index.ts` - ✅ Already global (no branch filter)
3. RPC function `get_jobs_needing_start_deadline_notifications` - ✅ No branch filter

### Risk Assessment:
- **RLS Policy:** Low risk (additive, doesn't break existing behavior)
- **Flutter Query:** Medium risk (changes query logic, needs testing)
- **Overall:** Low-Medium risk (minimal changes, well-scoped)

---

## 8. Implementation Checklist

### Pre-Implementation
- [ ] Review current RLS policies on `app_notifications`
- [ ] Verify admin/super_admin user counts and roles
- [ ] Test current notification visibility (as admin user)

### Phase 1: RLS Policy
- [ ] Create migration file: `20250122_add_admin_global_notification_rls.sql`
- [ ] Apply migration to database
- [ ] Verify policy exists: `allow_admins_view_all_notifications`
- [ ] Test RLS policy (as admin user, query all notifications)

### Phase 2: Flutter Query Update
- [ ] Update `getNotifications()` method in `notification_service.dart`
- [ ] Update `getNotificationsStream()` method (if needed)
- [ ] Test admin user can see all notifications in Flutter app
- [ ] Test regular user still sees only their notifications

### Phase 3: Verification
- [ ] Run all QA tests (Test 1-6)
- [ ] Verify no branch filtering in edge functions
- [ ] Verify admins receive 60-min escalations globally
- [ ] Verify managers receive 90-min warnings (job-scoped)

### Phase 4: Documentation
- [ ] Document RLS policy behavior
- [ ] Document Flutter query behavior for admins
- [ ] Update API documentation if needed

---

## 9. Non-Goals (Out of Scope)

**This plan does NOT cover:**
- ❌ Manager scoping fix (separate bug, documented but not implemented)
- ❌ 30-min to 60-min threshold update (separate requirement)
- ❌ Preference filtering enhancements
- ❌ Notification batching/aggregation
- ❌ Email notifications
- ❌ SMS notifications

**Future Enhancements (Out of Scope):**
- Admin notification dashboard (all notifications view)
- Notification filtering by type/category for admins
- Branch-specific notification preferences (if needed)

---

**End of Plan Document**

