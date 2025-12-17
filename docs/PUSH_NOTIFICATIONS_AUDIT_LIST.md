# Push Notifications Audit - Complete List
**Date:** 2025-01-11  
**Scope:** All push notifications sent from the Choice Lux Cars application  
**Status:** Comprehensive audit of all notification types and triggers

---

## EXECUTIVE SUMMARY

This document provides a complete inventory of all push notifications implemented in the Choice Lux Cars application. Each notification is documented with its type, trigger point, recipients, priority, and message content.

**Total Notification Types:** 12  
**Total Trigger Points:** 15+  
**Delivery Method:** Firebase Cloud Messaging (FCM) via Supabase Edge Function

---

## NOTIFICATION TYPES INVENTORY

### 1. **Job Assignment** (`job_assignment`)
- **Priority:** High
- **Recipients:** Assigned Driver
- **Trigger Points:**
  - `lib/features/jobs/services/job_assignment_service.dart:19` - `assignJobToDriver()`
  - `lib/features/jobs/services/job_assignment_service.dart:41` - `notifyDriverOfNewJob()`
  - `lib/features/jobs/data/jobs_repository.dart:105` - When job is created with driver assigned
- **Message:** "New job #[jobNumber] has been assigned to you. Please confirm your assignment."
- **Push Title:** "New Job Assignment"
- **Action Data:**
  - `action`: `new_job_assigned`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `route`: `/jobs/{jobId}/summary`
- **Status:** ✅ Active

---

### 2. **Job Reassignment** (`job_reassignment`)
- **Priority:** High
- **Recipients:** Newly Assigned Driver
- **Trigger Points:**
  - `lib/features/jobs/services/job_assignment_service.dart:64` - `notifyDriverOfReassignment()`
  - `lib/features/jobs/data/jobs_repository.dart:156` - When job driver is changed
- **Message:** "Job #[jobNumber] has been reassigned to you. Please confirm your assignment."
- **Push Title:** "Job Reassigned"
- **Action Data:**
  - `action`: `job_reassigned`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `route`: `/jobs/{jobId}/summary`
- **Status:** ✅ Active

---

### 3. **Job Confirmation** (`job_confirmation`)
- **Priority:** High
- **Recipients:** All Administrators, Managers, Driver Managers
- **Trigger Points:**
  - `lib/features/jobs/providers/jobs_provider.dart:367` - When driver confirms job assignment
- **Message:** "Job Confirmed: [driverName] confirmed job #[jobNumber]"
- **Push Title:** "Job Confirmed"
- **Action Data:**
  - `action`: `job_status_changed`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `driver_name`: Driver display name
  - `route`: `/jobs/{jobId}/summary`
- **Status:** ✅ Active

---

### 4. **Job Cancellation** (`job_cancelled`)
- **Priority:** High
- **Recipients:** Assigned Driver (if any)
- **Trigger Points:**
  - `lib/features/jobs/providers/jobs_provider.dart:395` - When admin cancels a job
  - `lib/features/jobs/data/jobs_repository.dart` - Job cancellation logic
- **Message:** "Job #[jobNumber] has been cancelled."
- **Push Title:** "Job Cancelled"
- **Action Data:**
  - `action`: `job_cancelled`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `route`: `/jobs/{jobId}/summary`
- **Status:** ✅ Active

---

### 5. **Job Status Change** (`job_status_change`)
- **Priority:** Normal
- **Recipients:** Assigned Driver, Job Creator
- **Trigger Points:**
  - `lib/features/notifications/services/notification_service.dart:425` - `sendJobStatusChangeNotification()`
  - Triggered when job status changes (e.g., `in_progress`, `completed`)
- **Message:** 
  - "Job #[jobNumber] has started." (if status = `in_progress`)
  - "Job #[jobNumber] has been completed." (if status = `completed`)
  - "Job #[jobNumber] status updated to [newStatus]." (other statuses)
- **Push Title:**
  - "Job Started" (if status = `in_progress`)
  - "Job Completed" (if status = `completed`)
  - "Job Status Updated" (other statuses)
- **Action Data:**
  - `action`: `job_status_changed`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `old_status`: Previous status
  - `new_status`: New status
  - `route`: `/jobs/{jobId}/summary`
