# Notification Role Experience Specification

**Date:** 2025-01-22  
**Status:** Audit Complete - Specification Ready  
**Objective:** Define the complete notification experience per role (driver, manager, admin, super_admin) including push eligibility, in-app visibility, and preference enforcement.

---

## Executive Summary

**Current State:**
- ✅ In-app notifications work for all roles (RLS allows users to see their own)
- ✅ Push notifications work for client-initiated notifications
- ❌ Server-triggered push notifications are unreliable (missing database trigger)
- ⚠️ **RLS Restriction:** Admins/super_admin can only see their own notifications (not global ops view)
- ⚠️ **Flutter Query Restriction:** All queries filter by `user_id = currentUser.id` (blocks admin global view)

**Key Findings:**
- **Recipient Selection:** ✅ Already global for admins/super_admin (no branch_id filter)
- **In-App Visibility:** ❌ Restricted to own notifications for all roles (including admins)
- **Push Eligibility:** ✅ Works correctly (preferences checked, tokens validated)
- **Preference Model:** ✅ Opt-out model (defaults to enabled) via JSONB field

---

## 1. Role-by-Role Experience Matrix

### 1.1 Driver Role

#### A) Notifications Received

**Push + In-App Notifications:**
- ✅ `job_assignment` - When assigned to a job
- ✅ `job_reassignment` - When job reassigned to them
- ✅ `job_confirmation` - When they confirm a job (self-triggered)
- ✅ `job_start` - When they start a job (self-triggered)
- ✅ `step_completion` - When they complete a step (self-triggered)
- ✅ `job_completion` - When job is completed
- ✅ `job_cancelled` - When their assigned job is cancelled
- ❌ `job_start_deadline_warning_90min` - **NOT RECEIVED** (manager only)
- ❌ `job_start_deadline_warning_60min` - **NOT RECEIVED** (admin/super_admin only)
- ❌ `job_start_deadline_warning_30min` - **NOT RECEIVED** (admin/super_admin only, to be updated to 60min)
- ✅ `payment_reminder` - If applicable
- ✅ `system_alert` - System-wide alerts

**Escalation Notifications:**
- ❌ **Drivers do NOT receive escalation notifications** (90-min or 60-min warnings)

---

#### B) In-App Visibility

**Current Implementation:**
- **Query:** `lib/features/notifications/services/notification_service.dart` (Lines 31-47)
  ```dart
  var query = _supabase
      .from('app_notifications')
      .select()
      .eq('user_id', currentUser.id)  // ← Filters to own notifications
      .eq('is_hidden', false);
  ```

**RLS Policy:**
- `allow_users_view_own` - `user_id = auth.uid()`
- ✅ **Driver can see:** Only notifications where `user_id = driver.id`
- ❌ **Driver cannot see:** Notifications for other users

**Real-time Subscription:**
- **Query:** `lib/features/notifications/services/notification_service.dart` (Lines 652-656)
  ```dart
  final stream = _supabase
      .from('app_notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', currentUser.id)  // ← Filters to own notifications
      .order('created_at', descending: false);
  ```
- ✅ **Real-time updates:** Only for driver's own notifications

**Conclusion:** ✅ **CORRECT** - Drivers see only their own notifications (as intended)

---

#### C) Push Eligibility

**Preference Check:**
- **Location:** `lib/features/notifications/services/notification_service.dart` (Lines 608-638)
- **Logic:** `isPushNotificationEnabled(userId, notificationType)`
  ```dart
  final prefs = profileResponse['notification_prefs'] as Map<String, dynamic>?;
  if (prefs == null || prefs.isEmpty) {
    return true;  // Default: enabled
  }
  final isEnabled = prefs[notificationType] as bool?;
  return isEnabled ?? true;  // Default: enabled if key missing
  ```

**Token Requirements:**
- **Mobile:** `profiles.fcm_token` must be set
- **Web:** `profiles.fcm_token_web` must be set
- **Edge Function:** `supabase/functions/push-notifications/index.ts` (Lines 225-248)
  - Checks for tokens, returns early if none found
  - Sends to all available tokens (mobile + web)

**Default Behavior:**
- ✅ **Opt-out model:** Push enabled by default
- ✅ **Per-type control:** Each notification type can be disabled individually
- ✅ **Fail-open:** If preference check fails, defaults to enabled

