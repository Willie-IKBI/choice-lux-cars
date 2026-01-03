# Notification Preferences Functionality Audit

**Date:** 2026-01-04  
**Purpose:** Identify which notification preference settings are functional vs. UI-only

---

## Executive Summary

**Problem:** The notification preferences screen displays many settings (delivery methods, sound, vibration, priority, quiet hours) that are **saved to the database** but **NOT actually enforced** by the notification system.

**Impact:** Users can configure these settings, but they have no effect on notification delivery, creating a misleading user experience.

---

## 1. Current State Analysis

### 1.1 What IS Functional ✅

| Setting | Saved to DB | Actually Used | Location |
|---------|-------------|---------------|----------|
| **Notification Type Toggles** | ✅ | ✅ | `push-notifications-poller` checks `prefs[notificationType] === false` |
| **Test Notification** | N/A | ✅ | `NotificationPreferencesService.sendTestNotification()` |
| **Clear All Notifications** | N/A | ✅ | `NotificationPreferencesService.clearAllNotifications()` |
| **Reset to Defaults** | ✅ | ✅ | Resets all state variables and saves |

---

### 1.2 What is NOT Functional ❌

| Setting | Saved to DB | Actually Used | Impact |
|---------|-------------|---------------|--------|
| **Push Notifications Toggle** | ✅ | ❌ | Users can disable push, but notifications still sent |
| **In-App Notifications Toggle** | ✅ | ❌ | Users can disable in-app, but notifications still shown |
| **Email Notifications Toggle** | ✅ | ❌ | Email system not implemented |
| **Sound Enabled** | ✅ | ❌ | FCM payload doesn't include sound settings |
| **Vibration Enabled** | ✅ | ❌ | FCM payload doesn't include vibration settings |
| **High Priority Only** | ✅ | ❌ | No filtering by priority in poller or UI |
| **Quiet Hours Enabled** | ✅ | ❌ | No time-based filtering in poller |
| **Quiet Hours Start/End** | ✅ | ❌ | No time-based filtering in poller |

---

## 2. Detailed Analysis

### 2.1 Delivery Methods

#### Push Notifications Toggle (`push_notifications`)

**Current Behavior:**
- ✅ Saved to `profiles.notification_prefs['push_notifications']`
- ❌ **NOT checked** in `push-notifications-poller/index.ts`
- ❌ **NOT checked** in `push-notifications/index.ts`
- ❌ **NOT checked** in `notification_service.dart`

**Expected Behavior:**
- If `push_notifications === false`, skip push delivery entirely
- Still create in-app notification (if `in_app_notifications === true`)

**Code Location:**
- `supabase/functions/push-notifications-poller/index.ts` (Line ~530-570)
- Currently only checks: `prefs[notificationType] === false`

**Fix Required:**
```typescript
// In push-notifications-poller/index.ts
const prefs = profile?.notification_prefs as Record<string, boolean> | null

// Check global push toggle
if (prefs && prefs['push_notifications'] === false) {
  console.log(`[${runId}] Notification ${notification.id}: skipped_push_disabled`)
  skippedPreferencesCount++
  continue
}

// Then check per-type toggle
if (prefs && prefs[notificationType] === false) {
  // ... existing logic
}
```

---

#### In-App Notifications Toggle (`in_app_notifications`)

**Current Behavior:**
- ✅ Saved to `profiles.notification_prefs['in_app_notifications']`
- ❌ **NOT checked** when creating `app_notifications` rows
- ❌ **NOT checked** in Flutter UI queries

**Expected Behavior:**
- If `in_app_notifications === false`, don't create `app_notifications` row
- Still send push (if `push_notifications === true`)

**Code Locations:**
- Edge Functions that create notifications (e.g., `check-job-start-deadlines`)
- Flutter `notification_service.dart` queries

**Fix Required:**
- Check preference before inserting into `app_notifications` table
- This would require changes in multiple Edge Functions

---

#### Email Notifications Toggle (`email_notifications`)

**Current Behavior:**
- ✅ Saved to `profiles.notification_prefs['email_notifications']`
- ❌ **Email system not implemented at all**
- ❌ No email sending code exists

**Expected Behavior:**
- If `email_notifications === true`, send email via email service
- Requires email infrastructure (SMTP, SendGrid, etc.)

**Fix Required:**
- Implement email sending infrastructure
- Add email sending logic to poller or separate email service
- This is a major feature addition

---

