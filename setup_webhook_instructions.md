# Webhook Setup Instructions

## Step 1: Create Database Webhook in Supabase Dashboard

1. **Go to Supabase Dashboard**
   - Navigate to your project
   - Go to **Database** → **Webhooks**

2. **Create New Webhook**
   - Click **"Create a new webhook"**
   - **Name**: `push-notifications`
   - **Table**: `app_notifications`
   - **Events**: Select **INSERT** only
   - **HTTP Method**: `POST`
   - **URL**: `https://your-project-ref.supabase.co/functions/v1/push-notifications`
   - **Headers**: Leave empty (uses default auth)

3. **Save the Webhook**
   - Click **"Save"** to create the webhook

## Step 2: Set FCM Credentials

Run these commands in your terminal:

```bash
# Set FCM Server Key
supabase secrets set FCM_SERVER_KEY=your_fcm_server_key_here

# Set FCM Project ID  
supabase secrets set FCM_PROJECT_ID=your_fcm_project_id_here
```

## Step 3: Test Push Notifications

1. **Create a test notification** (we already have the script)
2. **Check Edge Function logs** in Supabase Dashboard
3. **Verify push notification** appears on device

## Step 4: Test Job Assignment Flow

1. **Assign a job to a driver** in the app
2. **Verify notification appears** in Flutter
3. **Check push notification** is sent
4. **Test job confirmation** flow