**Conclusion:** ✅ **CORRECT** - Push eligibility works as intended

---

### 1.2 Manager Role

#### A) Notifications Received

**Push + In-App Notifications:**
- ✅ `job_assignment` - When jobs are assigned to their drivers
- ✅ `job_reassignment` - When jobs are reassigned
- ✅ `job_confirmation` - When drivers confirm jobs
- ✅ `job_start` - When drivers start jobs
- ✅ `step_completion` - When drivers complete steps
- ✅ `job_completion` - When jobs are completed
- ✅ `job_cancelled` - When jobs are cancelled
- ✅ `job_start_deadline_warning_90min` - **RECEIVED** (for jobs they manage)
- ❌ `job_start_deadline_warning_60min` - **NOT RECEIVED** (admin/super_admin only)
- ❌ `job_start_deadline_warning_30min` - **NOT RECEIVED** (admin/super_admin only)
- ✅ `payment_reminder` - If applicable
- ✅ `system_alert` - System-wide alerts

**Escalation Notifications:**
- ✅ **90-Minute Warning:** Manager receives notification for jobs where `jobs.manager_id = manager.id`
- ⚠️ **Current Bug:** Edge function queries ALL managers globally, not just `jobs.manager_id` (needs fix)

---

#### B) In-App Visibility

**Current Implementation:**
- **Query:** Same as driver - filters by `user_id = currentUser.id`
- **RLS Policy:** `allow_users_view_own` - `user_id = auth.uid()`
- ✅ **Manager can see:** Only notifications where `user_id = manager.id`
- ❌ **Manager cannot see:** Notifications for other users (including their drivers)

**Real-time Subscription:**
- Same as driver - filters by `user_id = currentUser.id`

**Conclusion:** ✅ **CORRECT** - Managers see only their own notifications (as intended)

---

#### C) Push Eligibility

**Preference Check:**
- Same logic as driver - opt-out model, per-type control
- **Default:** Enabled for all notification types

**Token Requirements:**
- Same as driver - requires `fcm_token` (mobile) or `fcm_token_web` (web)

**Conclusion:** ✅ **CORRECT** - Push eligibility works as intended

---

### 1.3 Administrator Role

#### A) Notifications Received

**Push + In-App Notifications:**
- ✅ `job_assignment` - When jobs are assigned (all jobs, not role-specific)
- ✅ `job_reassignment` - When jobs are reassigned
- ✅ `job_confirmation` - When drivers confirm jobs
- ✅ `job_start` - When drivers start jobs
- ✅ `step_completion` - When drivers complete steps
- ✅ `job_completion` - When jobs are completed
- ✅ `job_cancelled` - When jobs are cancelled
- ❌ `job_start_deadline_warning_90min` - **NOT RECEIVED** (manager only)
- ✅ `job_start_deadline_warning_60min` - **RECEIVED** (when updated from 30min)
- ✅ `job_start_deadline_warning_30min` - **RECEIVED** (currently, to be updated to 60min)
- ✅ `payment_reminder` - If applicable
- ✅ `system_alert` - System-wide alerts

**Escalation Notifications:**
- ✅ **60-Minute Escalation:** All active administrators receive notifications globally (no branch restriction)
- ✅ **Recipient Selection:** Edge function queries `role IN ('administrator', 'super_admin')` globally

---

#### B) In-App Visibility

**Current Implementation:**
- **Query:** Same as driver/manager - filters by `user_id = currentUser.id`
- **RLS Policy:** `allow_users_view_own` - `user_id = auth.uid()`
- ❌ **Admin can see:** Only notifications where `user_id = admin.id`
- ❌ **Admin cannot see:** Notifications for other users (BLOCKED by RLS + Flutter query)

**Expected Behavior (Option B - Global Ops View):**
- ✅ **Admin should see:** All notifications (global operations view)
- ✅ **Requires:** RLS policy `allow_admins_view_all_notifications`
- ✅ **Requires:** Flutter query to remove `user_id` filter for admins

**Real-time Subscription:**
- Currently filters by `user_id = currentUser.id`
- **If Option B implemented:** Should subscribe to all notifications (RLS allows)

**Conclusion:** ❌ **BLOCKED** - Admins currently see only their own notifications (needs RLS + Flutter fix)

