# Notification System - Role Summary

**Date:** 2026-01-04  
**Purpose:** Complete summary of which roles receive which notifications and who can set preferences

---

## Executive Summary

**Who Can Set Preferences:** ✅ **SUPER ADMIN ONLY** (all other roles cannot configure notification settings)  
**Who Receives Notifications:** Role-specific (see details below)

---

## 1. Notification Preferences Access

### ✅ Super Admin Only

**Access:** **RESTRICTED** - Only `super_admin` role can access notification preferences

**Location:**
- Drawer Menu → Settings → Notification Settings (super_admin only)
- Notification Bell → Notification Settings (super_admin only)
- Direct route `/settings` (protected by route guard)

**What Super Admin Can Control:**
- Enable/disable each notification type for all users
- Test notifications
- Clear all notifications
- Reset to defaults

**Access Control:**
- **Super Admin:** ✅ Full access to notification preferences screen
- **Administrator:** ❌ Access denied (redirected to dashboard)
- **Manager:** ❌ Access denied (redirected to dashboard)
- **Driver:** ❌ Access denied (redirected to dashboard)
- **Other Roles:** ❌ Access denied (redirected to dashboard)

**Security Layers:**
1. **UI Layer:** Settings menu items hidden for non-super-admin users
2. **Screen Layer:** Screen shows "Access Restricted" message for non-super-admin
3. **Route Layer:** Route guard redirects non-super-admin to dashboard

**Note:** Super admin configures notification preferences globally for all users. Individual users cannot modify their own notification settings.

---

## 2. Notifications Received by Role

### 2.1 Driver Role

**Receives (9 notification types):**

1. ✅ **`job_assignment`** - When a job is assigned to them
2. ✅ **`job_reassignment`** - When a job is reassigned to them
3. ✅ **`job_confirmation`** - When they confirm a job assignment (self-triggered)
4. ✅ **`job_status_change`** - When job status is updated
5. ✅ **`job_cancelled`** - When their assigned job is cancelled
6. ✅ **`job_start`** - When they start a job (self-triggered)
7. ✅ **`job_completion`** - When job is completed
8. ✅ **`step_completion`** - When they complete a job step (self-triggered)
9. ✅ **`system_alert`** - System-wide alerts

**Does NOT Receive:**
- ❌ `job_start_deadline_warning_90min` (manager only)
- ❌ `job_start_deadline_warning_60min` (admin/super_admin only)

**UI Visibility:**
- ❌ Cannot access notification preferences screen (super_admin only)
- Receives notifications based on super_admin configuration

---

### 2.2 Manager Role

**Receives (10 notification types):**

**All Driver Types (8):**
1. ✅ `job_assignment`
2. ✅ `job_reassignment`
3. ✅ `job_confirmation`
4. ✅ `job_status_change`
5. ✅ `job_cancelled`
6. ✅ `job_start`
7. ✅ `job_completion`
8. ✅ `step_completion`
9. ✅ `system_alert`

**PLUS Manager-Specific (1):**
10. ✅ **`job_start_deadline_warning_90min`** - When jobs are not started 90 minutes before pickup

**Does NOT Receive:**
- ❌ `job_start_deadline_warning_60min` (admin/super_admin only)

**UI Visibility:**
- ❌ Cannot access notification preferences screen (super_admin only)
- Receives notifications based on super_admin configuration

**Notification Scope:**
- Receives deadline warnings for jobs they manage (scoped by `manager_id`)
- Receives job-related notifications for jobs in their scope

---

### 2.3 Administrator Role

**Receives (10 notification types):**

**All Driver Types (8):**
1. ✅ `job_assignment`
2. ✅ `job_reassignment`
3. ✅ `job_confirmation`
4. ✅ `job_status_change`
5. ✅ `job_cancelled`
6. ✅ `job_start`
7. ✅ `job_completion`
8. ✅ `step_completion`
9. ✅ `system_alert`

**PLUS Admin-Specific (1):**
10. ✅ **`job_start_deadline_warning_60min`** - When jobs are not started 60 minutes before pickup (GLOBAL - all jobs)

**Does NOT Receive:**
- ❌ `job_start_deadline_warning_90min` (manager only)

**UI Visibility:**
- ❌ Cannot access notification preferences screen (super_admin only)
- Receives notifications based on super_admin configuration

**Notification Scope:**
- Receives deadline warnings for ALL jobs globally (no branch restriction)
- Receives job-related notifications for all jobs (global visibility)

---

### 2.4 Super Admin Role

**Receives (10 notification types):**

