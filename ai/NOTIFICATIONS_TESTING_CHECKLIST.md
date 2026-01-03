# Notification System Testing Checklist

**Date:** 2026-01-04  
**Status:** Ready for Testing  
**Purpose:** Comprehensive testing guide for notification preferences system

---

## Pre-Testing Setup

### 1. Verify Database State

```sql
-- Check if migration was applied
SELECT version, name 
FROM supabase_migrations.schema_migrations 
WHERE name = 'migrate_notification_preferences_keys';

-- Check notification_prefs column
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'profiles'
  AND column_name = 'notification_prefs';

-- Check sample user preferences
SELECT id, display_name, role, notification_prefs
FROM public.profiles
WHERE notification_prefs IS NOT NULL
  AND notification_prefs != '{}'::jsonb
LIMIT 3;
```

**Expected Results:**
- ✅ Migration exists in schema_migrations
- ✅ Column exists (JSONB, nullable, default `'{}'::jsonb`)
- ✅ Sample preferences use singular keys

---

## Test 1: Preference Loading

### 1.1 New User (No Preferences)

**Steps:**
1. Login as a user who has never set preferences
2. Navigate to Settings → Notification Settings
3. Observe loading state
4. Verify all toggles default to `ON` (true)

**Expected:**
- ✅ Loading spinner appears briefly
- ✅ All notification type toggles are ON
- ✅ All delivery method toggles are ON (except email)
- ✅ No errors displayed

**Verification SQL:**
```sql
-- Check if preferences were created
SELECT id, display_name, notification_prefs
FROM public.profiles
WHERE id = '<user_id>';
```

---

### 1.2 Existing User (With Preferences)

**Steps:**
1. Login as a user who has existing preferences
2. Navigate to Settings → Notification Settings
3. Observe loading state
4. Verify toggles reflect saved preferences

**Expected:**
- ✅ Loading spinner appears briefly
- ✅ Toggles match saved preferences
- ✅ No errors displayed

**Verification SQL:**
```sql
-- Check user's preferences
SELECT notification_prefs
FROM public.profiles
WHERE id = '<user_id>';
```

---

### 1.3 Error Handling

**Steps:**
1. Simulate network error (disable network temporarily)
2. Navigate to Settings → Notification Settings
3. Observe error state

**Expected:**
- ✅ Error message displayed
- ✅ Retry button available
- ✅ Clicking retry attempts to load again

---

## Test 2: Preference Saving

### 2.1 Toggle Individual Types

**Steps:**
1. Navigate to Notification Settings
2. Toggle "Job Assignments" OFF
3. Observe snackbar message
4. Refresh screen (navigate away and back)
5. Verify toggle is still OFF

**Expected:**
- ✅ Success snackbar appears
- ✅ Preference persists after refresh
- ✅ Database updated correctly

**Verification SQL:**
```sql
-- Check if preference was saved
SELECT notification_prefs->'job_assignment' as job_assignment
FROM public.profiles
WHERE id = '<user_id>';
-- Should return: false
```

---

### 2.2 Toggle Multiple Types

**Steps:**
1. Toggle 3-4 different notification types
2. Verify each shows success message
3. Refresh screen
4. Verify all changes persisted

**Expected:**
- ✅ All toggles save correctly
- ✅ No duplicate saves
- ✅ All preferences persist

---

### 2.3 Error Handling (Save Failure)

**Steps:**
1. Toggle a preference
2. Simulate network error (disable network)
3. Observe error handling

**Expected:**
- ✅ Error snackbar appears
- ✅ Toggle reverts to previous state (or shows error)
- ✅ User can retry

---

## Test 3: Role-Based Visibility

### 3.1 Driver Role

**Steps:**
1. Login as driver
2. Navigate to Notification Settings
3. Check visible notification types

**Expected:**
- ✅ Sees: job_assignment, job_reassignment, job_confirmation, job_status_change, job_cancelled, job_start, job_completion, step_completion, payment_reminder, system_alert
- ❌ Does NOT see: job_start_deadline_warning_90min, job_start_deadline_warning_60min