---

#### C) Push Eligibility

**Preference Check:**
- Same logic as driver/manager - opt-out model, per-type control
- **Default:** Enabled for all notification types
- **Edge Function:** `supabase/functions/check-job-start-deadlines/index.ts` (Lines 143-166)
  ```typescript
  const prefs = recipient.notification_prefs as Record<string, boolean> | null
  const pushEnabled = prefs?.[notification_type] !== false // Default to true
  ```

**Token Requirements:**
- Same as driver/manager - requires `fcm_token` or `fcm_token_web`

**Conclusion:** ✅ **CORRECT** - Push eligibility works as intended

---

### 1.4 Super_Admin Role

#### A) Notifications Received

**Push + In-App Notifications:**
- ✅ Same as Administrator (all notification types)
- ✅ `job_start_deadline_warning_60min` - **RECEIVED** (when updated from 30min)
- ✅ `job_start_deadline_warning_30min` - **RECEIVED** (currently, to be updated to 60min)

**Escalation Notifications:**
- ✅ **60-Minute Escalation:** All active super_admins receive notifications globally (no branch restriction)
- ✅ **Recipient Selection:** Edge function includes `super_admin` in query for `administrator` role

---

#### B) In-App Visibility

**Current Implementation:**
- **Query:** Same as administrator - filters by `user_id = currentUser.id`
- **RLS Policy:** `allow_users_view_own` - `user_id = auth.uid()`
- ❌ **Super_Admin can see:** Only notifications where `user_id = super_admin.id`
- ❌ **Super_Admin cannot see:** Notifications for other users (BLOCKED by RLS + Flutter query)

**Expected Behavior (Option B - Global Ops View):**
- ✅ **Super_Admin should see:** All notifications (global operations view)
- ✅ **Requires:** RLS policy `allow_admins_view_all_notifications` (includes super_admin)
- ✅ **Requires:** Flutter query to remove `user_id` filter for super_admins

**Real-time Subscription:**
- Currently filters by `user_id = currentUser.id`
- **If Option B implemented:** Should subscribe to all notifications (RLS allows)

**Conclusion:** ❌ **BLOCKED** - Super_admins currently see only their own notifications (needs RLS + Flutter fix)

---

#### C) Push Eligibility

**Preference Check:**
- Same logic as administrator - opt-out model, per-type control
- **Default:** Enabled for all notification types

**Token Requirements:**
- Same as administrator - requires `fcm_token` or `fcm_token_web`

**Conclusion:** ✅ **CORRECT** - Push eligibility works as intended

---

## 2. In-App Visibility Rules

### 2.1 Current RLS Policies

**Table:** `public.app_notifications`

**Policies:**
1. `allow_authenticated_insert` - Any authenticated user can INSERT
2. `allow_service_role_all` - Service role has full access
3. `allow_anon_insert` - Anonymous can INSERT (for webhooks)
4. `allow_users_view_own` - Users can SELECT their own (`user_id = auth.uid()`)
5. `allow_users_update_own` - Users can UPDATE their own

**Critical Finding:**
- ❌ **NO policy exists** for admins/super_admin to SELECT all notifications
- ❌ **All roles** (including admins) are restricted to `user_id = auth.uid()`

---

### 2.2 Flutter Query Implementation

**File:** `lib/features/notifications/services/notification_service.dart`

**Method:** `getNotifications()` (Lines 11-66)

**Current Query:**
```dart
var query = _supabase
    .from('app_notifications')
    .select()
    .eq('user_id', currentUser.id)  // ← Always filters by user_id
    .eq('is_hidden', false);
```

**Real-time Subscription:** `getNotificationsStream()` (Lines 641-680)
```dart
final stream = _supabase
    .from('app_notifications')
    .stream(primaryKey: ['id'])
    .eq('user_id', currentUser.id)  // ← Always filters by user_id
    .order('created_at', descending: false);
```

**Analysis:**
- ✅ **Correct for:** Driver, Manager (should see only their own)
- ❌ **Incorrect for:** Administrator, Super_Admin (should see all if Option B implemented)

---

### 2.3 Option A: Own-Only View (Current)

**Behavior:**
- All roles see only their own notifications
- RLS policy: `allow_users_view_own` (current)
- Flutter query: `.eq('user_id', currentUser.id)` (current)

