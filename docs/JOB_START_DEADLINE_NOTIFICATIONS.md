# Job Start Deadline Notifications

## Overview

Automated notification system that alerts managers and administrators when drivers haven't started jobs before the pickup time deadline.

## Notification Schedule

1. **90 minutes before pickup**: Managers receive notification if job hasn't started
2. **30 minutes before pickup**: Administrators receive notification if job still hasn't started

## Architecture

```
Supabase Cron (every 10 minutes)
  ↓
Edge Function: check-job-start-deadlines
  ↓
Database Function: get_jobs_needing_start_deadline_notifications
  ↓
Creates app_notifications records
  ↓
Webhook triggers push-notifications Edge Function
  ↓
Push notifications sent to managers/administrators
```

## Components

### 1. Database Function
- **File**: `supabase/migrations/20250111_job_start_deadline_notifications.sql`
- **Function**: `get_jobs_needing_start_deadline_notifications(p_current_time)`
- **Purpose**: Finds jobs needing deadline notifications
- **Criteria**:
  - Job has driver assigned
  - Job has earliest pickup_date from transport table
  - `driver_flow.job_started_at` is NULL
  - Job status is not 'cancelled' or 'completed'
  - Within 90-minute or 30-minute notification window

### 2. Edge Function
- **File**: `supabase/functions/check-job-start-deadlines/index.ts`
- **Purpose**: Scheduled function that checks and creates notifications
- **Features**:
  - Deduplication (checks if notification already sent)
  - Fan-out to all managers/administrators
  - Error handling and logging

### 3. Notification Types
- `job_start_deadline_warning_90min`: Manager notification
- `job_start_deadline_warning_30min`: Administrator notification

## Setup Instructions

### Step 1: Run Database Function SQL Script

**Option A: Direct SQL Execution (Recommended - Simplest)**

1. Go to Supabase Dashboard → SQL Editor
2. Open the file: `supabase/migrations/20250111_job_start_deadline_notifications.sql`
3. Copy the entire SQL script (starting from `-- Migration: Job Start Deadline Notifications`)
4. Paste into SQL Editor and click "Run"
5. Verify function was created:
   ```sql
   SELECT * FROM pg_proc WHERE proname = 'get_jobs_needing_start_deadline_notifications';
   ```

**Option B: Using Supabase CLI Migration**

If you prefer using migrations:
```bash
supabase db push
```

This will execute all pending migrations including the new one.

### Step 2: Deploy Edge Function

```bash
# From project root
supabase functions deploy check-job-start-deadlines
```

### Step 3: Configure Supabase Cron

**Option A: Using Supabase Dashboard (Recommended)**

1. Go to Supabase Dashboard → Database → Cron Jobs
2. Click "Create a new cron job"
3. Configure:
   - **Name**: `check_job_start_deadlines`
   - **Schedule**: `*/10 * * * *` (every 10 minutes)
   - **Command**: 
     ```sql
     SELECT net.http_post(
       url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-job-start-deadlines',
       headers := jsonb_build_object(
         'Content-Type', 'application/json',
         'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key')
       )
     );
     ```
   - **Enabled**: ✅

**Option B: Using SQL**

**Note**: Supabase requires `pg_net` extension for HTTP calls from cron jobs. This is typically enabled by default, but verify if needed.

```sql
-- Verify extensions are enabled
SELECT * FROM pg_extension WHERE extname IN ('pg_cron', 'pg_net');

-- If pg_cron is not enabled, enable it (requires superuser - contact Supabase support if needed)
-- CREATE EXTENSION IF NOT EXISTS pg_cron;

-- If pg_net is not enabled, enable it
CREATE EXTENSION IF NOT EXISTS pg_net;

-- Get your service role key (store it securely, or use Supabase secrets)
-- You can find it in Supabase Dashboard → Settings → API → service_role key

-- Create cron job to run every 10 minutes
SELECT cron.schedule(
  'check-job-start-deadlines',
  '*/10 * * * *', -- Every 10 minutes
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-job-start-deadlines',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
    ),
    body := '{}'::jsonb
  ) AS request_id;
  $$
);
```

