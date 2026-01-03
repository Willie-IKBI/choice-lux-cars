# Push Notifications Poller - Schedule Setup Instructions

**Date:** 2026-01-03  
**Function:** `push-notifications-poller`  
**Status:** Manual Dashboard Configuration Required

---

## ⚠️ IMPORTANT: Schedule Configuration Method

**Supabase CLI does NOT support scheduling Edge Functions.**  
Schedules must be configured via the **Supabase Dashboard** UI.

---

## Step-by-Step Dashboard Setup

### Step 1: Navigate to Edge Functions

1. Open **Supabase Dashboard**: https://supabase.com/dashboard
2. Select your project: **ChoiceLux-DB** (or project ref: `hgqrbekphumdlsifuamq`)
3. Go to: **Edge Functions** (left sidebar)

### Step 2: Open push-notifications-poller Function

1. Find **`push-notifications-poller`** in the functions list
2. Click on **`push-notifications-poller`** to open function details

### Step 3: Access Schedule Tab

**Expected UI:**
- You should see tabs: **Code**, **Settings**, **Logs**, **Schedule** (or **Cron**)
- Click on **Schedule** tab (or **Cron** tab if that's what appears)

**If Schedule Tab is Missing:**

If you don't see a Schedule/Cron tab, check:
1. **Settings tab** → Look for "Cron Jobs" or "Scheduled Jobs" section
2. **Function details page** → Look for "Schedule" button or link
3. **Project Settings** → **Cron Jobs** (if schedules are project-level)

### Step 4: Create New Schedule

**If Schedule Tab Exists:**

1. Click **"Add Schedule"** or **"New Schedule"** button
2. Fill in the form:
   - **Name:** `push-notifications-poller-cron`
   - **Cron Expression:** `*/2 * * * *`
   - **Enabled:** ✅ (check the box)
3. Click **"Save"** or **"Create Schedule"**

**Expected Confirmation:**
- Success message: "Schedule created successfully"
- Schedule appears in the list with:
  - Name: `push-notifications-poller-cron`
  - Cron: `*/2 * * * *`
  - Status: **Active** or **Enabled**

---

## Alternative: If Schedule Tab is Not Available

### Option A: Check Project-Level Cron Jobs

1. Go to **Project Settings** → **Cron Jobs** (or **Scheduled Jobs**)
2. Click **"Add Cron Job"**
3. Configure:
   - **Function:** Select `push-notifications-poller`
   - **Schedule:** `*/2 * * * *`
   - **Name:** `push-notifications-poller-cron`
   - **Enabled:** ✅

### Option B: Use Supabase Management API

If dashboard UI is not available, you can use the Supabase Management API:

```bash
curl -X POST \
  'https://api.supabase.com/v1/projects/hgqrbekphumdlsifuamq/functions/push-notifications-poller/schedules' \
  -H 'Authorization: Bearer <SUPABASE_ACCESS_TOKEN>' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "push-notifications-poller-cron",
    "cron": "*/2 * * * *",
    "enabled": true
  }'
```

**Note:** Requires Supabase Access Token (not service role key).

---

## Verification Checklist

After creating the schedule, verify:

- [ ] Schedule name: `push-notifications-poller-cron`
- [ ] Cron expression: `*/2 * * * *` (every 2 minutes)
- [ ] Status: **Active** or **Enabled**
- [ ] Function: `push-notifications-poller`
- [ ] Next run time: Shows next scheduled execution (if available)

---

## Expected Dashboard UI Elements

**If Schedule Tab Exists:**
```
┌─────────────────────────────────────────┐
│ push-notifications-poller                │
├─────────────────────────────────────────┤
│ [Code] [Settings] [Logs] [Schedule] ←──│
├─────────────────────────────────────────┤
│                                         │
│ Schedules                                │
│ ┌─────────────────────────────────────┐ │
│ │ Name: push-notifications-poller-cron│ │
│ │ Cron: */2 * * * *                   │ │
│ │ Status: Active                       │ │
│ │ [Edit] [Delete]                     │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ [+ Add Schedule]                        │
└─────────────────────────────────────────┘
```

**If Schedule is in Settings:**
```
┌─────────────────────────────────────────┐
│ Settings                                 │
├─────────────────────────────────────────┤
│ Secrets                                  │
│ Environment Variables                    │
│ ...                                      │
│ Cron Jobs / Scheduled Jobs              │
│ ┌─────────────────────────────────────┐ │
│ │ Function: push-notifications-poller │ │
│ │ Schedule: */2 * * * *               │ │
│ │ Enabled: ✅                          │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## Troubleshooting

### Schedule Tab Not Visible

**Possible Reasons:**
1. **Feature not enabled** - Cron/scheduling may require a paid plan
2. **UI location changed** - Check Settings tab or Project Settings
3. **Permissions** - Ensure you have admin/project owner access

**Action:**
- Check Supabase documentation for your plan tier
- Contact Supabase support if feature is unavailable

### Schedule Created But Not Running

**Check:**
1. Function logs for execution attempts
2. Schedule status (should be "Active")
3. Cron expression syntax (verify `*/2 * * * *` is correct)
4. Function `verify_jwt` setting (must be `false` for scheduled runs)

---

## Manual Verification After Setup

Once schedule is created, verify it's working:

1. **Wait 2-4 minutes** after creating schedule
2. **Check Edge Function Logs:**
   - Go to **Edge Functions** → `push-notifications-poller` → **Logs**
   - Look for execution entries every ~2 minutes
   - Should see: `=== PUSH NOTIFICATIONS POLLER STARTED ===`

3. **Check notification_delivery_log:**
   ```sql
   SELECT 
     notification_id,
     success,
     sent_at,
     error_message
   FROM public.notification_delivery_log
   ORDER BY sent_at DESC
   LIMIT 10;
   ```

4. **Verify schedule is active:**
   - Dashboard should show "Next run" time (if available)
   - Logs should show periodic executions

---

## Summary

**Schedule Configuration:**
- **Method:** Supabase Dashboard (UI only)
- **Name:** `push-notifications-poller-cron`
- **Cron:** `*/2 * * * *` (every 2 minutes)
- **Status:** Enabled/Active

**Next Steps:**
1. ✅ Create schedule via Dashboard
2. ✅ Verify schedule appears in list
3. ✅ Wait 2-4 minutes and check logs
4. ✅ Confirm function executes automatically

---

**End of Setup Instructions**