### 2.2 Sound & Vibration

#### Sound Enabled (`sound_enabled`)

**Current Behavior:**
- ✅ Saved to `profiles.notification_prefs['sound_enabled']`
- ❌ **NOT included in FCM payload**
- ❌ FCM uses default sound behavior

**Expected Behavior:**
- If `sound_enabled === false`, set FCM `sound: "silent"` or omit sound
- If `sound_enabled === true`, use default or custom sound

**Code Location:**
- `supabase/functions/push-notifications/index.ts` (FCM payload construction)

**Current FCM Payload:**
```typescript
const message = {
  token: token,
  notification: {
    title: title,
    body: message,
  },
  data: {
    // ... action data
  },
  // ❌ No sound field
}
```

**Fix Required:**
```typescript
const prefs = profile?.notification_prefs as Record<string, boolean> | null
const soundEnabled = prefs?.['sound_enabled'] !== false // Default to true

const message = {
  token: token,
  notification: {
    title: title,
    body: message,
  },
  data: {
    // ... action data
  },
  // Add sound control
  ...(soundEnabled ? {} : { sound: 'silent' }),
  // Or use Android-specific sound field
  android: {
    ...(soundEnabled ? {} : { sound: 'silent' }),
  },
  apns: {
    payload: {
      aps: {
        ...(soundEnabled ? {} : { sound: '' }),
      },
    },
  },
}
```

---

#### Vibration Enabled (`vibration_enabled`)

**Current Behavior:**
- ✅ Saved to `profiles.notification_prefs['vibration_enabled']`
- ❌ **NOT included in FCM payload**
- ❌ FCM uses default vibration behavior

**Expected Behavior:**
- If `vibration_enabled === false`, disable vibration in FCM payload
- If `vibration_enabled === true`, use default vibration

**Code Location:**
- `supabase/functions/push-notifications/index.ts` (FCM payload construction)

**Fix Required:**
```typescript
const prefs = profile?.notification_prefs as Record<string, boolean> | null
const vibrationEnabled = prefs?.['vibration_enabled'] !== false // Default to true

const message = {
  // ... other fields
  android: {
    ...(vibrationEnabled ? {} : { 
      notification: {
        vibrateTimingsMillis: [],
      }
    }),
  },
}
```

**Note:** FCM vibration control is platform-specific and may require Android/iOS-specific payloads.

---

### 2.3 Priority Settings

#### High Priority Only (`high_priority_only`)

**Current Behavior:**
- ✅ Saved to `profiles.notification_prefs['high_priority_only']`
- ❌ **NOT checked** in poller
- ❌ **NOT checked** in Flutter UI queries
- ❌ No filtering by `app_notifications.priority` field

**Expected Behavior:**
- If `high_priority_only === true`, only show/send notifications where `priority === 'high'`
- Filter both push and in-app notifications

**Code Locations:**
- `supabase/functions/push-notifications-poller/index.ts` (filter before processing)
- `lib/features/notifications/services/notification_service.dart` (filter queries)

**Fix Required:**
```typescript
// In push-notifications-poller/index.ts
const prefs = profile?.notification_prefs as Record<string, boolean> | null
const highPriorityOnly = prefs?.['high_priority_only'] === true

if (highPriorityOnly && notification.priority !== 'high') {
  console.log(`[${runId}] Notification ${notification.id}: skipped_low_priority`)
  skippedPreferencesCount++
  continue
}
```

```dart
// In notification_service.dart
final prefs = profileResponse['notification_prefs'] as Map<String, dynamic>?
final highPriorityOnly = prefs?['high_priority_only'] == true

var query = _supabase
    .from('app_notifications')
    .select()
    .eq('user_id', currentUser.id)
    .eq('is_hidden', false)

if (highPriorityOnly) {
  query = query.eq('priority', 'high')
}
```

---

### 2.4 Quiet Hours

#### Quiet Hours Enabled (`quiet_hours_enabled`)

**Current Behavior:**
- ✅ Saved to `profiles.notification_prefs['quiet_hours_enabled']`
- ✅ Saved to `profiles.notification_prefs['quiet_hours_start']` (e.g., "22:00")
- ✅ Saved to `profiles.notification_prefs['quiet_hours_end']` (e.g., "07:00")
- ❌ **NOT checked** in poller
- ❌ **NOT checked** in Flutter UI queries
- ❌ No time-based filtering

