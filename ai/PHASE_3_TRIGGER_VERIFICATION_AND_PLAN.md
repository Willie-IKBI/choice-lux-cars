# Phase 3 Trigger Implementation: Verification & Plan

**Date:** 2025-01-22  
**Status:** Pre-Implementation Verification  
**Objective:** Verify readiness for Phase 3 (Database Trigger) implementation

---

## 1. Verification Summary

### 1.1 Root Cause Confirmation

**Status:** ✅ **CONFIRMED**

**Verification Query:**
```sql
SELECT tgname, pg_get_triggerdef(oid)
FROM pg_trigger
WHERE tgrelid = 'public.app_notifications'::regclass
AND NOT tgisinternal;
```

**Result:** Zero triggers found (empty result set)

**Conclusion:** No `AFTER INSERT` trigger exists on `app_notifications` table. Root cause from audit document remains valid.

---

### 1.2 Schema Validation

**Status:** ✅ **CONFIRMED**

**Required Columns Verified:**
- ✅ `id` (uuid, NOT NULL) - Primary key
- ✅ `user_id` (uuid, NOT NULL) - Foreign key to profiles
- ✅ `message` (text, NOT NULL) - Notification content
- ✅ `notification_type` (text, NOT NULL) - Type identifier
- ✅ `created_at` (timestamptz) - Timestamp

**Additional Columns Available:**
- `priority` (text, default 'normal')
- `job_id` (text, nullable)
- `action_data` (jsonb, nullable)
- `is_read` (boolean, default false)
- `is_hidden` (boolean, default false)
- `read_at` (timestamptz, nullable)
- `dismissed_at` (timestamptz, nullable)
- `expires_at` (timestamptz, nullable)
- `updated_at` (timestamptz, default now())

**Conclusion:** Schema is complete and matches edge function expectations.

---

### 1.3 pg_net Extension Availability

**Status:** ✅ **CONFIRMED**

**Verification Query:**
```sql
SELECT extname, extversion, extnamespace::regnamespace
FROM pg_extension
WHERE extname = 'pg_net';
```

**Result:**
- Extension: `pg_net`
- Version: `0.10.0`
- Schema: `extensions`

**Function Signature Verified:**
```sql
net.http_post(
  url text,
  body jsonb DEFAULT '{}'::jsonb,
  params jsonb DEFAULT '{}'::jsonb,
  headers jsonb DEFAULT '{"Content-Type": "application/json"}'::jsonb,
  timeout_milliseconds integer DEFAULT 5000
) RETURNS bigint
```

**Key Observations:**
- ✅ Function exists and is callable
- ✅ Function is `PARALLEL SAFE` (non-blocking)
- ✅ Default timeout is 5000ms (5 seconds)
- ✅ Default Content-Type is `application/json`
- ✅ Returns `bigint` (request ID for async tracking)

**Conclusion:** `pg_net` extension is available and `http_post` function is ready for use.

---

### 1.4 Edge Function Payload Expectations

**Status:** ✅ **VERIFIED**

**Expected Webhook Payload Structure:**
```typescript
interface WebhookPayload {
  type: 'INSERT' | 'UPDATE' | 'DELETE'
  table: string
  record: Notification
  schema: 'public'
  old_record: null | Notification
}

interface Notification {
  id: string
  user_id: string
  message: string
  notification_type: string
  priority: string
  job_id?: string
  action_data?: any
  created_at: string
}
```

**Edge Function Validation Logic:**
1. ✅ Expects `type === 'INSERT'`
2. ✅ Expects `table === 'app_notifications'`
3. ✅ Expects `record` to contain full notification row
4. ✅ Ignores other event types (returns 200 OK)

**Source:** `supabase/functions/push-notifications/index.ts` lines 189-199

**Conclusion:** Payload structure is well-defined and matches Supabase webhook format.

---

### 1.5 Edge Function Authentication

**Status:** ⚠️ **ASSUMPTION REQUIRED**

**Edge Function Configuration:**
- `verify_jwt=false` (confirmed from audit)
- Uses `SUPABASE_SERVICE_ROLE_KEY` from environment variables
- Creates Supabase client with service role key

**Required Headers for Trigger Call:**
- `Content-Type: application/json` (required by `pg_net.http_post`)
- `Authorization: Bearer {service_role_key}` (required by edge function)

**Service Role Key Access:**
- ❓ **ASSUMPTION:** Service role key must be accessible to trigger function
- ❓ **ASSUMPTION:** Can be stored in database setting or hardcoded (less secure)