**Same as Administrator:**
1. ✅ `job_assignment`
2. ✅ `job_reassignment`
3. ✅ `job_confirmation`
4. ✅ `job_status_change`
5. ✅ `job_cancelled`
6. ✅ `job_start`
7. ✅ `job_completion`
8. ✅ `step_completion`
9. ✅ `system_alert`
10. ✅ **`job_start_deadline_warning_60min`** - When jobs are not started 60 minutes before pickup (GLOBAL - all jobs)

**Does NOT Receive:**
- ❌ `job_start_deadline_warning_90min` (manager only)

**UI Visibility:**
- ✅ Can access notification preferences screen (super_admin only)
- Can configure all 11 notification types globally
- Sees 60min deadline warning toggle

**Notification Scope:**
- Receives deadline warnings for ALL jobs globally (no branch restriction)
- Receives job-related notifications for all jobs (global visibility)
- Same scope as Administrator

**Special Privilege:**
- Only role that can configure notification preferences
- Settings apply globally to all users

---

## 3. Notification Type Breakdown

### 3.1 Job Lifecycle Notifications

| Notification Type | Driver | Manager | Admin | Super Admin |
|------------------|--------|---------|-------|-------------|
| `job_assignment` | ✅ | ✅ | ✅ | ✅ |
| `job_reassignment` | ✅ | ✅ | ✅ | ✅ |
| `job_confirmation` | ✅ | ✅ | ✅ | ✅ |
| `job_start` | ✅ | ✅ | ✅ | ✅ |
| `job_status_change` | ✅ | ✅ | ✅ | ✅ |
| `job_completion` | ✅ | ✅ | ✅ | ✅ |
| `job_cancelled` | ✅ | ✅ | ✅ | ✅ |
| `step_completion` | ✅ | ✅ | ✅ | ✅ |

**Total:** 8 types - All roles receive these

---

### 3.2 Escalation Notifications

| Notification Type | Driver | Manager | Admin | Super Admin |
|------------------|--------|---------|-------|-------------|
| `job_start_deadline_warning_90min` | ❌ | ✅ | ❌ | ❌ |
| `job_start_deadline_warning_60min` | ❌ | ❌ | ✅ | ✅ |

**Total:** 2 types - Role-specific

**Rules:**
- **90min warning:** Only managers receive (scoped to jobs they manage)
- **60min warning:** Only administrators and super_admins receive (GLOBAL - all jobs)

---

### 3.3 System Notifications

| Notification Type | Driver | Manager | Admin | Super Admin |
|------------------|--------|---------|-------|-------------|
| `system_alert` | ✅ | ✅ | ✅ | ✅ |

**Total:** 1 type - All roles receive this

---

## 4. Notification Scoping

### 4.1 Job-Related Notifications

**Driver:**
- Receives notifications for jobs assigned to them (`driver_id = user.id`)

**Manager:**
- Receives notifications for jobs they manage (`manager_id = user.id`)
- Receives deadline warnings for their managed jobs only

**Administrator/Super_Admin:**
- Receives notifications for ALL jobs (GLOBAL - no branch restriction)
- Receives deadline warnings for ALL jobs globally

---

### 4.2 Deadline Warning Escalation

**T-90 Minutes (Manager Only):**
- **Trigger:** Job not started 85-90 minutes before pickup
- **Recipients:** Assigned manager only (`manager_id`)
- **Scope:** Job-specific (only the manager for that job)

**T-60 Minutes (Admin/Super_Admin Only):**
- **Trigger:** Job not started 55-60 minutes before pickup
- **Recipients:** ALL active administrators AND super_admins globally
- **Scope:** GLOBAL (no branch restriction, all jobs)

**Prevention:**
- If job starts before T-60, no 60min warning is sent
- If job starts before T-90, no 90min warning is sent
- RPC function filters by `driver_flow.job_started_at IS NULL`

---

## 5. Preference Settings Summary

### 5.1 Who Can Set Preferences

✅ **SUPER ADMIN ONLY** can set notification preferences:
- **Super Admin:** ✅ Full access
- **Administrator:** ❌ Access denied
- **Manager:** ❌ Access denied
- **Driver:** ❌ Access denied

**Restrictions:** Only `super_admin` role can access and modify notification preferences. All other roles are blocked at the UI, screen, and route guard levels.

---

### 5.2 What Super Admin Can Set

**Notification Types:**
- Enable/disable each notification type globally
- Configure all 11 notification types:
  - `job_assignment`, `job_reassignment`, `job_confirmation`
  - `job_start`, `job_completion`, `job_status_change`
  - `job_cancelled`, `step_completion`
  - `job_start_deadline_warning_90min` (manager-specific)
  - `job_start_deadline_warning_60min` (admin/super_admin-specific)
  - `system_alert`

