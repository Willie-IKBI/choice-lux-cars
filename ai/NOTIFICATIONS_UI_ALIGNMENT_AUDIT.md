# Notification System UI Alignment Audit

**Date:** 2026-01-04  
**Status:** Audit Complete - Implementation Plan Ready  
**Issue:** Notification preferences UI shows notification types that don't align with actual implementation, missing types, and naming inconsistencies.

---

## Executive Summary

The notification preferences screen (`notification_preferences_screen.dart`) displays **6 notification types** in the UI, but the codebase actually uses **12+ notification types**. Additionally, there are naming inconsistencies between UI labels, constants, and actual database values.

**Key Findings:**
1. ❌ **UI Missing 6+ Notification Types:** `job_confirmation`, `job_start`, `job_completion`, `step_completion`, `job_start_deadline_warning_90min`, `job_start_deadline_warning_60min`
2. ❌ **Naming Inconsistencies:** UI uses plural forms (`job_assignments`) but constants/database use singular (`job_assignment`)
3. ❌ **Type Mismatch:** UI shows `job_cancellations` but code uses `job_cancelled` (not `job_cancellation`)
4. ❌ **Preferences Storage Mismatch:** UI references `user_notification_preferences` table but actual storage is `profiles.notification_prefs` (JSONB)
5. ❌ **No Backend Integration:** UI preferences are not saved/loaded from database

---

## 1. Notification Type Inventory

### 1.1 Notification Types in UI (Current)

**File:** `lib/features/notifications/screens/notification_preferences_screen.dart`

**UI Shows (6 types):**
1. `job_assignments` → Maps to `job_assignment`
2. `job_reassignments` → Maps to `job_reassignment`
3. `job_status_changes` → Maps to `job_status_change`
4. `job_cancellations` → **MISMATCH:** Should map to `job_cancelled` (not `job_cancellation`)
5. `payment_reminders` → Maps to `payment_reminder`
6. `system_alerts` → Maps to `system_alert`

**Missing from UI (6+ types):**
- `job_confirmation` - Driver confirms job assignment
- `job_start` - Driver starts a job
- `job_completion` - Job is completed
- `step_completion` - Driver completes a step
- `job_start_deadline_warning_90min` - 90-min deadline warning (manager)
- `job_start_deadline_warning_60min` - 60-min deadline warning (admin/super_admin)

---

### 1.2 Notification Types in Constants

**File:** `lib/core/constants/notification_constants.dart`

**Defined Constants (9 types):**
```dart
static const String jobAssignment = 'job_assignment';
static const String jobReassignment = 'job_reassignment';
static const String jobStatusChange = 'job_status_change';
static const String jobCancellation = 'job_cancellation';  // ⚠️ MISMATCH: Code uses 'job_cancelled'
static const String jobConfirmation = 'job_confirmation';
static const String jobStartDeadlineWarning90min = 'job_start_deadline_warning_90min';
static const String jobStartDeadlineWarning60min = 'job_start_deadline_warning_60min';
static const String paymentReminder = 'payment_reminder';
static const String systemAlert = 'system_alert';
```

**Missing from Constants (3 types):**
- `job_start` - Used in `notification_service.dart` line 752
- `job_completion` - Used in `notification_service.dart` line 882
- `step_completion` - Used in `notification_service.dart` line 816

---

### 1.3 Notification Types Actually Used in Code

**File:** `lib/features/notifications/services/notification_service.dart`

**Actually Created (12 types):**
1. `job_assignment` - Line 341-342
2. `job_reassignment` - Line 341-342
3. `job_cancelled` - Line 391 ⚠️ **NOT** `job_cancellation`
4. `job_status_change` - Line 455
5. `payment_reminder` - Line 507
6. `system_alert` - Line 568
7. `job_start` - Line 752 ⚠️ **NOT in constants**
8. `step_completion` - Line 816 ⚠️ **NOT in constants**
9. `job_completion` - Line 882 ⚠️ **NOT in constants**
10. `job_confirmation` - Line 967
11. `job_start_deadline_warning_90min` - Created by Edge Function
12. `job_start_deadline_warning_60min` - Created by Edge Function

---

### 1.4 Notification Types in Edge Functions

**File:** `supabase/functions/check-job-start-deadlines/index.ts`

**Created by Server:**
- `job_start_deadline_warning_90min` - Line 176
- `job_start_deadline_warning_60min` - Line 176

**File:** `supabase/functions/push-notifications/index.ts`

**Handled Types:**
- All types from constants
- `job_start_deadline_warning_60min` - Line 459

---

## 2. Naming Inconsistencies

### 2.1 UI vs Constants vs Database