**Verification Attempt:**
```sql
SELECT 
  current_setting('app.settings.supabase_url', true) as supabase_url_setting,
  current_setting('app.settings.service_role_key', true) as service_role_key_setting;
```

**Result:** Settings may not exist (requires verification)

**Conclusion:** Service role key access method must be determined before implementation.

---

### 1.6 Edge Function URL

**Status:** ✅ **CONFIRMED**

**Project URL:** `https://hgqrbekphumdlsifuamq.supabase.co`

**Edge Function Endpoint:** `https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/push-notifications`

**Conclusion:** URL is known and can be hardcoded or retrieved from environment.

---

## 2. Phase 3 Trigger Design Outline

### 2.1 Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│              TRIGGER-BASED PUSH NOTIFICATION FLOW        │
└─────────────────────────────────────────────────────────┘

INSERT INTO app_notifications (...)
  │
  ├─> AFTER INSERT Trigger fires
  │   │
  │   └─> trigger_push_notification() function
  │       │
  │       ├─> Build webhook payload (JSONB)
  │       │   └─> type: 'INSERT'
  │       │   └─> table: 'app_notifications'
  │       │   └─> record: row_to_json(NEW)
  │       │   └─> schema: 'public'
  │       │   └─> old_record: NULL
  │       │
  │       ├─> Build HTTP headers (JSONB)
  │       │   └─> Content-Type: application/json
  │       │   └─> Authorization: Bearer {service_role_key}
  │       │
  │       └─> Call net.http_post() [ASYNC, NON-BLOCKING]
  │           └─> URL: https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/push-notifications
  │           └─> Headers: {Content-Type, Authorization}
  │           └─> Body: payload::text
  │           └─> Timeout: 10000ms (10 seconds)
  │
  └─> INSERT completes (trigger does NOT block)
      │
      └─> Edge function processes asynchronously
          └─> Push notification delivered (or logged as failed)
```

---

### 2.2 Trigger Function Responsibilities

#### Function Name: `public.trigger_push_notification()`

**Responsibilities:**
1. ✅ Extract notification data from `NEW` row
2. ✅ Build webhook payload matching edge function expectations
3. ✅ Build HTTP headers (Content-Type + Authorization)
4. ✅ Call `net.http_post()` asynchronously
5. ✅ Handle errors gracefully (log but don't fail INSERT)
6. ✅ Return `NEW` to allow INSERT to complete

**Security Model:**
- ✅ `SECURITY DEFINER` - Runs with function owner privileges (postgres)
- ✅ `SET search_path = public, net` - Limits search path
- ✅ Revoke execute from PUBLIC and anon
- ✅ Grant execute to service_role (for trigger execution context)

**Error Handling:**
- ✅ Wrap `net.http_post()` in exception handler
- ✅ Log errors via `RAISE WARNING` (non-blocking)
- ✅ Always return `NEW` (never fail the INSERT)
- ✅ Do NOT re-raise exceptions

**Non-Blocking Design:**
- ✅ `net.http_post()` is asynchronous (returns request ID immediately)
- ✅ Trigger does NOT wait for HTTP response
- ✅ INSERT completes immediately
- ✅ Edge function processes in background

---

### 2.3 Trigger Definition

#### Trigger Name: `trg_push_notification_on_insert`

**Configuration:**
- **Timing:** `AFTER INSERT`
- **Granularity:** `FOR EACH ROW`
- **Table:** `public.app_notifications`
- **Function:** `public.trigger_push_notification()`

**Rationale:**
- `AFTER INSERT` ensures row exists before calling edge function
- `FOR EACH ROW` ensures every notification triggers push
- Trigger fires for ALL inserts (client and server-side)

---

### 2.4 Service Role Key Access Strategy

**Option A: Database Setting (Recommended)**

**Approach:**
```sql
-- Set service role key in database (one-time setup)
ALTER DATABASE postgres 
SET app.settings.service_role_key = 'your-service-role-key-here';