- **Status:** ✅ Active (but may not be fully implemented in job status update flows)

---

### 6. **Job Start** (`job_start`)
- **Priority:** High
- **Recipients:** All Administrators, Managers, Driver Managers
- **Trigger Points:**
  - `lib/features/jobs/services/driver_flow_api_service.dart:81` - `startJob()` method
  - When driver starts a job (marks job as started)
- **Message:** "Job Started: [driverName] is driving [passengerName] ([clientName]) - Job #[jobNumber]"
- **Push Title:** "Job Started"
- **Action Data:**
  - `action`: `job_status_changed`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `driver_name`: Driver display name
  - `client_name`: Client company name
  - `passenger_name`: Passenger name
  - `route`: `/jobs/{jobId}/summary`
- **Status:** ✅ Active

---

### 7. **Step Completion** (`step_completion`)
- **Priority:** Normal
- **Recipients:** All Administrators, Managers, Driver Managers
- **Trigger Points:**
  - `lib/features/jobs/services/driver_flow_api_service.dart:143` - `collectVehicle()` (Vehicle Collection)
  - `lib/features/jobs/services/driver_flow_api_service.dart:205` - `arriveAtPickup()` (Pickup Arrival)
  - `lib/features/jobs/services/driver_flow_api_service.dart:267` - `boardPassenger()` (Passenger Onboard)
  - `lib/features/jobs/services/driver_flow_api_service.dart:329` - `arriveAtDropoff()` (Dropoff Arrival)
  - `lib/features/jobs/services/driver_flow_api_service.dart:390` - `completeTrip()` (Trip Completion)
  - `lib/features/jobs/services/driver_flow_api_service.dart:451` - `returnVehicle()` (Vehicle Return)
- **Message:** "Driver Update: [driverName] completed [stepDisplayName] - Job #[jobNumber]"
- **Push Title:** "Driver Update"
- **Step Display Names:**
  - `vehicle_collection` → "Vehicle Collection"
  - `pickup_arrival` → "Pickup Arrival"
  - `passenger_onboard` → "Passenger Onboard"
  - `dropoff_arrival` → "Dropoff Arrival"
  - `trip_complete` → "Trip Completion"
  - `vehicle_return` → "Vehicle Return"
- **Action Data:**
  - `action`: `job_status_changed`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `driver_name`: Driver display name
  - `step_name`: Step identifier
  - `step_display_name`: Human-readable step name
  - `route`: `/jobs/{jobId}/summary`
- **Status:** ✅ Active

---

### 8. **Job Completion** (`job_completion`)
- **Priority:** High
- **Recipients:** All Administrators, Managers, Driver Managers
- **Trigger Points:**
  - `lib/features/jobs/services/driver_flow_api_service.dart:548` - `completeJob()` method
  - When driver completes all job steps and finalizes the job
- **Message:** "Job Completed: [driverName] finished job for [passengerName] ([clientName]) - Job #[jobNumber]"
- **Push Title:** "Job Completed"
- **Action Data:**
  - `action`: `job_status_changed`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `driver_name`: Driver display name
  - `client_name`: Client company name
  - `passenger_name`: Passenger name
  - `route`: `/jobs/{jobId}/summary`
- **Status:** ✅ Active

---

### 9. **Job Start Deadline Warning (90 minutes)** (`job_start_deadline_warning_90min`)
- **Priority:** High
- **Recipients:** All Managers
- **Trigger Points:**
  - `supabase/functions/check-job-start-deadlines/index.ts` - Scheduled Edge Function (runs every 10 minutes via Supabase Cron)
  - Database function: `get_jobs_needing_start_deadline_notifications()`
  - Triggered when job hasn't started and pickup time is within 90 minutes
- **Message:** "Warning job# [jobNumber] has not started with the driver [driverName]"
- **Push Title:** "Job Start Warning"
- **Action Data:**
  - `action`: `job_status_changed`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `driver_name`: Driver display name
  - `minutes_before_pickup`: 90
  - `route`: `/jobs/{jobId}/summary`
- **Deduplication:** Checks if notification already sent for this job + notification type
- **Status:** ✅ Active (Scheduled)