**Verification:**
- Count visible toggles: Should be 10 notification types

---

### 3.2 Manager Role

**Steps:**
1. Login as manager
2. Navigate to Notification Settings
3. Check visible notification types

**Expected:**
- ✅ Sees all driver types PLUS: job_start_deadline_warning_90min
- ❌ Does NOT see: job_start_deadline_warning_60min

**Verification:**
- Count visible toggles: Should be 11 notification types
- Verify 90min warning toggle is visible

---

### 3.3 Administrator Role

**Steps:**
1. Login as administrator
2. Navigate to Notification Settings
3. Check visible notification types

**Expected:**
- ✅ Sees all types PLUS: job_start_deadline_warning_60min
- ❌ Does NOT see: job_start_deadline_warning_90min (manager only)

**Verification:**
- Count visible toggles: Should be 11 notification types
- Verify 60min warning toggle is visible
- Verify 90min warning toggle is NOT visible

---

### 3.4 Super Admin Role

**Steps:**
1. Login as super_admin
2. Navigate to Notification Settings
3. Check visible notification types

**Expected:**
- ✅ Same as administrator (11 types including 60min warning)
- ❌ Does NOT see: job_start_deadline_warning_90min

**Verification:**
- Count visible toggles: Should be 11 notification types
- Verify 60min warning toggle is visible

---

## Test 4: Notification Filtering

### 4.1 Disable Notification Type

**Steps:**
1. Disable "Job Assignments" preference
2. Trigger a job assignment notification (assign job to user)
3. Verify push notification is NOT sent
4. Verify in-app notification still appears (if applicable)

**Expected:**
- ✅ Preference saved successfully
- ✅ Push notification blocked
- ✅ In-app notification may still appear (depends on implementation)

**Verification:**
- Check `notification_delivery_log` for skipped entries
- Check Edge Function logs for "skipped_preferences"

---

### 4.2 Enable Notification Type

**Steps:**
1. Enable "Job Assignments" preference
2. Trigger a job assignment notification
3. Verify push notification IS sent

**Expected:**
- ✅ Preference saved successfully
- ✅ Push notification sent
- ✅ Delivery logged

**Verification:**
- Check `notification_delivery_log` for successful delivery
- Verify push notification received on device

---

### 4.3 Test Multiple Types

**Steps:**
1. Disable 3 different notification types
2. Trigger each type
3. Verify all are blocked

**Expected:**
- ✅ All disabled types blocked
- ✅ Enabled types still work

---

## Test 5: Edge Function Integration

### 5.1 Deadline Warning Preferences

**Test for Manager (90min warning):**

**Steps:**
1. Login as manager
2. Disable "Job Start Deadline Warning (90 min)"
3. Create a job that will trigger 90min warning
4. Wait for scheduled Edge Function to run
5. Verify notification is NOT sent

**Expected:**
- ✅ Preference saved
- ✅ Edge Function creates notification
- ✅ Push poller skips due to preference
- ✅ No push notification received

**Verification SQL:**
```sql
-- Check if notification was created but push skipped
SELECT 
  an.id,
  an.notification_type,
  an.user_id,
  ndl.success,
  ndl.error_message
FROM public.app_notifications an
LEFT JOIN public.notification_delivery_log ndl ON an.id = ndl.notification_id
WHERE an.notification_type = 'job_start_deadline_warning_90min'
  AND an.user_id = '<manager_user_id>'
ORDER BY an.created_at DESC
LIMIT 1;
```

---

**Test for Admin (60min warning):**

**Steps:**
1. Login as administrator
2. Disable "Job Start Deadline Warning (60 min)"
3. Create a job that will trigger 60min warning
4. Wait for scheduled Edge Function to run
5. Verify notification is NOT sent

**Expected:**
- ✅ Preference saved
- ✅ Edge Function creates notification
- ✅ Push poller skips due to preference
- ✅ No push notification received

---

### 5.2 Push Notifications Poller

**Steps:**
1. Create a notification manually (via SQL or Flutter)
2. Disable that notification type for the user
3. Manually invoke push-notifications-poller
4. Verify notification is skipped