**Expected Behavior:**
- If `quiet_hours_enabled === true`, check current time against `quiet_hours_start` and `quiet_hours_end`
- If within quiet hours, skip push delivery (and optionally in-app)
- Handle timezone (should use user's timezone or SA time)

**Code Location:**
- `supabase/functions/push-notifications-poller/index.ts` (check before sending)

**Fix Required:**
```typescript
// In push-notifications-poller/index.ts
const prefs = profile?.notification_prefs as Record<string, boolean | string> | null
const quietHoursEnabled = prefs?.['quiet_hours_enabled'] === true

if (quietHoursEnabled) {
  const quietStart = prefs?.['quiet_hours_start'] as string | undefined // "22:00"
  const quietEnd = prefs?.['quiet_hours_end'] as string | undefined // "07:00"
  
  if (quietStart && quietEnd) {
    const now = new Date()
    const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
    
    // Handle overnight quiet hours (e.g., 22:00 - 07:00)
    const isQuietHours = isWithinQuietHours(currentTime, quietStart, quietEnd)
    
    if (isQuietHours) {
      console.log(`[${runId}] Notification ${notification.id}: skipped_quiet_hours`)
      skippedPreferencesCount++
      continue
    }
  }
}

function isWithinQuietHours(current: string, start: string, end: string): boolean {
  // Parse "HH:MM" format
  const [currentH, currentM] = current.split(':').map(Number)
  const [startH, startM] = start.split(':').map(Number)
  const [endH, endM] = end.split(':').map(Number)
  
  const currentMinutes = currentH * 60 + currentM
  const startMinutes = startH * 60 + startM
  const endMinutes = endH * 60 + endM
  
  // Handle overnight (e.g., 22:00 - 07:00)
  if (startMinutes > endMinutes) {
    return currentMinutes >= startMinutes || currentMinutes < endMinutes
  } else {
    return currentMinutes >= startMinutes && currentMinutes < endMinutes
  }
}
```

**Note:** Timezone handling is critical. Should use user's timezone or SA time consistently.

---

## 3. Implementation Priority

### Priority 1: Critical (Misleading UX)
1. **Push Notifications Toggle** - Users expect this to work
2. **Quiet Hours** - Common user expectation
3. **High Priority Only** - Useful filtering feature

### Priority 2: Nice to Have
4. **Sound Enabled** - Improves UX but not critical
5. **Vibration Enabled** - Improves UX but not critical
6. **In-App Notifications Toggle** - Less common use case

### Priority 3: Future Feature
7. **Email Notifications** - Requires email infrastructure

---

## 4. Recommended Actions

### Option A: Implement Missing Functionality (Recommended)

**Pros:**
- ✅ Delivers on user expectations
- ✅ Improves user experience
- ✅ Makes settings functional

**Cons:**
- ⚠️ Requires development time
- ⚠️ Requires testing
- ⚠️ May need timezone handling for quiet hours

**Estimated Effort:**
- Push Notifications Toggle: 2 hours
- Quiet Hours: 4 hours (including timezone handling)
- High Priority Only: 2 hours
- Sound/Vibration: 3 hours
- **Total: ~11 hours**

---

### Option B: Remove Non-Functional UI (Quick Fix)

**Pros:**
- ✅ Quick fix (removes misleading UI)
- ✅ No development time
- ✅ Honest UX

**Cons:**
- ❌ Removes potentially useful features
- ❌ Users lose ability to configure (even if not working)
- ❌ May need to re-add later

**Estimated Effort:**
- Remove UI elements: 1 hour
- Update defaults: 30 minutes
- **Total: ~1.5 hours**

---

### Option C: Hybrid Approach

**Phase 1 (Quick):** Remove clearly non-functional settings (email, sound/vibration if FCM doesn't support)
**Phase 2 (Implement):** Implement critical settings (push toggle, quiet hours, high priority)

**Pros:**
- ✅ Removes misleading UI quickly
- ✅ Implements important features
- ✅ Balanced approach

**Cons:**
- ⚠️ Requires two phases
- ⚠️ May confuse users if settings reappear

---

## 5. Detailed Implementation Plan (Option A)

### 5.1 Push Notifications Toggle

**File:** `supabase/functions/push-notifications-poller/index.ts`

**Change:**
```typescript
// Before checking per-type preference, check global push toggle
const prefs = profile?.notification_prefs as Record<string, boolean> | null

// Check global push toggle first
if (prefs && prefs['push_notifications'] === false) {
  console.log(`[${runId}] Notification ${notification.id}: skipped_push_disabled`)
  skippedPreferencesCount++
  
  // Log skip (unless dry_run)
  if (!dryRun) {
    await supabase
      .from('notification_delivery_log')
      .insert({
        notification_id: notification.id,
        user_id: notification.user_id,
        sent_at: new Date().toISOString(),
        success: false,
        error_message: 'skipped_push_disabled',
        fcm_response: { run_id: runId },
        retry_count: 0
      })
  }
  
  processedCount++
  continue
}

// Then check per-type toggle (existing logic)
if (prefs && prefs[notificationType] === false) {
  // ... existing logic
}
```

**Testing:**
- Set `push_notifications: false` for a user
- Create a notification
- Verify poller skips push delivery
- Verify delivery log shows `skipped_push_disabled`

---

### 5.2 Quiet Hours

**File:** `supabase/functions/push-notifications-poller/index.ts`

**Add helper function:**
```typescript
function isWithinQuietHours(
  currentTime: string, // "HH:MM" format
  quietStart: string,  // "HH:MM" format
  quietEnd: string     // "HH:MM" format
): boolean {
  const [currentH, currentM] = currentTime.split(':').map(Number)
  const [startH, startM] = quietStart.split(':').map(Number)
  const [endH, endM] = quietEnd.split(':').map(Number)
  
  const currentMinutes = currentH * 60 + currentM
  const startMinutes = startH * 60 + startM
  const endMinutes = endH * 60 + endM
  
  // Handle overnight quiet hours (e.g., 22:00 - 07:00)
  if (startMinutes > endMinutes) {
    return currentMinutes >= startMinutes || currentMinutes < endMinutes
  } else {
    return currentMinutes >= startMinutes && currentMinutes < endMinutes
  }
}
```

**Add check in processing loop:**
```typescript
const prefs = profile?.notification_prefs as Record<string, boolean | string> | null
const quietHoursEnabled = prefs?.['quiet_hours_enabled'] === true

if (quietHoursEnabled) {
  const quietStart = prefs?.['quiet_hours_start'] as string | undefined
  const quietEnd = prefs?.['quiet_hours_end'] as string | undefined
  
  if (quietStart && quietEnd) {
    // Get current time in SA timezone (or user's timezone)
    const now = new Date()
    // TODO: Convert to SA timezone or user's timezone
    const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`
    
    if (isWithinQuietHours(currentTime, quietStart, quietEnd)) {
      console.log(`[${runId}] Notification ${notification.id}: skipped_quiet_hours`)
      skippedPreferencesCount++
      
      if (!dryRun) {
        await supabase
          .from('notification_delivery_log')
          .insert({
            notification_id: notification.id,
            user_id: notification.user_id,
            sent_at: new Date().toISOString(),
            success: false,
            error_message: 'skipped_quiet_hours',
            fcm_response: { run_id: runId },
            retry_count: 0
          })
      }
      
      processedCount++
      continue
    }
  }
}
```

**Testing:**
- Set `quiet_hours_enabled: true`, `quiet_hours_start: "22:00"`, `quiet_hours_end: "07:00"`
- Create notification during quiet hours (e.g., 23:00)
- Verify poller skips push delivery
- Create notification outside quiet hours (e.g., 10:00)
- Verify poller sends push delivery

---

### 5.3 High Priority Only

**File:** `supabase/functions/push-notifications-poller/index.ts`

**Add check:**
```typescript
const prefs = profile?.notification_prefs as Record<string, boolean> | null
const highPriorityOnly = prefs?.['high_priority_only'] === true