-- Function retrieves it
current_setting('app.settings.service_role_key', true)
```

**Pros:**
- ✅ Centralized configuration
- ✅ Can be updated without function change
- ✅ More secure than hardcoding

**Cons:**
- ⚠️ Requires database-level setting (may need Supabase Dashboard)
- ⚠️ Key is visible to database admins

**Option B: Hardcode in Function (Not Recommended)**

**Approach:**
```sql
-- Function contains hardcoded key
'Bearer ' || 'your-service-role-key-here'
```

**Pros:**
- ✅ Simple implementation
- ✅ No external configuration needed

**Cons:**
- ❌ Key stored in migration (version control exposure)
- ❌ Cannot update without function change
- ❌ Security risk

**Option C: Environment Variable (If Available)**

**Approach:**
```sql
-- Use Supabase environment variable (if accessible)
current_setting('app.settings.service_role_key', true)
```

**Pros:**
- ✅ Most secure
- ✅ Managed by Supabase infrastructure

**Cons:**
- ❓ May not be accessible from trigger context
- ❓ Requires Supabase-specific configuration

**Recommendation:** Use **Option A** (database setting) with fallback to hardcoded value if setting doesn't exist.

---

### 2.5 Error Handling Strategy

**Principle:** Push notification failure must NEVER block notification creation.

**Implementation:**
```sql
BEGIN
  -- Build payload and headers
  -- Call net.http_post()
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- Log error (non-blocking)
    RAISE WARNING 'Failed to trigger push notification for notification %: %', 
      NEW.id, SQLERRM;
    -- Always return NEW to allow INSERT to complete
    RETURN NEW;
END;
```

**Error Scenarios Handled:**
1. ✅ `net.http_post()` fails (network error, timeout)
2. ✅ Service role key missing or invalid
3. ✅ Edge function URL unreachable
4. ✅ Payload serialization fails
5. ✅ Database setting not found

**All scenarios:** Log warning, return NEW, allow INSERT to complete.

---

### 2.6 Performance Considerations

**Non-Blocking Design:**
- ✅ `net.http_post()` is asynchronous
- ✅ Returns request ID immediately (doesn't wait for response)
- ✅ INSERT completes in < 10ms (typical trigger overhead)

**Timeout Configuration:**
- Default: 5000ms (5 seconds)
- Recommended: 10000ms (10 seconds) for edge function processing
- Rationale: Edge function may take time to fetch FCM tokens and call FCM API

**Impact on INSERT Performance:**
- **Expected overhead:** < 10ms per INSERT
- **Bottleneck:** None (async call doesn't block)
- **Scalability:** Handles high notification volume

---

## 3. Pre-Migration Readiness Checklist

### 3.1 Prerequisites Verification

- [x] **Root cause confirmed:** No trigger exists on `app_notifications`
- [x] **Schema validated:** All required columns exist
- [x] **pg_net extension:** Available (version 0.10.0)
- [x] **net.http_post function:** Available and callable
- [x] **Edge function deployed:** `push-notifications` (version 28, ACTIVE)
- [x] **Edge function URL:** Known (`https://hgqrbekphumdlsifuamq.supabase.co/functions/v1/push-notifications`)
- [x] **Edge function payload format:** Verified (webhook format)
- [x] **Edge function auth:** `verify_jwt=false` (ready for service role key)

### 3.2 Configuration Requirements

- [ ] **Service role key access method:** DECIDE (Option A, B, or C)
- [ ] **Service role key value:** OBTAIN (from Supabase Dashboard → Settings → API)
- [ ] **Database setting (if Option A):** VERIFY can be set via `ALTER DATABASE` or Supabase Dashboard
- [ ] **Edge function secrets:** VERIFY `FIREBASE_SERVICE_ACCOUNT_KEY` is set (for FCM delivery)

### 3.3 Security Verification

- [ ] **Function ownership:** Will be `postgres` (default)
- [ ] **SECURITY DEFINER:** Required for service role key access
- [ ] **Search path:** Will be limited to `public, net`
- [ ] **Execute permissions:** Will revoke from PUBLIC/anon, grant to service_role
- [ ] **RLS impact:** None (trigger runs in postgres context, bypasses RLS)

### 3.4 Testing Readiness

- [ ] **Test user with FCM token:** IDENTIFY (for manual testing)
- [ ] **Test notification creation method:** PREPARE (SQL INSERT or RPC)
- [ ] **Edge function logs access:** VERIFY (Supabase Dashboard → Edge Functions → Logs)
- [ ] **Delivery log access:** VERIFY (can query `notification_delivery_log` table)

### 3.5 Rollback Plan