| UI Label | UI Variable | Constant Name | Database Value | Status |
|----------|-------------|---------------|----------------|--------|
| Job Assignments | `_jobAssignments` | `jobAssignment` | `job_assignment` | ✅ Match |
| Job Reassignments | `_jobReassignments` | `jobReassignment` | `job_reassignment` | ✅ Match |
| Job Status Changes | `_jobStatusChanges` | `jobStatusChange` | `job_status_change` | ✅ Match |
| Job Cancellations | `_jobCancellations` | `jobCancellation` | `job_cancelled` | ❌ **MISMATCH** |
| Payment Reminders | `_paymentReminders` | `paymentReminder` | `payment_reminder` | ✅ Match |
| System Alerts | `_systemAlerts` | `systemAlert` | `system_alert` | ✅ Match |

**Issue:** `job_cancellation` constant exists but code uses `job_cancelled`.

---

## 3. Preferences Storage Analysis

### 3.1 Current Implementation

**File:** `lib/features/notifications/services/notification_preferences_service.dart`

**Storage Location:**
- **Referenced:** `user_notification_preferences` table (Line 17, 37)
- **Actual:** `profiles.notification_prefs` (JSONB column) - Used by Edge Functions

**Evidence:**
- Edge Function `check-job-start-deadlines/index.ts` reads from `profiles.notification_prefs` (Line 88, 111)
- Edge Function `push-notifications-poller/index.ts` reads from `profiles.notification_prefs` (Line 448, 534)
- No `user_notification_preferences` table found in migrations

**Status:** ❌ **BROKEN** - Service references non-existent table

---

### 3.2 Preference Model

**Current Model (from `_getDefaultPreferences()`):**
```dart
{
  'job_assignments': true,        // Plural
  'job_reassignments': true,      // Plural
  'job_status_changes': true,     // Plural
  'job_cancellations': true,      // Plural
  'payment_reminders': true,      // Plural
  'system_alerts': true,          // Plural
  'push_notifications': true,
  'in_app_notifications': true,
  'email_notifications': false,
  'sound_enabled': true,
  'vibration_enabled': true,
  'high_priority_only': false,
  'quiet_hours_enabled': false,
  'quiet_hours_start': '22:00',
  'quiet_hours_end': '07:00',
}
```

**Expected Model (from Edge Functions):**
```typescript
{
  'job_assignment': boolean,                    // Singular
  'job_reassignment': boolean,                  // Singular
  'job_status_change': boolean,                 // Singular
  'job_cancelled': boolean,                     // Singular, different name
  'job_confirmation': boolean,                  // Missing from UI
  'job_start': boolean,                         // Missing from UI
  'job_completion': boolean,                    // Missing from UI
  'step_completion': boolean,                   // Missing from UI
  'job_start_deadline_warning_90min': boolean, // Missing from UI
  'job_start_deadline_warning_60min': boolean, // Missing from UI
  'payment_reminder': boolean,                  // Singular
  'system_alert': boolean,                      // Singular
}
```

**Status:** ❌ **MISMATCH** - Plural vs singular, missing types, wrong cancellation name

---

## 4. UI Implementation Issues

### 4.1 Missing Backend Integration

**File:** `lib/features/notifications/screens/notification_preferences_screen.dart`

**Issues:**
1. **No Load:** Preferences are not loaded from database on screen init
2. **No Save:** `_savePreferences()` method is empty (Line 355-360) - TODO comment
3. **Hardcoded Defaults:** All preferences default to `true` in state variables
4. **No Provider Integration:** Does not use `NotificationPreferencesService` or any provider

**Status:** ❌ **NON-FUNCTIONAL** - UI is display-only, changes are not persisted

---

### 4.2 Missing Notification Types

**UI Missing:**
- Job Confirmation toggle
- Job Start toggle
- Job Completion toggle
- Step Completion toggle
- Job Start Deadline Warning (90 min) toggle
- Job Start Deadline Warning (60 min) toggle

**Impact:**
- Users cannot disable these notification types
- Edge Functions check preferences but UI doesn't allow configuration
- Default behavior (enabled) applies to all missing types

---

## 5. Role-Based Notification Types

### 5.1 Per-Role Notification Types

**From:** `ai/NOTIFICATIONS_ROLE_EXPERIENCE_SPEC.md`

**Driver:**
- `job_assignment`, `job_reassignment`, `job_confirmation`, `job_start`, `step_completion`, `job_completion`, `job_cancelled`, `payment_reminder`, `system_alert`
- ❌ **NOT:** `job_start_deadline_warning_90min`, `job_start_deadline_warning_60min`

**Manager:**
- All driver types PLUS: `job_start_deadline_warning_90min`
- ❌ **NOT:** `job_start_deadline_warning_60min`