**Important Notes**:
- Replace `YOUR_PROJECT_REF` with your actual Supabase project reference (found in Dashboard URL)
- Replace `YOUR_SERVICE_ROLE_KEY` with your actual service role key from Supabase Dashboard → Settings → API
- The cron job uses `pg_net` extension to make HTTP POST requests
- Cron jobs run on UTC time, so schedule accordingly

### Step 4: Verify Setup

1. **Test the database function manually**:
   ```sql
   SELECT * FROM get_jobs_needing_start_deadline_notifications(NOW());
   ```

2. **Test the Edge Function manually**:
   ```bash
   curl -X POST https://YOUR_PROJECT_REF.supabase.co/functions/v1/check-job-start-deadlines \
     -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY" \
     -H "Content-Type: application/json"
   ```

3. **Check cron job status**:
   ```sql
   SELECT * FROM cron.job WHERE jobname = 'check-job-start-deadlines';
   ```

4. **View cron job execution history**:
   ```sql
   SELECT * FROM cron.job_run_details 
   WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'check-job-start-deadlines')
   ORDER BY start_time DESC 
   LIMIT 10;
   ```

## Notification Message Format

- **Message**: "Warning job# {job_number} has not started with the driver {driver_name}"
- **Priority**: `high`
- **Type**: `job_start_deadline_warning_90min` or `job_start_deadline_warning_30min`
- **Recipients**: 
  - 90min: All active `manager` role users
  - 30min: All active `administrator` role users

## Deduplication

The system automatically prevents duplicate notifications by:
1. Checking `app_notifications` table for existing notification with same `job_id` and `notification_type`
2. Only sending if notification doesn't already exist

## Time Windows

- **90-minute window**: Checks between 90-85 minutes before pickup (5-minute window)
- **30-minute window**: Checks between 30-25 minutes before pickup (5-minute window)

This 5-minute window accounts for cron job frequency (every 10 minutes), ensuring notifications are caught.

## Troubleshooting

### No notifications being sent

1. **Check cron job is running**:
   ```sql
   SELECT * FROM cron.job_run_details 
   WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'check-job-start-deadlines')
   ORDER BY start_time DESC;
   ```

2. **Check Edge Function logs**:
   - Go to Supabase Dashboard → Edge Functions → check-job-start-deadlines → Logs

3. **Verify jobs exist**:
   ```sql
   -- Check if there are jobs that should trigger notifications
   SELECT 
     j.id,
     j.job_number,
     j.driver_id,
     j.job_status,
     MIN(t.pickup_date) as earliest_pickup,
     df.job_started_at
   FROM jobs j
   JOIN transport t ON j.id = t.job_id
   LEFT JOIN driver_flow df ON j.id = df.job_id
   WHERE j.driver_id IS NOT NULL
     AND df.job_started_at IS NULL
     AND j.job_status NOT IN ('cancelled', 'completed')
   GROUP BY j.id, j.job_number, j.driver_id, j.job_status, df.job_started_at;
   ```

### Notifications sent multiple times

- Check deduplication logic is working
- Verify `app_notifications` table has unique constraint on `job_id` + `notification_type` (if needed)

## Maintenance

### Updating Cron Schedule

```sql
-- Update cron schedule
SELECT cron.alter_job(
  (SELECT jobid FROM cron.job WHERE jobname = 'check-job-start-deadlines'),
  schedule := '*/5 * * * *' -- Change to every 5 minutes
);
```

### Disabling Cron Job

```sql
-- Disable cron job
SELECT cron.alter_job(
  (SELECT jobid FROM cron.job WHERE jobname = 'check-job-start-deadlines'),
  active := false
);
```

### Removing Cron Job

```sql
-- Remove cron job
SELECT cron.unschedule('check-job-start-deadlines');
```

## Related Files

- Database Migration: `supabase/migrations/20250111_job_start_deadline_notifications.sql`
- Edge Function: `supabase/functions/check-job-start-deadlines/index.ts`
- Notification Constants: `lib/core/constants/notification_constants.dart`
- Push Notifications Handler: `supabase/functions/push-notifications/index.ts`

