# Driver Job Confirmation - Deployment Guide

## 🚀 **Phase 1: Backend Deployment**

### **Step 1: Deploy Supabase Edge Function**

1. **Navigate to Supabase Dashboard**
   - Go to your Supabase project dashboard
   - Navigate to Edge Functions section

2. **Deploy the Edge Function**
   ```bash
   # From your project root
   supabase functions deploy process-job-notifications
   ```

3. **Set Environment Variables**
   - In Supabase Dashboard → Settings → Edge Functions
   - Add environment variable: `FIREBASE_SERVER_KEY`
   - Value: Your Firebase Server Key from Firebase Console

### **Step 2: Execute Database Migration**

1. **Run the SQL Migration**
   - Go to Supabase Dashboard → SQL Editor
   - Execute the migration: `supabase/migrations/20241208_job_assignment_trigger.sql`
   - This creates the notification log table and triggers

2. **Verify Table and Trigger Creation**
   ```sql
   -- Check if notification log table exists
   SELECT * FROM job_notification_log LIMIT 1;
   
   -- Check if trigger exists
   SELECT * FROM information_schema.triggers 
   WHERE trigger_name = 'job_assignment_trigger';
   ```

3. **Test the Trigger**
   ```sql
   -- Test by updating a job with a driver
   UPDATE jobs 
   SET driver_id = 'your-test-driver-id' 
   WHERE id = 1;
   
   -- Check if notification was logged
   SELECT * FROM job_notification_log ORDER BY created_at DESC LIMIT 5;
   ```

4. **Process Notifications**
   ```bash
   # Call the Edge Function to process pending notifications
   curl -X POST https://your-project-ref.supabase.co/functions/v1/process-job-notifications \
     -H "Authorization: Bearer your-anon-key" \
     -H "Content-Type: application/json"
   ```

## 🚀 **Phase 2: Flutter App Deployment**

### **Step 1: Firebase Configuration**

1. **Get Firebase Server Key**
   - Go to Firebase Console → Project Settings → Cloud Messaging
   - Copy the Server Key

2. **Update Supabase Environment**
   - Add the Server Key to Supabase Edge Function environment variables

### **Step 2: Build and Deploy Flutter App**

1. **Test Locally**
   ```bash
   flutter run
   ```

2. **Build for Production**
   ```bash
   # Android
   flutter build apk --release
   
   # Web
   flutter build web --release
   ```

3. **Deploy to Vercel (Web)**
   - Connect your repository in the [Vercel dashboard](https://vercel.com); the `vercel.json` config handles the build
   - Or deploy manually: `vercel deploy --prebuilt build/web --prod` (after running `flutter build web --release`)

## 🧪 **Testing Checklist**

### **Backend Testing**
- [ ] Edge Function deploys successfully
- [ ] Database migration executes without errors
- [ ] Notification log table is created
- [ ] Database trigger fires when job is assigned
- [ ] Notifications are logged to the table
- [ ] Edge Function processes pending notifications
- [ ] FCM notification is sent to driver
- [ ] RLS policies work correctly

### **Flutter App Testing**
- [ ] App compiles without errors
- [ ] FCM service initializes properly
- [ ] Driver can see confirmation button
- [ ] Driver can confirm job assignment
- [ ] Admin can see confirmation status
- [ ] Driver reassignment works correctly

### **End-to-End Testing**
- [ ] Admin assigns job to driver
- [ ] Driver receives notification
- [ ] Driver confirms job
- [ ] Admin sees confirmed status
- [ ] Admin reassigns job to different driver
- [ ] New driver receives notification

## 🔧 **Troubleshooting**

### **Common Issues**

1. **FCM Notifications Not Working**
   - Check Firebase Server Key in Supabase
   - Verify FCM token is saved in user profile
   - Check device notification permissions

2. **Database Trigger Not Firing**
   - Verify trigger is created successfully
   - Check Edge Function URL in trigger
   - Test with manual job update

3. **Confirmation Button Not Showing**
   - Check user role and job assignment
   - Verify driver_confirm_ind field exists
   - Check RLS policies

### **Debug Commands**

```bash
# Check Supabase logs
supabase logs

# Test Edge Function locally
supabase functions serve job-assignment-notification

# Check Flutter logs
flutter logs
```

## 📱 **User Instructions**

### **For Drivers**
1. Enable notifications in app settings
2. When assigned a job, you'll receive a notification
3. Tap notification or open app to view job details
4. Click "Confirm Job" button to accept assignment

### **For Admins**
1. Create or edit jobs as usual
2. Assign driver from dropdown
3. Driver will be notified automatically
4. Monitor confirmation status in job list

## 🎯 **Success Metrics**

- **Notification Delivery Rate**: >95%
- **Confirmation Response Time**: <5 minutes
- **User Adoption**: >90% of drivers confirm jobs
- **System Reliability**: <1% notification failures

## 📞 **Support**

If you encounter issues:
1. Check the troubleshooting section above
2. Review Supabase and Firebase logs
3. Test with a simple job assignment
4. Contact development team if issues persist 