**Administrator/Super_Admin:**
- All types PLUS: `job_start_deadline_warning_60min`
- ❌ **NOT:** `job_start_deadline_warning_90min` (manager only)

**UI Impact:**
- UI should show role-appropriate notification types
- Currently shows same 6 types for all roles
- Missing role-specific deadline warnings

---

## 6. Complete Alignment Plan

### Phase 1: Fix Constants and Naming

**Tasks:**
1. ✅ Add missing constants to `NotificationConstants`:
   - `jobStart = 'job_start'`
   - `jobCompletion = 'job_completion'`
   - `stepCompletion = 'step_completion'`
2. ✅ Fix `jobCancellation` constant:
   - Option A: Rename to `jobCancelled` (match database)
   - Option B: Update all code to use `job_cancellation` (requires DB migration)
   - **Recommendation:** Option A (smaller change)

**Files to Modify:**
- `lib/core/constants/notification_constants.dart`

---

### Phase 2: Fix Preferences Storage

**Tasks:**
1. ✅ Update `NotificationPreferencesService`:
   - Change table from `user_notification_preferences` to `profiles`
   - Update to read/write `profiles.notification_prefs` (JSONB)
   - Use current user's profile ID
2. ✅ Create migration if needed:
   - Ensure `profiles.notification_prefs` column exists
   - Add index if needed

**Files to Modify:**
- `lib/features/notifications/services/notification_preferences_service.dart`
- `supabase/migrations/YYYYMMDDHHMMSS_fix_notification_preferences_storage.sql` (if needed)

---

### Phase 3: Update UI to Show All Types

**Tasks:**
1. ✅ Add missing notification type toggles:
   - Job Confirmation
   - Job Start
   - Job Completion
   - Step Completion
   - Job Start Deadline Warning (90 min) - Role: Manager only
   - Job Start Deadline Warning (60 min) - Role: Admin/Super_Admin only
2. ✅ Fix naming:
   - Use singular forms in state variables
   - Map UI labels to database values correctly
3. ✅ Add role-based visibility:
   - Show deadline warnings only to appropriate roles
   - Hide driver-only types from managers/admins if needed

**Files to Modify:**
- `lib/features/notifications/screens/notification_preferences_screen.dart`

---

### Phase 4: Implement Backend Integration

**Tasks:**
1. ✅ Load preferences on screen init:
   - Call `NotificationPreferencesService.getPreferences()`
   - Populate state variables
   - Handle loading/error states
2. ✅ Save preferences on change:
   - Implement `_savePreferences()` method
   - Call `NotificationPreferencesService.savePreferences()`
   - Show success/error feedback
3. ✅ Use Riverpod provider (optional):
   - Create `notificationPreferencesProvider`
   - Manage state reactively
   - Auto-save on change

**Files to Modify:**
- `lib/features/notifications/screens/notification_preferences_screen.dart`
- `lib/features/notifications/providers/notification_preferences_provider.dart` (new)

---

### Phase 5: Align Preference Keys

**Tasks:**
1. ✅ Standardize preference keys:
   - Use singular forms: `job_assignment` (not `job_assignments`)
   - Use correct cancellation key: `job_cancelled` (not `job_cancellation`)
   - Add all missing types
2. ✅ Update Edge Functions (if needed):
   - Ensure preference checks use correct keys
   - Add fallback for old keys during migration
3. ✅ Data migration (if needed):
   - Migrate existing preferences from plural to singular
   - Migrate `job_cancellation` to `job_cancelled`

**Files to Modify:**
- `lib/features/notifications/services/notification_preferences_service.dart`
- `supabase/functions/check-job-start-deadlines/index.ts` (verify)
- `supabase/functions/push-notifications-poller/index.ts` (verify)
- `supabase/migrations/YYYYMMDDHHMMSS_migrate_notification_preferences_keys.sql` (if needed)

---

### Phase 6: Testing and Validation

**Tasks:**
1. ✅ Test preference loading:
   - Verify preferences load from `profiles.notification_prefs`
   - Verify defaults apply if no preferences exist
2. ✅ Test preference saving:
   - Verify preferences save to database
   - Verify Edge Functions read updated preferences
3. ✅ Test notification filtering:
   - Disable a notification type
   - Trigger that notification type
   - Verify it's blocked (no push, but in-app may still appear)
4. ✅ Test role-based visibility:
   - Login as driver → Verify only driver types shown
   - Login as manager → Verify manager types + 90min warning
   - Login as admin → Verify all types + 60min warning
5. ✅ Test Edge Function integration:
   - Verify `check-job-start-deadlines` respects preferences
   - Verify `push-notifications-poller` respects preferences

---

## 7. Implementation Checklist

