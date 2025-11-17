# FCM v1 API Setup Instructions

## Problem Fixed
- Removed duplicate `send-push-notification` function
- Updated `push-notifications` function to use FCM v1 API with service account
- Fixed environment variable inconsistency (`FCM_SERVER_KEY` → `FIREBASE_SERVICE_ACCOUNT_KEY`)

## Required Setup

### 1. Set Service Account Key in Supabase

You already have the service account key JSON. Set it as an environment variable:

```bash
# Set the entire service account JSON as a string
supabase secrets set FIREBASE_SERVICE_ACCOUNT_KEY='{"type":"service_account","project_id":"choice-lux-cars-8d510",...}'
```

**Important**: The entire JSON must be on one line as a string.

### 2. Deploy Updated Function

```bash
# Deploy the updated push-notifications function
supabase functions deploy push-notifications
```

### 3. Test the Fix

```sql
-- Insert a test notification
INSERT INTO app_notifications (
    user_id,
    message,
    notification_type,
    priority
) VALUES (
    'your-user-id-here',
    'Test notification from FCM v1',
    'system_alert',
    'normal'
);
```

## Key Changes Made

1. **Consolidated Functions**: Removed duplicate `send-push-notification`
2. **Updated Endpoint**: `https://fcm.googleapis.com/fcm/send` → `https://fcm.googleapis.com/v1/projects/choice-lux-cars-8d510/messages:send`
3. **Updated Auth**: `key=` → `Bearer` (OAuth2 with service account)
4. **Updated Message Format**: `to` → `token`, wrapped in `message` object
5. **Fixed Environment Variable**: `FCM_SERVER_KEY` → `FIREBASE_SERVICE_ACCOUNT_KEY`
6. **Added JWT Generation**: Automatically generates OAuth2 tokens from service account

## Why This Fixes the 404 Error

- The legacy FCM endpoint was deprecated/removed
- FCM v1 API uses OAuth2 authentication instead of server keys
- The new endpoint format includes your project ID
- Message format is slightly different in v1 API

Your PWA notifications should now work correctly!
