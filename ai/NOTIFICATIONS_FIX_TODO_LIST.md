# Notification System Fix - TODO List

**Date:** 2026-01-04  
**Status:** Ready for Implementation  
**Priority:** High - Notification preferences are non-functional

---

## Overview

This document contains all TODO tasks to fix the notification system alignment issues identified in the audit. Tasks are organized by phase and priority.

---

## Phase 1: Fix Constants and Naming (HIGH PRIORITY)

### Task 1.1: Add Missing Constants
**File:** `lib/core/constants/notification_constants.dart`  
**Priority:** High  
**Estimated Time:** 15 minutes

- [ ] Add `static const String jobStart = 'job_start';`
- [ ] Add `static const String jobCompletion = 'job_completion';`
- [ ] Add `static const String stepCompletion = 'step_completion';`
- [ ] Verify all constants are properly formatted

**Acceptance Criteria:**
- All 12 notification types have constants defined
- Constants match database values exactly

---

### Task 1.2: Fix jobCancellation Constant
**File:** `lib/core/constants/notification_constants.dart`  
**Priority:** High  
**Estimated Time:** 30 minutes

- [ ] Rename `jobCancellation` to `jobCancelled` in constants
- [ ] Search codebase for all references to `jobCancellation`
- [ ] Update all references to use `jobCancelled`
- [ ] Update `notification_card.dart` if it references `job_cancellation`

**Files to Check:**
- `lib/core/constants/notification_constants.dart`
- `lib/features/notifications/widgets/notification_card.dart`
- `lib/features/notifications/screens/notification_list_screen.dart`
- Any other files using `jobCancellation`

**Acceptance Criteria:**
- No references to `job_cancellation` remain (except in comments)
- All code uses `job_cancelled` consistently

---

## Phase 2: Fix Preferences Storage (HIGH PRIORITY)

### Task 2.1: Verify profiles.notification_prefs Column Exists
**File:** Database migration (if needed)  
**Priority:** High  
**Estimated Time:** 15 minutes

- [ ] Query database to check if `profiles.notification_prefs` column exists
- [ ] If missing, create migration to add column:
  ```sql
  ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS notification_prefs JSONB DEFAULT '{}'::jsonb;
  ```
- [ ] Add index if needed for performance

**Acceptance Criteria:**
- Column exists in `profiles` table
- Column is JSONB type with default empty object

---

### Task 2.2: Fix NotificationPreferencesService Storage
**File:** `lib/features/notifications/services/notification_preferences_service.dart`  
**Priority:** High  
**Estimated Time:** 45 minutes

- [ ] Remove references to `user_notification_preferences` table
- [ ] Update `getPreferences()` to read from `profiles.notification_prefs`:
  ```dart
  final response = await _supabase
      .from('profiles')
      .select('notification_prefs')
      .eq('id', currentUser.id)
      .single();
  ```
- [ ] Update `savePreferences()` to write to `profiles.notification_prefs`:
  ```dart
  await _supabase
      .from('profiles')
      .update({
        'notification_prefs': preferences,
        'updated_at': SATimeUtils.getCurrentSATimeISO(),
      })
      .eq('id', currentUser.id);
  ```
- [ ] Update error handling
- [ ] Test read/write operations

**Acceptance Criteria:**
- Service reads from `profiles.notification_prefs`
- Service writes to `profiles.notification_prefs`
- No references to `user_notification_preferences` table

---

## Phase 3: Update UI to Show All Types (MEDIUM PRIORITY)

### Task 3.1: Add Missing Notification Type Toggles
**File:** `lib/features/notifications/screens/notification_preferences_screen.dart`  
**Priority:** Medium  
**Estimated Time:** 1 hour

- [ ] Add state variable: `bool _jobConfirmation = true;`
- [ ] Add state variable: `bool _jobStart = true;`
- [ ] Add state variable: `bool _jobCompletion = true;`
- [ ] Add state variable: `bool _stepCompletion = true;`
- [ ] Add state variable: `bool _jobStartDeadlineWarning90min = true;`
- [ ] Add state variable: `bool _jobStartDeadlineWarning60min = true;`
- [ ] Add UI toggles for each new type with appropriate icons and descriptions

**Acceptance Criteria:**
- All 12 notification types have UI toggles
- Each toggle has descriptive text and icon

---

### Task 3.2: Fix Naming in State Variables
**File:** `lib/features/notifications/screens/notification_preferences_screen.dart`  
**Priority:** Medium  
**Estimated Time:** 30 minutes

- [ ] Rename `_jobAssignments` → `_jobAssignment` (keep UI label plural)
- [ ] Rename `_jobReassignments` → `_jobReassignment`
- [ ] Rename `_jobStatusChanges` → `_jobStatusChange`
- [ ] Rename `_jobCancellations` → `_jobCancelled` (also fix mapping)
- [ ] Rename `_paymentReminders` → `_paymentReminder`
- [ ] Rename `_systemAlerts` → `_systemAlert`
- [ ] Update all references to these variables