### 7.1 Constants and Naming
- [ ] Add `jobStart`, `jobCompletion`, `stepCompletion` to `NotificationConstants`
- [ ] Fix `jobCancellation` → `jobCancelled` in constants
- [ ] Update all references to use `jobCancelled`
- [ ] Verify `notification_card.dart` handles all types

### 7.2 Preferences Storage
- [ ] Update `NotificationPreferencesService` to use `profiles.notification_prefs`
- [ ] Remove references to `user_notification_preferences` table
- [ ] Verify `profiles.notification_prefs` column exists
- [ ] Add migration if column missing

### 7.3 UI Updates
- [ ] Add Job Confirmation toggle
- [ ] Add Job Start toggle
- [ ] Add Job Completion toggle
- [ ] Add Step Completion toggle
- [ ] Add Job Start Deadline Warning (90 min) toggle (manager only)
- [ ] Add Job Start Deadline Warning (60 min) toggle (admin/super_admin only)
- [ ] Fix naming: Use singular forms in state variables
- [ ] Fix `job_cancellations` → `job_cancelled` mapping
- [ ] Add role-based visibility logic

### 7.4 Backend Integration
- [ ] Implement `_loadPreferences()` method
- [ ] Call `_loadPreferences()` in `initState()`
- [ ] Implement `_savePreferences()` method
- [ ] Call `_savePreferences()` on toggle change
- [ ] Add loading states
- [ ] Add error handling
- [ ] Add success feedback

### 7.5 Preference Keys Alignment
- [ ] Update `_getDefaultPreferences()` to use singular keys
- [ ] Update `_getDefaultPreferences()` to include all types
- [ ] Update `_getDefaultPreferences()` to use `job_cancelled`
- [ ] Create data migration script (if needed)
- [ ] Verify Edge Functions use correct keys

### 7.6 Testing
- [ ] Test preference loading
- [ ] Test preference saving
- [ ] Test notification filtering
- [ ] Test role-based visibility
- [ ] Test Edge Function integration
- [ ] Test with existing user preferences (migration)

---

## 8. Files to Modify

### 8.1 Core Files
- `lib/core/constants/notification_constants.dart` - Add missing constants, fix naming
- `lib/features/notifications/services/notification_preferences_service.dart` - Fix storage, add methods
- `lib/features/notifications/screens/notification_preferences_screen.dart` - Add types, implement save/load

### 8.2 New Files (Optional)
- `lib/features/notifications/providers/notification_preferences_provider.dart` - Riverpod provider
- `supabase/migrations/YYYYMMDDHHMMSS_fix_notification_preferences_storage.sql` - Storage fix
- `supabase/migrations/YYYYMMDDHHMMSS_migrate_notification_preferences_keys.sql` - Key migration

### 8.3 Verification Files
- `supabase/functions/check-job-start-deadlines/index.ts` - Verify preference keys
- `supabase/functions/push-notifications-poller/index.ts` - Verify preference keys

---

## 9. Risk Assessment

### 9.1 Low Risk
- Adding missing constants
- Adding missing UI toggles
- Implementing save/load functionality

### 9.2 Medium Risk
- Changing preference storage location (if users have existing preferences)
- Migrating preference keys (plural → singular, `job_cancellation` → `job_cancelled`)
- Role-based UI visibility (need to test all roles)

### 9.3 High Risk
- Changing `job_cancellation` → `job_cancelled` in database (if data exists)
- Edge Function preference checks (if keys don't match, notifications may be blocked)

**Mitigation:**
- Test thoroughly with existing user data
- Provide migration scripts for preference keys
- Add fallback logic in Edge Functions for old keys
- Deploy in stages (constants → storage → UI → integration)

---

## 10. Success Criteria

✅ **Phase 1 Complete:**
- All notification types have constants
- Naming is consistent across codebase

✅ **Phase 2 Complete:**
- Preferences load from `profiles.notification_prefs`
- Preferences save to `profiles.notification_prefs`

✅ **Phase 3 Complete:**
- UI shows all 12 notification types
- Role-based visibility works correctly

✅ **Phase 4 Complete:**
- Preferences persist when toggled
- Loading states work correctly

✅ **Phase 5 Complete:**
- Preference keys match Edge Function expectations
- No data loss during migration

✅ **Phase 6 Complete:**
- All tests pass
- Edge Functions respect preferences
- Role-based filtering works

---

## 11. Next Steps

1. **Review this audit** with team
2. **Prioritize phases** based on user impact
3. **Create implementation tickets** for each phase
4. **Start with Phase 1** (lowest risk, foundational)
5. **Test incrementally** after each phase
6. **Deploy to staging** before production

---

**End of Audit Document**