**Pros:**
- ✅ Simple and secure
- ✅ No RLS changes needed
- ✅ No Flutter query changes needed

**Cons:**
- ❌ Admins cannot monitor all notifications (no ops view)
- ❌ Limited visibility for troubleshooting

**Conclusion:** ✅ **CURRENT STATE** - Works but limits admin visibility

---

### 2.4 Option B: Global Ops View for Admins (Recommended)

**Behavior:**
- Driver/Manager: See only their own notifications
- Administrator/Super_Admin: See all notifications (global ops view)

**Required Changes:**
1. **RLS Policy:** Add `allow_admins_view_all_notifications`
   ```sql
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
   ```

2. **Flutter Query:** Remove `user_id` filter for admins
   ```dart
   // Get user role
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
       .eq('is_hidden', false);
   
   // Only filter by user_id if not admin
   if (!isAdmin) {
     query = query.eq('user_id', currentUser.id);
   }
   ```

**Pros:**
- ✅ Admins can monitor all notifications (ops view)
- ✅ Better troubleshooting and oversight
- ✅ Aligns with "national/global" admin role

**Cons:**
- ⚠️ Requires RLS policy change
- ⚠️ Requires Flutter query change
- ⚠️ Needs testing to ensure security

**Conclusion:** ✅ **RECOMMENDED** - Enables global ops view for admins

---

## 3. Push Eligibility Rules

### 3.1 Preference Model

**Storage:** `profiles.notification_prefs` (JSONB column)

**Structure:**
```json
{
  "job_assignment": true,
  "job_reassignment": true,
  "job_confirmation": true,
  "job_start": true,
  "step_completion": true,
  "job_completion": true,
  "job_cancelled": true,
  "job_start_deadline_warning_90min": true,
  "job_start_deadline_warning_30min": true,  // To be updated to 60min
  "payment_reminder": true,
  "system_alert": true
}
```

**Default Behavior:**
- ✅ **Opt-out model:** All notification types enabled by default
- ✅ **Per-type control:** Each type can be disabled individually
- ✅ **Fail-open:** If preference missing or check fails, defaults to enabled

**Evidence:**
- `lib/features/notifications/services/notification_preferences_service.dart` (Lines 187-195)
  ```dart
  Map<String, bool> _getDefaultPreferences() {
    final defaults = <String, bool>{};
    for (final type in NotificationConstants.allNotificationTypes) {
      defaults[type] = true;  // All enabled by default
    }
    return defaults;
  }
  ```

---

### 3.2 Preference Check Logic

#### A) Flutter Client (Client-Initiated Notifications)

**Location:** `lib/features/notifications/services/notification_service.dart`

**Method:** `isPushNotificationEnabled()` (Lines 608-638)

**Logic:**
```dart
final prefs = profileResponse['notification_prefs'] as Map<String, dynamic>?;

if (prefs == null || prefs.isEmpty) {
  return true;  // Default: enabled
}

final isEnabled = prefs[notificationType] as bool?;
return isEnabled ?? true;  // Default: enabled if key missing
```

**Usage:**
- Called before invoking `push-notifications` edge function
- If disabled, notification is created but push is skipped

---

#### B) Edge Function (Server-Initiated Notifications)

**Location:** `supabase/functions/check-job-start-deadlines/index.ts`

**Logic (Lines 143-166):**
```typescript
const prefs = recipient.notification_prefs as Record<string, boolean> | null
const pushEnabled = prefs?.[notification_type] !== false // Default to true if not set

if (pushEnabled) {
  // Trigger push notification via webhook
  await supabase.functions.invoke('push-notifications', {...})
} else {
  console.log(`Push notification skipped for user ${recipient.id} - ${notification_type} disabled`)
}
```

**Analysis:**
- ✅ **Opt-out model:** `!== false` means enabled by default
- ✅ **Per-type control:** Checks specific `notification_type` key
- ✅ **Consistent with Flutter:** Same logic (opt-out, per-type)

---

#### C) Push-Notifications Edge Function

**Location:** `supabase/functions/push-notifications/index.ts`

**Note:** This function does NOT check preferences (already checked by caller)

**Logic:**
- Receives notification record
- Fetches FCM tokens from `profiles` table
- Sends to FCM API
- Logs delivery attempt to `notification_delivery_log`