if (highPriorityOnly && notification.priority !== 'high') {
  console.log(`[${runId}] Notification ${notification.id}: skipped_low_priority`)
  skippedPreferencesCount++
  
  if (!dryRun) {
    await supabase
      .from('notification_delivery_log')
      .insert({
        notification_id: notification.id,
        user_id: notification.user_id,
        sent_at: new Date().toISOString(),
        success: false,
        error_message: 'skipped_low_priority',
        fcm_response: { run_id: runId },
        retry_count: 0
      })
  }
  
  processedCount++
  continue
}
```

**File:** `lib/features/notifications/services/notification_service.dart`

**Update query:**
```dart
final prefs = profileResponse['notification_prefs'] as Map<String, dynamic>?
final highPriorityOnly = prefs?['high_priority_only'] == true

var query = _supabase
    .from('app_notifications')
    .select()
    .eq('user_id', currentUser.id)
    .eq('is_hidden', false)

if (highPriorityOnly) {
  query = query.eq('priority', 'high')
}
```

**Testing:**
- Set `high_priority_only: true` for a user
- Create notification with `priority: 'normal'`
- Verify poller skips push delivery
- Verify Flutter UI doesn't show notification
- Create notification with `priority: 'high'`
- Verify poller sends push delivery
- Verify Flutter UI shows notification

---

### 5.4 Sound & Vibration

**File:** `supabase/functions/push-notifications/index.ts`

**Update FCM payload:**
```typescript
const prefs = profile?.notification_prefs as Record<string, boolean> | null
const soundEnabled = prefs?.['sound_enabled'] !== false // Default to true
const vibrationEnabled = prefs?.['vibration_enabled'] !== false // Default to true