**Actions:**
- Send test notification
- Clear all notifications
- Reset to defaults

**Note:** Delivery methods, sound, vibration, priority settings, and quiet hours have been removed from the UI as they were not enforced by the notification system.

---

### 5.3 Preference Storage

**Location:** `profiles.notification_prefs` (JSONB column)

**Format:**
```json
{
  "job_assignment": true,
  "job_reassignment": true,
  "job_confirmation": true,
  "job_status_change": true,
  "job_cancelled": true,
  "job_start": true,
  "job_completion": true,
  "step_completion": true,
  "job_start_deadline_warning_90min": true,  // Manager only
  "job_start_deadline_warning_60min": true,  // Admin/Super_Admin only
  "system_alert": true
}
```

**Note:** 
- Delivery methods, sound, vibration, priority, and quiet hours preferences have been removed as they were not enforced by the notification system.
- Payment reminders have been removed as they are not needed.

**Default:** All notification types enabled (`true`)

---

## 6. Quick Reference Table

### Notification Types by Role

| Notification Type | Driver | Manager | Admin | Super Admin | UI Toggle Visible |
|------------------|--------|---------|-------|-------------|-------------------|
| Job Assignment | ✅ | ✅ | ✅ | ✅ | ✅ Super Admin only |
| Job Reassignment | ✅ | ✅ | ✅ | ✅ | ✅ Super Admin only |
| Job Confirmation | ✅ | ✅ | ✅ | ✅ | ✅ Super Admin only |
| Job Status Change | ✅ | ✅ | ✅ | ✅ | ✅ Super Admin only |
| Job Cancelled | ✅ | ✅ | ✅ | ✅ | ✅ Super Admin only |
| Job Start | ✅ | ✅ | ✅ | ✅ | ✅ Super Admin only |
| Job Completion | ✅ | ✅ | ✅ | ✅ | ✅ Super Admin only |
| Step Completion | ✅ | ✅ | ✅ | ✅ | ✅ Super Admin only |
| System Alert | ✅ | ✅ | ✅ | ✅ | ✅ Super Admin only |
| Deadline Warning (90min) | ❌ | ✅ | ❌ | ❌ | ✅ Super Admin only |
| Deadline Warning (60min) | ❌ | ❌ | ✅ | ✅ | ✅ Super Admin only |
| **Total Types** | **9** | **10** | **10** | **10** | **Super Admin only** |

---

### Preference Access by Role

| Feature | Driver | Manager | Admin | Super Admin |
|---------|--------|---------|-------|-------------|
| Access Preferences Screen | ❌ | ❌ | ❌ | ✅ |
| Set Notification Types | ❌ | ❌ | ❌ | ✅ |
| Test Notifications | ❌ | ❌ | ❌ | ✅ |
| Clear Notifications | ❌ | ❌ | ❌ | ✅ |
| Reset to Defaults | ❌ | ❌ | ❌ | ✅ |

**Result:** ✅ **SUPER ADMIN ONLY** has access to preference settings. All other roles are blocked.

---

## 7. Notification Flow Examples

### Example 1: Driver Receives Job Assignment

**Flow:**
1. Manager assigns job to driver
2. System creates `job_assignment` notification
3. **Preference Check:** Edge Function checks `prefs['job_assignment']`
4. **If Enabled:** Push notification sent + in-app notification appears
5. **If Disabled:** In-app notification may appear, but push is blocked

**Recipients:**
- ✅ Driver (assigned user)
- ✅ Manager (job manager)
- ✅ Administrators/Super_Admins (global visibility)

---

### Example 2: Manager Receives 90min Deadline Warning

**Flow:**
1. Job not started 85-90 minutes before pickup
2. Scheduled Edge Function `check-job-start-deadlines` runs
3. RPC identifies job needing 90min warning
4. System creates `job_start_deadline_warning_90min` notification
5. **Preference Check:** Poller checks `prefs['job_start_deadline_warning_90min']`
6. **If Enabled:** Push notification sent
7. **If Disabled:** Push blocked, in-app may appear

**Recipients:**
- ✅ Manager (assigned manager only)
- ❌ Driver (does not receive)
- ❌ Administrators (do not receive 90min warnings)

---

### Example 3: Admin Receives 60min Deadline Warning