**Expected:**
- ✅ Poller logs "skipped_preferences"
- ✅ No push notification sent
- ✅ Delivery log shows skip reason

**Verification:**
- Check poller logs for skip message
- Check `notification_delivery_log` for `error_message = 'skipped_preferences'`

---

## Test 6: UI Functionality

### 6.1 Test Notification Button

**Steps:**
1. Click "Test Notification" button
2. Verify test notification is sent
3. Verify push notification received

**Expected:**
- ✅ Success message displayed
- ✅ Test notification appears in notification list
- ✅ Push notification received on device

---

### 6.2 Clear All Notifications

**Steps:**
1. Click "Clear All Notifications"
2. Confirm in dialog
3. Verify all notifications cleared

**Expected:**
- ✅ Confirmation dialog appears
- ✅ All notifications deleted
- ✅ Success message displayed
- ✅ Notification list is empty

**Verification SQL:**
```sql
-- Check if notifications were deleted
SELECT COUNT(*) as notification_count
FROM public.app_notifications
WHERE user_id = '<user_id>';
-- Should return: 0
```

---

### 6.3 Reset to Defaults

**Steps:**
1. Change several preferences
2. Click "Reset to Defaults"
3. Confirm in dialog
4. Verify all preferences reset to defaults

**Expected:**
- ✅ Confirmation dialog appears
- ✅ All toggles reset to ON (except email)
- ✅ Preferences saved to database
- ✅ Success message displayed

**Verification SQL:**
```sql
-- Check if preferences were reset
SELECT notification_prefs
FROM public.profiles
WHERE id = '<user_id>';
-- All notification types should be true
```

---

## Test 7: Backward Compatibility

### 7.1 Old Plural Keys

**Steps:**
1. Manually set old plural keys in database:
   ```sql
   UPDATE public.profiles
   SET notification_prefs = '{"job_assignments": false, "job_reassignments": true}'::jsonb
   WHERE id = '<user_id>';
   ```
2. Login as that user
3. Navigate to Notification Settings
4. Verify preferences load correctly

**Expected:**
- ✅ Preferences load from old plural keys
- ✅ Toggles reflect old values
- ✅ Saving converts to singular keys

**Verification SQL:**
```sql
-- Check if keys were converted
SELECT notification_prefs
FROM public.profiles
WHERE id = '<user_id>';
-- Should have singular keys, not plural
```

---

## Test 8: Edge Cases

### 8.1 Missing Preferences

**Steps:**
1. Set user's `notification_prefs` to `NULL`
2. Login and navigate to settings
3. Verify defaults are applied

**Expected:**
- ✅ No error
- ✅ All toggles default to ON
- ✅ Preferences can be saved

---

### 8.2 Empty Preferences

**Steps:**
1. Set user's `notification_prefs` to `'{}'::jsonb`
2. Login and navigate to settings
3. Verify defaults are applied

**Expected:**
- ✅ No error
- ✅ All toggles default to ON
- ✅ Preferences can be saved

---

### 8.3 Invalid JSON

**Steps:**
1. Manually corrupt `notification_prefs` (if possible)
2. Login and navigate to settings
3. Verify error handling

**Expected:**
- ✅ Error handled gracefully
- ✅ Defaults applied or error shown
- ✅ User can retry

---

## Test 9: Performance

### 9.1 Load Time

**Steps:**
1. Navigate to Notification Settings
2. Measure time to load

**Expected:**
- ✅ Loads within 1-2 seconds
- ✅ Loading spinner shows during load

---

### 9.2 Save Time

**Steps:**
1. Toggle a preference
2. Measure time to save

**Expected:**
- ✅ Saves within 500ms
- ✅ Success message appears quickly

---

## Test 10: Cross-Platform

### 10.1 Mobile (Android/iOS)

**Steps:**
1. Test on mobile device
2. Verify all UI elements visible
3. Test all functionality

**Expected:**
- ✅ All toggles visible and accessible
- ✅ No UI overlap or cut-off
- ✅ Touch targets are adequate size

---

### 10.2 Web

**Steps:**
1. Test on web browser
2. Verify all UI elements visible
3. Test all functionality