const message: any = {
  token: token,
  notification: {
    title: title,
    body: message,
  },
  data: {
    // ... action data
  },
}

// Android sound control
if (!soundEnabled) {
  message.android = {
    ...message.android,
    notification: {
      ...message.android?.notification,
      sound: 'silent',
    },
  }
}

// iOS sound control
if (!soundEnabled) {
  message.apns = {
    ...message.apns,
    payload: {
      aps: {
        ...message.apns?.payload?.aps,
        sound: '',
      },
    },
  }
}

// Android vibration control
if (!vibrationEnabled) {
  message.android = {
    ...message.android,
    notification: {
      ...message.android?.notification,
      vibrateTimingsMillis: [],
    },
  }
}
```

**Testing:**
- Set `sound_enabled: false` for a user
- Send push notification
- Verify Android device receives silent notification
- Set `vibration_enabled: false` for a user
- Send push notification
- Verify Android device receives notification without vibration

**Note:** FCM sound/vibration control is platform-specific and may require additional testing.

---

## 6. Recommendation

**Recommended Approach:** **Option A (Implement Missing Functionality)**

**Rationale:**
1. Users expect these settings to work
2. Settings are already saved to database
3. Implementation is straightforward (mostly preference checks)
4. Improves user experience significantly

**Implementation Order:**
1. **Push Notifications Toggle** (2 hours) - Critical
2. **Quiet Hours** (4 hours) - High user value
3. **High Priority Only** (2 hours) - Useful filtering
4. **Sound/Vibration** (3 hours) - Nice to have

**Total Estimated Time:** ~11 hours

**Alternative:** If time is limited, implement Priority 1 items only (Push Toggle, Quiet Hours, High Priority) = ~8 hours.

---

## 7. Testing Checklist

### 7.1 Push Notifications Toggle
- [ ] Set `push_notifications: false`
- [ ] Create notification
- [ ] Verify poller skips push delivery
- [ ] Verify delivery log shows `skipped_push_disabled`
- [ ] Verify in-app notification still appears (if `in_app_notifications: true`)

### 7.2 Quiet Hours
- [ ] Set `quiet_hours_enabled: true`, `quiet_hours_start: "22:00"`, `quiet_hours_end: "07:00"`
- [ ] Create notification at 23:00 (within quiet hours)
- [ ] Verify poller skips push delivery
- [ ] Create notification at 10:00 (outside quiet hours)
- [ ] Verify poller sends push delivery
- [ ] Test overnight boundary (e.g., 06:00 should be quiet, 08:00 should not)

### 7.3 High Priority Only
- [ ] Set `high_priority_only: true`
- [ ] Create notification with `priority: 'normal'`
- [ ] Verify poller skips push delivery
- [ ] Verify Flutter UI doesn't show notification
- [ ] Create notification with `priority: 'high'`
- [ ] Verify poller sends push delivery
- [ ] Verify Flutter UI shows notification

### 7.4 Sound & Vibration
- [ ] Set `sound_enabled: false`
- [ ] Send push notification
- [ ] Verify Android device receives silent notification
- [ ] Set `vibration_enabled: false`
- [ ] Send push notification
- [ ] Verify Android device receives notification without vibration

---

## 8. Conclusion

**Current State:** Many notification preference settings are saved to the database but not enforced, creating a misleading user experience.

**Recommended Action:** Implement the missing functionality, starting with critical settings (Push Toggle, Quiet Hours, High Priority Only).

**Estimated Effort:** ~11 hours for full implementation, ~8 hours for critical features only.

---

**End of Audit**