**Flow:**
1. Job not started 55-60 minutes before pickup
2. Scheduled Edge Function `check-job-start-deadlines` runs
3. RPC identifies job needing 60min warning
4. System creates `job_start_deadline_warning_60min` notification
5. **Preference Check:** Poller checks `prefs['job_start_deadline_warning_60min']`
6. **If Enabled:** Push notification sent to ALL admins/super_admins
7. **If Disabled:** Push blocked for that admin

**Recipients:**
- ✅ ALL Administrators (globally)
- ✅ ALL Super_Admins (globally)
- ❌ Manager (does not receive 60min warnings)
- ❌ Driver (does not receive)

---

## 8. Preference Enforcement

### 8.1 Where Preferences Are Checked

**1. Push Notifications Poller:**
- File: `supabase/functions/push-notifications-poller/index.ts`
- Checks: `prefs[notificationType] === false`
- Action: Skips push notification if disabled
- Logs: `skipped_preferences` in delivery log

**2. Client-Side (Flutter):**
- File: `lib/features/notifications/services/notification_service.dart`
- Checks: `isPushNotificationEnabled()` before invoking edge function
- Action: Blocks client-initiated push if disabled

**3. Edge Function (Deadline Checker):**
- File: `supabase/functions/check-job-start-deadlines/index.ts`
- Note: Does NOT check preferences (creates notifications, preference check happens in poller)

---

### 8.2 Preference Model

**Type:** Opt-out (defaults to enabled)

**Logic:**
```typescript
const prefs = profile.notification_prefs as Record<string, boolean> | null
const pushEnabled = prefs?.[notificationType] !== false // Default to true
```

**Meaning:**
- If preference is `undefined` or `null` → **Enabled** (default)
- If preference is `true` → **Enabled**
- If preference is `false` → **Disabled**

---

## 9. Summary Tables

### Notification Count by Role

| Role | Notification Types Received | Deadline Warnings | Total |
|------|----------------------------|-------------------|-------|
| Driver | 9 | 0 | **9** |
| Manager | 9 | 1 (90min) | **10** |
| Administrator | 9 | 1 (60min) | **10** |
| Super Admin | 9 | 1 (60min) | **10** |

---

### Preference Access Summary

| Feature | Access Level |
|---------|--------------|
| View Preferences | ✅ Super Admin only |
| Modify Preferences | ✅ Super Admin only |
| Test Notifications | ✅ Super Admin only |
| Clear Notifications | ✅ Super Admin only |
| Reset Defaults | ✅ Super Admin only |

**Result:** ✅ **Super Admin only** - all other roles are blocked from accessing preferences

---

## 10. Key Takeaways

1. **✅ Super Admin Only Can Set Preferences:** Only `super_admin` role can access/modify notification preferences. All other roles are blocked at UI, screen, and route guard levels.

2. **📊 Role-Specific Notifications:**
   - Drivers: 9 types (no deadline warnings)
   - Managers: 10 types (includes 90min warning)
   - Admins/Super_Admins: 10 types (includes 60min warning)

3. **🎯 Deadline Warning Rules:**
   - 90min: Manager only, scoped to their jobs
   - 60min: Admin/Super_Admin only, GLOBAL scope

4. **⚙️ Preference Enforcement:**
   - Opt-out model (defaults to enabled)
   - Checked in push-notifications-poller
   - Checked in client-side code
   - Disabled types block push but may still show in-app

5. **🔒 Scope Rules:**
   - Drivers: Own jobs only
   - Managers: Managed jobs only
   - Admins/Super_Admins: ALL jobs globally

---

## 11. Quick Reference

### Who Gets What?

**Driver:**
- Gets: 9 notification types
- Can set: ❌ Cannot access preferences (super_admin only)
- Scope: Own jobs only

**Manager:**
- Gets: 10 notification types (9 + 90min warning)
- Can set: ❌ Cannot access preferences (super_admin only)
- Scope: Managed jobs + deadline warnings for their jobs

**Administrator:**
- Gets: 10 notification types (9 + 60min warning)
- Can set: ❌ Cannot access preferences (super_admin only)
- Scope: ALL jobs globally

**Super Admin:**
- Gets: 10 notification types (9 + 60min warning)
- Can set: ✅ Can configure all 11 notification types globally
- Scope: ALL jobs globally (same as admin)
- Special: Only role with access to notification preferences screen

---

### Who Can Set Preferences?

✅ **SUPER ADMIN ONLY** - Only super administrators can:
- Access notification preferences screen
- Enable/disable notification types globally
- Test notifications
- Clear notifications
- Reset to defaults

**All other roles are blocked** from accessing notification preferences at the UI, screen, and route guard levels.

---

**End of Role Summary**