**Conclusion:** ✅ **CORRECT** - Preferences checked before invocation

---

### 3.3 Token Requirements

**Mobile Tokens:**
- **Column:** `profiles.fcm_token` (text, nullable)
- **Required for:** Mobile/Android push notifications
- **Edge Function Check:** `supabase/functions/push-notifications/index.ts` (Lines 226-234)
  ```typescript
  if (profile?.fcm_token) {
    tokens.push(profile.fcm_token)
  }
  ```

**Web Tokens:**
- **Column:** `profiles.fcm_token_web` (text, nullable)
- **Required for:** Web platform push notifications
- **Edge Function Check:** `supabase/functions/push-notifications/index.ts` (Lines 231-234)
  ```typescript
  if (profile?.fcm_token_web) {
    tokens.push(profile.fcm_token_web)
  }
  ```

**Token Statistics:**
- Total active profiles: 24
- Profiles with mobile token: 19 (79%)
- Profiles with web token: 7 (29%)
- Profiles with preferences: 24 (100%)

**Conclusion:** ✅ **CORRECT** - Token validation works as intended

---

### 3.4 Push Eligibility Summary

**For All Roles:**
1. ✅ **Preference Check:** Notification type must not be disabled (`prefs[type] !== false`)
2. ✅ **Token Check:** At least one FCM token must exist (`fcm_token` or `fcm_token_web`)
3. ✅ **Default Behavior:** Enabled by default (opt-out model)
4. ✅ **Fail-Open:** If check fails, defaults to enabled

**Edge Cases:**
- **No preferences:** Push enabled (default)
- **Missing preference key:** Push enabled (default)
- **No tokens:** Push skipped (no delivery attempt)
- **Preference disabled:** Push skipped (notification still created in-app)

---

## 4. Notification Type Inventory

### 4.1 All Notification Types

**Source:** `lib/core/constants/notification_constants.dart`

**Types:**
1. `job_assignment` - Job assigned to driver
2. `job_reassignment` - Job reassigned to different driver
3. `job_confirmation` - Driver confirmed job assignment
4. `job_start` - Driver started job
5. `step_completion` - Driver completed a step
6. `job_completion` - Job completed
7. `job_cancelled` - Job cancelled
8. `job_start_deadline_warning_90min` - 90 minutes before pickup, job not started (manager)
9. `job_start_deadline_warning_30min` - 30 minutes before pickup, job not started (admin) - **TO BE UPDATED TO 60min**
10. `payment_reminder` - Payment reminder
11. `system_alert` - System-wide alert

**Database Statistics:**
- Total notifications: 37,587
- Unique notification types: 10
- Most common: `step_completion` (27,956), `job_start` (4,950), `job_confirmation` (3,052)
- Escalation types: `job_start_deadline_warning_90min` (214), `job_start_deadline_warning_30min` (648)

---

### 4.2 Role-Specific Notification Types

**Driver:**
- `job_assignment`, `job_reassignment`, `job_confirmation`, `job_start`, `step_completion`, `job_completion`, `job_cancelled`, `payment_reminder`, `system_alert`
- ❌ **NOT:** `job_start_deadline_warning_90min`, `job_start_deadline_warning_60min`, `job_start_deadline_warning_30min`

**Manager:**
- All driver types PLUS: `job_start_deadline_warning_90min`
- ❌ **NOT:** `job_start_deadline_warning_60min`, `job_start_deadline_warning_30min`

**Administrator/Super_Admin:**
- All types PLUS: `job_start_deadline_warning_60min` (when updated from 30min)
- ❌ **NOT:** `job_start_deadline_warning_90min` (manager only)

---

## 5. Preference Enforcement Summary

### 5.1 Current Implementation

**Storage:**
- `profiles.notification_prefs` (JSONB column)
- All 24 active profiles have preferences set

**Model:**
- **Opt-out:** Defaults to enabled
- **Per-type:** Each notification type can be disabled individually
- **Fail-open:** If check fails, defaults to enabled

**Enforcement Points:**
1. ✅ **Flutter Client:** `isPushNotificationEnabled()` checks before invoking edge function
2. ✅ **Edge Function:** `check-job-start-deadlines` checks before invoking push function
3. ✅ **Push Function:** Does not check (already checked by caller)

