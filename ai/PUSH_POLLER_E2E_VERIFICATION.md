# Push Notifications Poller - E2E Verification

**Date:** 2026-01-03  
**Test Notification ID:** `137df6ef-bebd-4083-9ae3-cb0b548c8987`  
**User ID:** `3e59b0ec-1e8f-4975-b7b2-a58610a62212` (Russell Islam, driver_manager)

---

## Step 1: Verify FIREBASE_SERVICE_ACCOUNT_KEY Secret

### For `push-notifications-poller` Function

**Navigation Steps:**
1. Open **Supabase Dashboard**: https://supabase.com/dashboard
2. Select project: **ChoiceLux-DB** (ref: `hgqrbekphumdlsifuamq`)
3. Go to: **Edge Functions** (left sidebar)
4. Click: **`push-notifications-poller`**
5. Click: **Settings** tab
6. Scroll to: **Secrets** section
7. Look for: **`FIREBASE_SERVICE_ACCOUNT_KEY`**

**Expected Value Format:**
- **Type:** JSON string (entire service account key as single JSON object)
- **Format:** 
  ```json
  {
    "type": "service_account",
    "project_id": "choice-lux-cars-8d510",
    "private_key_id": "...",
    "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
    "client_email": "...@choice-lux-cars-8d510.iam.gserviceaccount.com",
    "client_id": "...",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token",
    "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
    "client_x509_cert_url": "..."
  }
  ```
- **Important:** The entire JSON must be on a single line or properly escaped as a string value

**Verification Checklist:**
- [ ] Secret name: `FIREBASE_SERVICE_ACCOUNT_KEY` (exact match, case-sensitive)
- [ ] Value is non-empty
- [ ] Value is valid JSON (can be parsed)
- [ ] Contains `private_key` field
- [ ] Contains `client_email` field
- [ ] Contains `project_id` field

---

### For `push-notifications` Function (Comparison)

**Navigation Steps:**
1. Same as above, but select **`push-notifications`** function
2. Go to **Settings** → **Secrets**
3. Check if `FIREBASE_SERVICE_ACCOUNT_KEY` exists

**Recommendation:**
- ✅ **SHARE the same secret** - Both functions use identical FCM authentication
- ✅ **Same secret name:** `FIREBASE_SERVICE_ACCOUNT_KEY`
- ✅ **Same value** - Copy from `push-notifications` to `push-notifications-poller` if missing

**Why Share:**
- Both functions use the same Firebase project (`choice-lux-cars-8d510`)
- Both use identical FCM authentication logic
- Reduces secret management overhead
- Ensures consistency

---

## Step 2: Manual Invocation

### Option A: GitHub Actions Workflow (Recommended)

1. Go to: **GitHub Repository** → **Actions** tab
2. Click: **"Push Notifications Poller"** workflow
3. Click: **"Run workflow"** button (top right)
4. Select branch: **`master`**
5. Click: **"Run workflow"** (green button)
6. Wait for workflow to complete (~10-30 seconds)

**Expected Output:**
- Status: ✅ Green checkmark (success)
- Logs show: `✅ SUCCESS: Function executed successfully (HTTP 200)`
- Metrics displayed: `processed`, `success_count`, `failure_count`

---

### Option B: Direct HTTP Invocation (Alternative)

```bash
curl -X POST \
  'https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/push-notifications-poller' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer YOUR_SERVICE_ROLE_KEY' \
  -d '{}'
```

**Expected Response:**
```json
{
  "success": true,
  "processed": 1,
  "success_count": 1,
  "failure_count": 0
}
```

---

## Step 3: Check Delivery Log

After manual invocation, run this SQL query:

```sql
SELECT 
  ndl.id,
  ndl.notification_id,
  ndl.user_id,
  ndl.success,
  ndl.error_message,
  ndl.retry_count,
  ndl.sent_at,
  ndl.fcm_response,
  an.message,
  an.notification_type
FROM public.notification_delivery_log ndl
INNER JOIN public.app_notifications an ON ndl.notification_id = an.id
WHERE ndl.notification_id = '137df6ef-bebd-4083-9ae3-cb0b548c8987'
ORDER BY ndl.sent_at DESC
LIMIT 5;
```

---

## Test Notification Details

- **Notification ID:** `137df6ef-bebd-4083-9ae3-cb0b548c8987`
- **User ID:** `3e59b0ec-1e8f-4975-b7b2-a58610a62212`
- **User Name:** Russell Islam
- **User Role:** driver_manager
- **Has Mobile Token:** ✅ Yes
- **Has Web Token:** ❌ No
- **Created At:** 2026-01-03 17:21:11 UTC

---

## Expected Results

### ✅ SUCCESS Case

**Delivery Log:**
- `success = true`
- `error_message = NULL`
- `fcm_response` contains: `{"success": 1, "message_id": "..."}`
- `retry_count = 1`

**PASS Checklist:**
- [ ] Delivery log entry exists
- [ ] `success = true`
- [ ] `error_message IS NULL`
- [ ] `fcm_response` contains success indicator
- [ ] Push notification received on device (if user is logged in)

---

### ❌ FAILURE Case

**Common Failure Reasons (Ranked):**

1. **Missing FIREBASE_SERVICE_ACCOUNT_KEY**
   - Error: `"Firebase Service Account Key not configured"`
   - Fix: Add secret in Dashboard → Edge Functions → push-notifications-poller → Settings → Secrets

2. **Invalid JSON in Secret**
   - Error: `"Failed to get Firebase access token: ..."`
   - Fix: Verify secret is valid JSON, properly escaped

3. **Invalid Service Account Key**
   - Error: `"Failed to get access token: 401 Unauthorized"`
   - Fix: Regenerate service account key in Firebase Console

4. **Invalid FCM Token**
   - Error: `fcm_response` contains `"error": "INVALID_ARGUMENT"` or `"UNREGISTERED"`
   - Fix: User needs to re-register FCM token (token expired/invalid)

5. **FCM API Rate Limit**
   - Error: `"error": "RESOURCE_EXHAUSTED"`
   - Fix: Wait and retry (temporary)

6. **Network/Timeout**
   - Error: `"error": "Network error"` or timeout
   - Fix: Check Edge Function logs, verify network connectivity

---

## Verification Queries

### Check Delivery Status
```sql
SELECT 
  notification_id,
  success,
  error_message,
  retry_count,
  sent_at,
  fcm_response->0->>'error' as fcm_error
FROM public.notification_delivery_log
WHERE notification_id = '137df6ef-bebd-4083-9ae3-cb0b548c8987'
ORDER BY sent_at DESC
LIMIT 1;
```

### Check if Notification Was Processed
```sql
SELECT 
  an.id,
  an.message,
  an.created_at,
  EXISTS (
    SELECT 1 FROM public.notification_delivery_log ndl
    WHERE ndl.notification_id = an.id
    AND ndl.success = true
  ) as successfully_delivered
FROM public.app_notifications an
WHERE an.id = '137df6ef-bebd-4083-9ae3-cb0b548c8987';
```

---

**End of Verification Guide**