**Acceptance Criteria:**
- State variables use singular forms
- UI labels remain user-friendly (can be plural)
- Mapping to database values is correct

---

### Task 3.3: Add Role-Based Visibility
**File:** `lib/features/notifications/screens/notification_preferences_screen.dart`  
**Priority:** Medium  
**Estimated Time:** 45 minutes

- [ ] Get current user role from auth/profile
- [ ] Show `job_start_deadline_warning_90min` only for `manager` role
- [ ] Show `job_start_deadline_warning_60min` only for `administrator` and `super_admin` roles
- [ ] Hide driver-only types from managers/admins if needed (optional)
- [ ] Add conditional rendering logic

**Acceptance Criteria:**
- Managers see 90min warning toggle
- Admins/super_admins see 60min warning toggle
- Drivers don't see deadline warnings
- All roles see appropriate notification types

---

## Phase 4: Implement Backend Integration (HIGH PRIORITY)

### Task 4.1: Implement Load Preferences
**File:** `lib/features/notifications/screens/notification_preferences_screen.dart`  
**Priority:** High  
**Estimated Time:** 1 hour

- [ ] Create `_loadPreferences()` async method
- [ ] Call `NotificationPreferencesService.getPreferences()`
- [ ] Map loaded preferences to state variables:
  ```dart
  final prefs = await NotificationPreferencesService().getPreferences();
  setState(() {
    _jobAssignment = prefs['job_assignment'] ?? true;
    _jobReassignment = prefs['job_reassignment'] ?? true;
    // ... etc
  });
  ```
- [ ] Call `_loadPreferences()` in `initState()`
- [ ] Add loading state indicator
- [ ] Handle errors gracefully

**Acceptance Criteria:**
- Preferences load on screen init
- Loading state is shown
- Errors are handled and displayed
- Defaults apply if no preferences exist

---

### Task 4.2: Implement Save Preferences
**File:** `lib/features/notifications/screens/notification_preferences_screen.dart`  
**Priority:** High  
**Estimated Time:** 1 hour

- [ ] Implement `_savePreferences()` method:
  ```dart
  void _savePreferences() async {
    try {
      final prefs = {
        'job_assignment': _jobAssignment,
        'job_reassignment': _jobReassignment,
        'job_status_change': _jobStatusChange,
        'job_cancelled': _jobCancelled,
        'job_confirmation': _jobConfirmation,
        'job_start': _jobStart,
        'job_completion': _jobCompletion,
        'step_completion': _stepCompletion,
        'payment_reminder': _paymentReminder,
        'system_alert': _systemAlert,
        // Add deadline warnings based on role
      };
      
      await NotificationPreferencesService().savePreferences(prefs);
      // Show success message
    } catch (e) {
      // Show error message
    }
  }
  ```
- [ ] Call `_savePreferences()` on each toggle change
- [ ] Add debouncing to prevent excessive saves (optional)
- [ ] Show success/error snackbar
- [ ] Handle network errors

**Acceptance Criteria:**
- Preferences save when toggled
- Success feedback is shown
- Errors are handled and displayed
- No excessive API calls

---

### Task 4.3: Add Loading and Error States
**File:** `lib/features/notifications/screens/notification_preferences_screen.dart`  
**Priority:** Medium  
**Estimated Time:** 30 minutes

- [ ] Add `bool _isLoading = false;` state variable
- [ ] Add `String? _errorMessage;` state variable
- [ ] Show loading indicator during load/save
- [ ] Display error message if load/save fails
- [ ] Disable toggles while loading

**Acceptance Criteria:**
- Loading states are visible
- Errors are displayed clearly
- UI is disabled during operations

---

## Phase 5: Align Preference Keys (MEDIUM PRIORITY)

### Task 5.1: Update Default Preferences
**File:** `lib/features/notifications/services/notification_preferences_service.dart`  
**Priority:** Medium  
**Estimated Time:** 30 minutes

- [ ] Update `_getDefaultPreferences()` to use singular keys:
  ```dart
  {
    'job_assignment': true,
    'job_reassignment': true,
    'job_status_change': true,
    'job_cancelled': true,  // Fixed name
    'job_confirmation': true,
    'job_start': true,
    'job_completion': true,
    'step_completion': true,
    'job_start_deadline_warning_90min': true,
    'job_start_deadline_warning_60min': true,
    'payment_reminder': true,
    'system_alert': true,
  }
  ```
- [ ] Remove plural keys
- [ ] Add all missing types

**Acceptance Criteria:**
- All keys use singular forms
- All notification types included
- `job_cancelled` used (not `job_cancellation`)

---

### Task 5.2: Create Preference Key Migration (if needed)
**File:** `supabase/migrations/YYYYMMDDHHMMSS_migrate_notification_preferences_keys.sql`  
**Priority:** Low (only if existing data)  
**Estimated Time:** 1 hour

- [ ] Check if any users have existing preferences with old keys
- [ ] Create migration script to convert:
  - `job_assignments` → `job_assignment`
  - `job_reassignments` → `job_reassignment`
  - `job_status_changes` → `job_status_change`
  - `job_cancellations` → `job_cancelled`
  - `payment_reminders` → `payment_reminder`
  - `system_alerts` → `system_alert`