---

### 10. **Job Start Deadline Warning (30 minutes)** (`job_start_deadline_warning_30min`)
- **Priority:** High
- **Recipients:** All Administrators
- **Trigger Points:**
  - `supabase/functions/check-job-start-deadlines/index.ts` - Scheduled Edge Function (runs every 10 minutes via Supabase Cron)
  - Database function: `get_jobs_needing_start_deadline_notifications()`
  - Triggered when job hasn't started and pickup time is within 30 minutes
- **Message:** "Warning job# [jobNumber] has not started with the driver [driverName]"
- **Push Title:** "Job Start Urgent Warning"
- **Action Data:**
  - `action`: `job_status_changed`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `driver_name`: Driver display name
  - `minutes_before_pickup`: 30
  - `route`: `/jobs/{jobId}/summary`
- **Deduplication:** Checks if notification already sent for this job + notification type
- **Status:** ✅ Active (Scheduled)

---

### 11. **Payment Reminder** (`payment_reminder`)
- **Priority:** High
- **Recipients:** Job Creator, Client Contact, or specified user
- **Trigger Points:**
  - `lib/features/notifications/services/notification_service.dart:493` - `sendPaymentReminderNotification()`
  - Manual trigger or scheduled payment reminders (if implemented)
- **Message:** "Payment reminder: Job #[jobNumber] - $[amount] due"
- **Push Title:** "Payment Reminder"
- **Action Data:**
  - `action`: `payment_reminder`
  - `job_id`: Job ID
  - `job_number`: Job number
  - `amount`: Payment amount
  - `route`: `/jobs/{jobId}/payment`
- **Status:** ⚠️ Defined but may not be actively triggered

---

### 12. **System Alert** (`system_alert`)
- **Priority:** Normal/High/Urgent (configurable)
- **Recipients:** Specified user(s)
- **Trigger Points:**
  - `lib/features/notifications/services/notification_service.dart:543` - `sendSystemAlertNotification()`
  - Manual system alerts, maintenance notifications, etc.
- **Message:** Custom message (provided as parameter)
- **Push Title:** "System Alert" (or custom title)
- **Action Data:**
  - `action`: `system_alert`
  - Custom action data (provided as parameter)
- **Status:** ✅ Active (available for use)

---

## NOTIFICATION DELIVERY FLOW

```
1. App Code → NotificationService.createNotification()
   OR
   Edge Function → Direct insert to app_notifications table
   ↓
2. Insert record into app_notifications table
   ↓
3. Call Edge Function: push-notifications
   (via supabase.functions.invoke() or webhook trigger)
   ↓
4. Edge Function fetches user's FCM tokens
   (fcm_token for mobile, fcm_token_web for web)
   ↓
5. Edge Function sends to FCM API (v1)
   ↓
6. FCM delivers to device(s)
   ↓
7. Device shows system notification
   ↓
8. App handles notification tap → Navigate to route
```

---

## NOTIFICATION PRIORITIES

- **Low:** Not currently used
- **Normal:** Step completions, status changes, system alerts
- **High:** Job assignments, confirmations, cancellations, start/completion, deadline warnings, payment reminders
- **Urgent:** Not currently used (available for system alerts)

---

## RECIPIENT ROLES

### By Notification Type:

1. **Driver-Specific:**
   - Job Assignment
   - Job Reassignment
   - Job Cancellation
   - Job Status Change

2. **Management Team (Admin/Manager/Driver Manager):**
   - Job Confirmation
   - Job Start
   - Step Completion
   - Job Completion
   - Job Start Deadline Warning (90min) - Managers only
   - Job Start Deadline Warning (30min) - Administrators only

3. **Custom/Manual:**
   - Payment Reminder (specified user)
   - System Alert (specified user)

---

## EDGE FUNCTION DETAILS

### `push-notifications` Edge Function
- **Location:** `supabase/functions/push-notifications/index.ts`
- **Purpose:** Sends FCM push notifications when app_notifications records are created
- **Trigger:** 
  - Manual invocation via `supabase.functions.invoke()`
  - Webhook trigger (if configured)
