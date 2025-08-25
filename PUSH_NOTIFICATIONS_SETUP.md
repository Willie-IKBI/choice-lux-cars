# Push Notifications Setup Guide

## **🚀 STEP 1: DATABASE CLEANUP**

1. **Run the cleanup script** in your Supabase SQL editor:
   ```sql
   -- Copy and paste the entire disable_supabase_realtime_completely.sql file
   ```

2. **Verify cleanup was successful** - you should see:
   - "SUPABASE REALTIME COMPLETELY DISABLED!" message
   - No triggers remaining on jobs/notifications tables
   - Test notification created without HTTP errors

## **⚡ STEP 2: DEPLOY EDGE FUNCTION**

### **2.1 Set Environment Variables**
```bash
# Set FCM credentials
supabase secrets set FCM_SERVER_KEY=your_fcm_server_key_here
supabase secrets set FCM_PROJECT_ID=your_fcm_project_id_here
```

### **2.2 Deploy the Function**
```bash
supabase functions deploy push-notifications
```

### **2.3 Verify Deployment**
```bash
supabase functions list
```

## **🔗 STEP 3: CREATE DATABASE WEBHOOK**

### **3.1 Go to Supabase Dashboard**
1. Navigate to **Database → Webhooks**
2. Click **"Create a new webhook"**

### **3.2 Configure Webhook**
- **Name**: `notifications_push_webhook`
- **Table**: `notifications`
- **Events**: ✅ **INSERT** only
- **Type**: **Supabase Edge Functions**
- **Function**: `push-notifications`
- **Method**: `POST`
- **Timeout**: `1000` ms

### **3.3 Add Headers**
- Click **"Add new header"**
- Select **"Add auth header with service key"**
- Content-Type: `application/json`

### **3.4 Create Webhook**
Click **"Create webhook"**

## **📱 STEP 4: UPDATE FLUTTER APP**

### **4.1 Update JobAssignmentService**
Remove direct push notification calls - only insert to database:

```dart
// Remove this section from JobAssignmentService
// await _notificationService.sendPushNotification(...)
```

### **4.2 Test the Flow**
1. Assign a job to a driver
2. Check that notification appears in database
3. Verify push notification is received
4. Check Edge Function logs for any errors

## **🔧 STEP 5: GET FCM CREDENTIALS**

### **5.1 Firebase Console**
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Project Settings → Cloud Messaging**
4. Copy the **Server key**

### **5.2 Set Credentials**
```bash
supabase secrets set FCM_SERVER_KEY=your_server_key_here
supabase secrets set FCM_PROJECT_ID=your_project_id_here
```

## **✅ STEP 6: TESTING**

### **6.1 Test Job Assignment**
```dart
await JobAssignmentService.assignJobToDriver(
  jobId: 123,
  driverId: 'driver-uuid',
);
```

### **6.2 Check Logs**
- **Supabase Dashboard** → **Edge Functions** → **Logs**
- **Firebase Console** → **Analytics** → **Events**

### **6.3 Verify Flow**
1. ✅ Job assigned to driver
2. ✅ Notification inserted in database
3. ✅ Webhook triggered
4. ✅ Edge Function executed
5. ✅ Push notification sent via FCM
6. ✅ Notification received on device

## **🐛 TROUBLESHOOTING**

### **Common Issues:**
- **No FCM token**: User needs to register FCM token in profiles table
- **Webhook not triggering**: Check webhook configuration
- **Edge Function errors**: Check function logs
- **FCM errors**: Verify server key and project ID

### **Debug Commands:**
```bash
# Check function logs
supabase functions logs push-notifications

# Test function locally
supabase functions serve push-notifications

# Check webhook status
# Go to Supabase Dashboard → Database → Webhooks
```

## **🎯 SUCCESS CRITERIA**

- ✅ No HTTP queue errors when creating notifications
- ✅ Push notifications received on devices
- ✅ Clean separation of concerns (database vs HTTP)
- ✅ Reliable notification delivery
- ✅ Proper error handling and logging