- [ ] Add new keys for missing types
- [ ] Test migration on staging

**SQL Example:**
```sql
UPDATE public.profiles
SET notification_prefs = jsonb_build_object(
  'job_assignment', COALESCE(notification_prefs->'job_assignments', 'true'),
  'job_reassignment', COALESCE(notification_prefs->'job_reassignments', 'true'),
  -- ... etc
)
WHERE notification_prefs IS NOT NULL;
```

**Acceptance Criteria:**
- Old keys migrated to new keys
- No data loss
- New keys added with defaults

---

### Task 5.3: Verify Edge Function Preference Keys
**Files:** 
- `supabase/functions/check-job-start-deadlines/index.ts`
- `supabase/functions/push-notifications-poller/index.ts`  
**Priority:** Medium  
**Estimated Time:** 30 minutes

- [ ] Verify Edge Functions use singular keys
- [ ] Verify Edge Functions check `job_cancelled` (not `job_cancellation`)
- [ ] Add fallback for old keys during migration period (optional)
- [ ] Test preference checks work correctly

**Acceptance Criteria:**
- Edge Functions use correct preference keys
- Preference checks work as expected
- Fallback logic handles old keys (if implemented)

---

## Phase 6: Testing and Validation (HIGH PRIORITY)

### Task 6.1: Test Preference Loading
**Priority:** High  
**Estimated Time:** 30 minutes

- [ ] Test with user who has existing preferences
- [ ] Test with user who has no preferences (should use defaults)
- [ ] Test with corrupted preferences (should handle gracefully)
- [ ] Test loading state displays correctly
- [ ] Test error handling

**Test Cases:**
1. User with existing preferences → Should load correctly
2. New user → Should show defaults
3. Network error → Should show error message
4. Invalid JSON → Should use defaults

---

### Task 6.2: Test Preference Saving
**Priority:** High  
**Estimated Time:** 30 minutes

- [ ] Toggle each notification type
- [ ] Verify save is called
- [ ] Verify data is persisted in database
- [ ] Verify success message appears
- [ ] Test error handling (network failure, etc.)

**Test Cases:**
1. Toggle on → Should save `true`
2. Toggle off → Should save `false`
3. Network error → Should show error, revert toggle
4. Multiple rapid toggles → Should handle gracefully

---

### Task 6.3: Test Notification Filtering
**Priority:** High  
**Estimated Time:** 1 hour

- [ ] Disable `job_assignment` preference
- [ ] Trigger a job assignment notification
- [ ] Verify push notification is blocked
- [ ] Verify in-app notification still appears (if applicable)
- [ ] Repeat for other notification types

**Test Cases:**
1. Disabled type → Push blocked
2. Enabled type → Push sent
3. Missing preference → Default to enabled
4. Edge Function respects preferences

---

### Task 6.4: Test Role-Based Visibility
**Priority:** Medium  
**Estimated Time:** 45 minutes

- [ ] Login as driver → Verify only driver types shown
- [ ] Login as manager → Verify manager types + 90min warning
- [ ] Login as administrator → Verify all types + 60min warning
- [ ] Login as super_admin → Verify all types + 60min warning

**Test Cases:**
1. Driver → No deadline warnings
2. Manager → 90min warning only
3. Admin → 60min warning only
4. Super Admin → 60min warning only

---

### Task 6.5: Test Edge Function Integration
**Priority:** High  
**Estimated Time:** 1 hour

- [ ] Disable `job_start_deadline_warning_60min` for an admin
- [ ] Trigger deadline notification (via Edge Function)
- [ ] Verify notification is not sent (preference respected)
- [ ] Enable preference
- [ ] Trigger again → Verify notification is sent
- [ ] Test with `push-notifications-poller`

**Test Cases:**
1. Preference disabled → Notification blocked
2. Preference enabled → Notification sent
3. Poller respects preferences
4. Deadline checker respects preferences

---

## Summary

### Total Tasks: 25
### Estimated Total Time: ~12 hours

### Priority Breakdown:
- **High Priority:** 12 tasks (~7 hours)
- **Medium Priority:** 10 tasks (~4 hours)
- **Low Priority:** 3 tasks (~1 hour)

### Recommended Implementation Order:
1. Phase 1 (Constants) - Foundation
2. Phase 2 (Storage) - Critical for functionality
3. Phase 4 (Backend Integration) - Makes UI functional
4. Phase 3 (UI Updates) - User-facing improvements
5. Phase 5 (Key Alignment) - Data consistency
6. Phase 6 (Testing) - Validation throughout

---

## Notes

- **Start with Phase 1** - It's the foundation and lowest risk
- **Test incrementally** - Don't wait until the end
- **Deploy to staging first** - Test with real data
- **Monitor Edge Functions** - Ensure preference checks work
- **Backup existing preferences** - Before running migrations

---

**End of TODO List**

