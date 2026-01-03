# Push Notifications Poller Setup

**Date:** 2026-01-03  
**Status:** Implemented  
**Purpose:** Scheduled Edge Function that polls `app_notifications` and sends push notifications via FCM

---

## Overview

The `push-notifications-poller` Edge Function replaces the disabled pg_net trigger approach. It periodically checks for pending notifications (not successfully delivered) and sends push notifications via Firebase Cloud Messaging (FCM).

**Key Features:**
- ✅ No reliance on pg_net triggers
- ✅ Idempotent (won't send duplicates)
- ✅ Handles missing tokens gracefully
- ✅ Batch processing (50 notifications per run)
- ✅ Concurrency safety via advisory locks
- ✅ Respects user notification preferences

---

## Function Details

**Function Name:** `push-notifications-poller`  
**Location:** `supabase/functions/push-notifications-poller/index.ts`  
**JWT Verification:** `verify_jwt=false` (allows scheduled invocation)

---

## SQL Query for Pending Notifications

The function uses this query logic to find pending notifications:

```sql
-- Step 1: Get all non-hidden notifications, ordered by oldest first
SELECT 
  id, user_id, message, notification_type, priority, job_id, action_data, created_at
FROM public.app_notifications
WHERE is_hidden = false
ORDER BY created_at ASC
LIMIT 50

-- Step 2: Filter out notifications that already have successful delivery
-- A notification is considered delivered if:
-- EXISTS (
--   SELECT 1 FROM public.notification_delivery_log
--   WHERE notification_id = app_notifications.id
--   AND success = true
-- )
```

**Implementation:** The function fetches 50 notifications, then filters in-memory by checking `notification_delivery_log` for successful deliveries.

---

## Scheduling

### Recommended Schedule

**Cron Expression:** `*/2 * * * *` (every 2 minutes)

**Rationale:**
- Balances responsiveness with resource usage
- 2-minute delay is acceptable for push notifications
- Prevents excessive function invocations

### How to Add Schedule

**Option 1: Supabase Dashboard**
1. Go to **Edge Functions** → `push-notifications-poller`
2. Click **Schedule** tab
3. Add new schedule:
   - **Name:** `push-notifications-poller-cron`
   - **Cron Expression:** `*/2 * * * *`
   - **Enabled:** ✅

**Option 2: Supabase CLI**
```bash
supabase functions schedule push-notifications-poller \
  --cron "*/2 * * * *" \
  --name push-notifications-poller-cron
```

**Option 3: Manual SQL (if schedules table exists)**
```sql
INSERT INTO supabase_functions.schedules (
  name,
  schedule,
  function_name,
  enabled
) VALUES (
  'push-notifications-poller-cron',
  '*/2 * * * *',
  'push-notifications-poller',
  true
);
```

---

## Manual Invocation

### Via Supabase Dashboard
1. Go to **Edge Functions** → `push-notifications-poller`
2. Click **Invoke** button
3. Use empty body `{}` or no body
4. Check logs for results

### Via Supabase CLI
```bash
supabase functions invoke push-notifications-poller \
  --project-ref hgqrbekphumdlsifuamq
```

### Via HTTP Request
```bash
curl -X POST \
  'https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/push-notifications-poller' \
  -H 'Authorization: Bearer <SERVICE_ROLE_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{}'
```

---

## Deployment

### Initial Deployment

The function is already deployed via MCP. To redeploy:

**Via Supabase CLI:**
```bash
supabase functions deploy push-notifications-poller \
  --project-ref hgqrbekphumdlsifuamq
```

**Via Supabase Dashboard:**
1. Go to **Edge Functions**
2. Upload or edit `push-notifications-poller/index.ts`
3. Deploy

### Environment Variables Required

The function uses the same environment variables as `push-notifications`:
- `SUPABASE_URL` (auto-provided)
- `SUPABASE_SERVICE_ROLE_KEY` (auto-provided)
- `FIREBASE_SERVICE_ACCOUNT_KEY` (must be set in Supabase Dashboard)

**To set `FIREBASE_SERVICE_ACCOUNT_KEY`:**
1. Go to **Edge Functions** → `push-notifications-poller` → **Settings**
2. Add secret: `FIREBASE_SERVICE_ACCOUNT_KEY`
3. Paste the full JSON service account key

---

## How It Works

### 1. Advisory Lock
- Uses `pg_advisory_lock(1234567890)` to prevent concurrent runs
- If lock cannot be acquired, function exits gracefully
- Lock is released in `finally` block

### 2. Query Pending Notifications
- Fetches up to 50 non-hidden notifications, oldest first
- Filters out notifications with `success=true` in delivery log

### 3. Process Each Notification
- Re-checks for successful delivery (concurrency safety)
- Fetches user profile (tokens + preferences)
- Handles missing tokens: logs `error_message='missing_fcm_token'`
- Respects user preferences: skips if disabled
- Sends to all available tokens (mobile + web)
- Logs delivery attempt to `notification_delivery_log`

### 4. Retry Count
- Calculates: `COALESCE(MAX(retry_count), 0) + 1` for each notification
- Increments on each attempt

### 5. Delivery Logging
- One row per notification (not per token)
- `success=true` if at least one token succeeded
- `fcm_response` contains array of results for all tokens
- `retry_count` increments on each attempt

---

## Test Checklist

### Test 1: Notification with Valid Token
- [ ] Insert test notification for user with `fcm_token IS NOT NULL`
- [ ] Invoke poller manually
- [ ] Verify `notification_delivery_log` has row with `success=true`
- [ ] Verify push notification received on device

### Test 2: Notification with Missing Token
- [ ] Insert test notification for user with `fcm_token IS NULL`
- [ ] Invoke poller manually
- [ ] Verify `notification_delivery_log` has row with `success=false`, `error_message='missing_fcm_token'`

### Test 3: Idempotency
- [ ] Insert test notification
- [ ] Invoke poller (should send)
- [ ] Invoke poller again (should skip - already delivered)
- [ ] Verify only one successful delivery log entry

### Test 4: Batch Processing
- [ ] Insert 60 test notifications
- [ ] Invoke poller
- [ ] Verify exactly 50 notifications processed (oldest first)
- [ ] Invoke poller again
- [ ] Verify remaining 10 notifications processed

### Test 5: Concurrency Safety
- [ ] Invoke poller twice simultaneously (or within 1 second)
- [ ] Verify one run acquires lock, other exits gracefully
- [ ] Verify no duplicate sends

### Test 6: User Preferences
- [ ] Set user preference: `notification_prefs['system_alert'] = false`
- [ ] Insert `system_alert` notification for that user
- [ ] Invoke poller
- [ ] Verify delivery log has `success=false`, `error_message` contains 'preference'

---

## Monitoring

### Check Function Logs
1. **Supabase Dashboard:** Edge Functions → `push-notifications-poller` → **Logs**
2. **Supabase CLI:**
   ```bash
   supabase functions logs push-notifications-poller \
     --project-ref hgqrbekphumdlsifuamq
   ```

### Check Delivery Status
```sql
-- Recent delivery attempts
SELECT 
  ndl.id,
  ndl.notification_id,
  ndl.user_id,
  ndl.success,
  ndl.error_message,
  ndl.retry_count,
  ndl.sent_at,
  an.message,
  an.notification_type
FROM public.notification_delivery_log ndl
INNER JOIN public.app_notifications an ON ndl.notification_id = an.id
ORDER BY ndl.sent_at DESC
LIMIT 20;
```

### Check Pending Notifications
```sql
-- Notifications waiting for delivery
SELECT 
  an.id,
  an.user_id,
  an.message,
  an.notification_type,
  an.created_at,
  COUNT(ndl.id) as delivery_attempts,
  MAX(ndl.retry_count) as max_retry_count
FROM public.app_notifications an
LEFT JOIN public.notification_delivery_log ndl ON ndl.notification_id = an.id
WHERE an.is_hidden = false
AND NOT EXISTS (
  SELECT 1 FROM public.notification_delivery_log ndl2
  WHERE ndl2.notification_id = an.id
  AND ndl2.success = true
)
GROUP BY an.id, an.user_id, an.message, an.notification_type, an.created_at
ORDER BY an.created_at ASC
LIMIT 10;
```

---

## Troubleshooting

### Function Not Processing Notifications
1. Check function logs for errors
2. Verify `FIREBASE_SERVICE_ACCOUNT_KEY` is set
3. Verify schedule is enabled (if using scheduled runs)
4. Check advisory lock: if stuck, manually unlock:
   ```sql
   SELECT pg_advisory_unlock(1234567890);
   ```

### Notifications Not Being Delivered
1. Check delivery log for error messages
2. Verify user has `fcm_token` or `fcm_token_web`
3. Verify user preferences allow the notification type
4. Check FCM API responses in `fcm_response` JSONB field

### Duplicate Sends
1. Verify idempotency check is working (re-check before sending)
2. Verify advisory lock is preventing concurrent runs
3. Check delivery log for multiple `success=true` entries (should not happen)

---

## Performance Considerations

- **Batch Size:** 50 notifications per run (configurable in code)
- **Frequency:** Every 2 minutes (configurable in schedule)
- **Lock Timeout:** Advisory lock held for duration of function execution
- **FCM Rate Limits:** Function sends sequentially to avoid rate limits

---

## Future Enhancements

- [ ] Configurable batch size via environment variable
- [ ] Exponential backoff for retries
- [ ] Dead letter queue for permanently failed notifications
- [ ] Metrics/analytics dashboard
- [ ] Webhook notifications for delivery failures

---

**End of Setup Documentation**