- **Features:**
  - Fetches both `fcm_token` (mobile) and `fcm_token_web` (web)
  - Sends to all available tokens for the user
  - Uses FCM v1 API with Firebase Service Account
  - Logs delivery status to `notification_delivery_log` table
  - Handles errors gracefully

### `check-job-start-deadlines` Edge Function
- **Location:** `supabase/functions/check-job-start-deadlines/index.ts`
- **Purpose:** Scheduled function that checks for jobs needing deadline notifications
- **Schedule:** Runs every 10 minutes (via Supabase Cron)
- **Features:**
  - Calls database function `get_jobs_needing_start_deadline_notifications()`
  - Creates notifications for managers (90min) and administrators (30min)
  - Deduplication to prevent duplicate notifications
  - Fan-out to all users with target role

---

## DATABASE FUNCTION

### `get_jobs_needing_start_deadline_notifications(p_current_time)`
- **Location:** `supabase/migrations/20250111_job_start_deadline_notifications.sql`
- **Purpose:** Finds jobs that need deadline notifications
- **Criteria:**
  - Job has driver assigned
  - Job has earliest `pickup_date` from `transport` table
  - `driver_flow.job_started_at` is NULL
  - Job status is not 'cancelled' or 'completed'
  - Within 90-minute window (manager notification)
  - Within 30-minute window (administrator notification)

---

## NOTIFICATION CONSTANTS

**Location:** `lib/core/constants/notification_constants.dart`

Defined notification types:
- `jobAssignment`
- `jobReassignment`
- `jobStatusChange`
- `jobCancellation`
- `jobConfirmation`
- `jobStartDeadlineWarning90min`
- `jobStartDeadlineWarning30min`
- `paymentReminder`
- `systemAlert`

---

## FCM TOKEN MANAGEMENT

- **Mobile Token:** Stored in `profiles.fcm_token`
- **Web Token:** Stored in `profiles.fcm_token_web`
- **Update Location:** `lib/core/services/fcm_service.dart`
- **Update Trigger:** 
  - On user login (`lib/features/auth/providers/auth_provider.dart`)
  - On token refresh
  - On permission grant

---

## NOTIFICATION DELIVERY LOG

- **Table:** `notification_delivery_log`
- **Purpose:** Tracks FCM delivery status for each notification
- **Fields:**
  - `notification_id`
  - `user_id`
  - `fcm_token`
  - `fcm_response`
  - `sent_at`
  - `success`

---

## POTENTIAL ISSUES & RECOMMENDATIONS

### ⚠️ Issues Identified:

1. **Job Status Change Notifications:**
   - Defined but may not be actively triggered in all job status update flows
   - **Recommendation:** Audit job status update code paths

2. **Payment Reminder Notifications:**
   - Defined but no clear trigger point found
   - **Recommendation:** Implement scheduled payment reminder system if needed

3. **Notification Deduplication:**
   - Only implemented for deadline warnings
   - **Recommendation:** Consider deduplication for other notification types if needed

4. **Branch-Based Filtering:**
   - Notifications don't currently filter by branch
   - **Recommendation:** Consider adding branch filtering for management notifications

### ✅ Working Well:

- Job assignment/reassignment flow
- Driver flow step completion notifications
- Job start/completion notifications
- Deadline warning system
- FCM token management (web + mobile)
- Edge function delivery system

---

## SUMMARY STATISTICS

- **Total Notification Types:** 12
- **Active Notifications:** 10
- **Scheduled Notifications:** 2 (deadline warnings)
- **Manual Notifications:** 2 (payment reminder, system alert)
- **Driver-Facing Notifications:** 4
- **Management-Facing Notifications:** 6
- **Edge Functions:** 2
- **Database Functions:** 1

---

## NEXT STEPS

1. ✅ Complete audit (this document)
2. ⏭️ Review notification triggers in job status update flows
3. ⏭️ Implement payment reminder scheduling (if needed)
4. ⏭️ Consider branch-based filtering for notifications
5. ⏭️ Add notification preferences/per-user settings
6. ⏭️ Monitor notification delivery success rates

---

**Last Updated:** 2025-01-11  
**Audited By:** AI Assistant  
**Version:** 1.0