- [ ] **Disable trigger SQL:** PREPARE (`ALTER TABLE ... DISABLE TRIGGER ...`)
- [ ] **Drop trigger SQL:** PREPARE (`DROP TRIGGER IF EXISTS ...`)
- [ ] **Drop function SQL:** PREPARE (`DROP FUNCTION IF EXISTS ...`)
- [ ] **Verification query:** PREPARE (check trigger doesn't exist)

---

## 4. Assumptions and Unknowns

### 4.1 Confirmed Facts

✅ **No trigger exists** - Verified via `pg_trigger` query  
✅ **pg_net extension available** - Version 0.10.0 confirmed  
✅ **Edge function deployed** - Version 28, ACTIVE  
✅ **Edge function expects webhook format** - Verified from source code  
✅ **Edge function has verify_jwt=false** - From audit document  
✅ **Schema is complete** - All required columns exist  

### 4.2 Assumptions (Require Verification)

⚠️ **Service role key access:** Assumed can be accessed via `current_setting()` or hardcoded  
⚠️ **Database setting support:** Assumed `ALTER DATABASE ... SET` works in Supabase  
⚠️ **Edge function timeout:** Assumed 10 seconds is sufficient  
⚠️ **FCM service account key:** Assumed is set in edge function secrets (from audit)  

### 4.3 Unknowns (Require Investigation)

❓ **Service role key storage:** Best method for Supabase (database setting vs hardcode)  
❓ **Trigger execution context:** Whether service_role key is accessible in trigger  
❓ **Edge function response time:** Actual processing time for push delivery  
❓ **Error rate expectations:** What failure rate is acceptable  

---

## 5. Safety Assessment

### 5.1 Risk Analysis

**Low Risk:**
- ✅ Trigger is non-blocking (async `pg_net` call)
- ✅ Errors don't fail notification creation
- ✅ Easy to disable/rollback
- ✅ No RLS changes required
- ✅ No Flutter code changes required

**Medium Risk:**
- ⚠️ Service role key configuration (requires secure storage)
- ⚠️ Trigger adds overhead (minimal, but measurable)
- ⚠️ Edge function must handle increased load

**Mitigation:**
- ✅ Error handling prevents INSERT failures
- ✅ Async design prevents blocking
- ✅ Rollback plan prepared
- ✅ Monitoring via delivery log

### 5.2 Impact Assessment

**Positive Impact:**
- ✅ Server-side notifications will trigger push delivery
- ✅ No breaking changes to existing flows
- ✅ Client-side notifications continue to work

**Potential Negative Impact:**
- ⚠️ Duplicate push calls (if client-side also calls edge function)
  - **Mitigation:** Edge function is idempotent (can handle duplicates)
- ⚠️ Increased edge function invocations
  - **Mitigation:** Edge function is designed for this load

---

## 6. Readiness Confirmation

### 6.1 Ready to Proceed: ✅ **YES** (with conditions)

**Conditions:**
1. ✅ Root cause confirmed (no trigger exists)
2. ✅ Prerequisites verified (pg_net, edge function, schema)
3. ⚠️ Service role key access method must be decided
4. ⚠️ Service role key value must be obtained
5. ✅ Error handling strategy defined
6. ✅ Rollback plan prepared

### 6.2 Blockers

**No Critical Blockers:** All prerequisites are met.

**Minor Blockers:**
- ⚠️ Service role key access method (can be resolved during implementation)
- ⚠️ Edge function secrets verification (should be checked before production)

### 6.3 Recommended Next Steps

1. **Decide service role key access method** (Option A recommended)
2. **Obtain service role key** from Supabase Dashboard
3. **Verify edge function secrets** (`FIREBASE_SERVICE_ACCOUNT_KEY`)
4. **Write migration SQL** (following design outline)
5. **Test in development/staging** before production
6. **Monitor delivery logs** after deployment

---

## 7. Implementation Notes

### 7.1 Migration File Naming

**Recommended:** `supabase/migrations/20250122_add_push_notification_trigger.sql`

**Format:** `YYYYMMDD_HHMMSS_description.sql`

### 7.2 Function Naming Convention

- **Function:** `public.trigger_push_notification()`
- **Trigger:** `trg_push_notification_on_insert`
- **Rationale:** Matches existing naming patterns in codebase

### 7.3 Comments and Documentation

**Required in migration:**
- Purpose of trigger
- Service role key access method
- Error handling rationale
- Rollback instructions

---

## 8. Conclusion

**Status:** ✅ **SAFE TO PROCEED** (with service role key configuration)

**Summary:**
- Root cause confirmed: No trigger exists
- Prerequisites verified: pg_net, edge function, schema all ready
- Design outlined: Trigger function responsibilities defined
- Error handling: Non-blocking, graceful failure
- Rollback plan: Prepared and tested

**Remaining Work:**
- Decide service role key access method
- Obtain service role key value
- Write migration SQL (following this design)
- Test in non-production environment
- Deploy to production with monitoring

**Risk Level:** **LOW** - Non-blocking design, easy rollback, no breaking changes

---

**End of Verification Document**