---

### 5.2 Preference UI

**Location:** `lib/features/notifications/screens/notification_preferences_screen.dart`

**Features:**
- Toggle switches for each notification type
- Display names and descriptions from `NotificationConstants`
- Saves to `profiles.notification_prefs` JSONB column
- Real-time updates via `NotificationPreferencesService`

**Available Types:**
- All types from `NotificationConstants.allNotificationTypes`
- Includes: `job_start_deadline_warning_90min`, `job_start_deadline_warning_30min`

**Note:** When 30min is updated to 60min, UI should be updated to show `job_start_deadline_warning_60min`

---

## 6. Admin/Super_Admin Global Scope Validation

### 6.1 Recipient Selection (Edge Function)

**File:** `supabase/functions/check-job-start-deadlines/index.ts`

**Code (Lines 89-99):**
```typescript
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
- ✅ **NO branch_id filter** - Queries all active admins/super_admins globally
- ✅ **Correct role handling** - Includes both 'administrator' and 'super_admin'
- ✅ **Global scope confirmed** - No geographic restrictions

**Conclusion:** ✅ **ALREADY GLOBAL** - No changes needed

---

### 6.2 RLS Visibility (Database)

**Current State:**
- ❌ **Only `allow_users_view_own` policy exists**
- ❌ **Admins can only see:** Notifications where `user_id = auth.uid()`
- ❌ **Admins cannot see:** Notifications for other users

**Required for Option B (Global Ops View):**
- ✅ **Add policy:** `allow_admins_view_all_notifications`
- ✅ **Policy should:** Allow `role IN ('administrator', 'super_admin')` to SELECT all rows

**Conclusion:** ❌ **BLOCKED** - RLS prevents global admin visibility

---

### 6.3 Flutter Query Visibility

**Current State:**
- ❌ **All queries filter by:** `.eq('user_id', currentUser.id)`
- ❌ **Admins see only:** Their own notifications
- ❌ **Admins cannot see:** Notifications for other users

**Required for Option B (Global Ops View):**
- ✅ **Remove filter for admins:** Check role, skip `user_id` filter if admin/super_admin
- ✅ **Rely on RLS:** Let RLS policy enforce security

**Conclusion:** ❌ **BLOCKED** - Flutter query prevents global admin visibility

---

## 7. Summary Table

| Role | Push Eligible | In-App Visibility | Escalation Notifications | Global Scope |
|------|---------------|-------------------|-------------------------|---------------|
| **Driver** | ✅ Yes (if prefs enabled + token exists) | Own only | ❌ No | N/A |
| **Manager** | ✅ Yes (if prefs enabled + token exists) | Own only | ✅ 90-min warning (job-scoped) | N/A |
| **Administrator** | ✅ Yes (if prefs enabled + token exists) | Own only (❌ should be global) | ✅ 60-min escalation (global) | ✅ Recipient selection global, ❌ Visibility blocked |
| **Super_Admin** | ✅ Yes (if prefs enabled + token exists) | Own only (❌ should be global) | ✅ 60-min escalation (global) | ✅ Recipient selection global, ❌ Visibility blocked |

---

## 8. Recommendations

### 8.1 Immediate Actions

1. **Implement Option B (Global Ops View):**
   - Add RLS policy `allow_admins_view_all_notifications`
   - Update Flutter queries to remove `user_id` filter for admins/super_admins
   - Test security and performance

2. **Fix Manager Scoping:**
   - Update edge function to filter by `jobs.manager_id` for 90-min warnings
   - Update RPC function to return `manager_id` in result set

3. **Update 30min → 60min:**
   - Update RPC function threshold
   - Update notification type constant
   - Update UI preferences screen

---

### 8.2 Future Enhancements

1. **Preference Categories:**
   - Group notification types into categories (e.g., "Escalations", "Job Updates")
   - Allow category-level preferences (e.g., disable all escalations)

2. **Admin Notification Dashboard:**
   - Dedicated view for admins to see all notifications
   - Filtering by type, user, job, date range
   - Bulk actions (mark all read, dismiss)

3. **Notification Analytics:**
   - Track delivery rates per role
   - Monitor escalation notification effectiveness
   - Alert on high failure rates

---

**End of Role Experience Specification**