**Expected:**
- ✅ All toggles visible and accessible
- ✅ Responsive layout works
- ✅ No console errors

---

## Verification Queries

### Check User Preferences

```sql
-- Get user's current preferences
SELECT 
  id,
  display_name,
  role,
  notification_prefs
FROM public.profiles
WHERE id = '<user_id>';
```

### Check Notification Delivery

```sql
-- Check if notifications were sent/skipped
SELECT 
  an.id,
  an.notification_type,
  an.user_id,
  an.message,
  ndl.success,
  ndl.error_message,
  ndl.sent_at
FROM public.app_notifications an
LEFT JOIN public.notification_delivery_log ndl ON an.id = ndl.notification_id
WHERE an.user_id = '<user_id>'
  AND an.created_at > NOW() - INTERVAL '1 hour'
ORDER BY an.created_at DESC;
```

### Check Preference Keys Format

```sql
-- Verify all preferences use singular keys
SELECT 
  id,
  display_name,
  jsonb_object_keys(notification_prefs) as pref_key
FROM public.profiles
WHERE notification_prefs IS NOT NULL
  AND notification_prefs != '{}'::jsonb
  AND (
    notification_prefs ? 'job_assignments' OR
    notification_prefs ? 'job_reassignments' OR
    notification_prefs ? 'job_status_changes' OR
    notification_prefs ? 'job_cancellations' OR
    notification_prefs ? 'payment_reminders' OR
    notification_prefs ? 'system_alerts'
  );
-- Should return: 0 rows (no plural keys)
```

---

## Success Criteria

✅ **All tests pass:**
- Preferences load correctly
- Preferences save correctly
- Role-based visibility works
- Notification filtering works
- Edge Functions respect preferences
- UI is responsive and accessible
- Error handling is graceful
- Backward compatibility maintained

---

## Known Issues / Notes

- **None currently** - All implementation complete

---

## Test Results Template

```
Test Date: __________
Tester: __________
Environment: [ ] Staging [ ] Production

Test 1: Preference Loading
  [ ] 1.1 New User - PASS / FAIL
  [ ] 1.2 Existing User - PASS / FAIL
  [ ] 1.3 Error Handling - PASS / FAIL

Test 2: Preference Saving
  [ ] 2.1 Toggle Individual - PASS / FAIL
  [ ] 2.2 Toggle Multiple - PASS / FAIL
  [ ] 2.3 Error Handling - PASS / FAIL

Test 3: Role-Based Visibility
  [ ] 3.1 Driver - PASS / FAIL
  [ ] 3.2 Manager - PASS / FAIL
  [ ] 3.3 Administrator - PASS / FAIL
  [ ] 3.4 Super Admin - PASS / FAIL

Test 4: Notification Filtering
  [ ] 4.1 Disable Type - PASS / FAIL
  [ ] 4.2 Enable Type - PASS / FAIL
  [ ] 4.3 Multiple Types - PASS / FAIL

Test 5: Edge Function Integration
  [ ] 5.1 Deadline Warnings - PASS / FAIL
  [ ] 5.2 Push Poller - PASS / FAIL

Test 6: UI Functionality
  [ ] 6.1 Test Notification - PASS / FAIL
  [ ] 6.2 Clear All - PASS / FAIL
  [ ] 6.3 Reset Defaults - PASS / FAIL

Test 7: Backward Compatibility
  [ ] 7.1 Old Plural Keys - PASS / FAIL

Test 8: Edge Cases
  [ ] 8.1 Missing Preferences - PASS / FAIL
  [ ] 8.2 Empty Preferences - PASS / FAIL
  [ ] 8.3 Invalid JSON - PASS / FAIL

Test 9: Performance
  [ ] 9.1 Load Time - PASS / FAIL
  [ ] 9.2 Save Time - PASS / FAIL

Test 10: Cross-Platform
  [ ] 10.1 Mobile - PASS / FAIL
  [ ] 10.2 Web - PASS / FAIL

Overall Status: [ ] PASS [ ] FAIL
Notes: __________
```

---

**End of Testing Checklist**

