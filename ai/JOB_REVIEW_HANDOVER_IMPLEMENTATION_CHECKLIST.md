# Job Review Handover Implementation Checklist

**Date:** 2025-01-XX  
**Status:** IMPLEMENTATION CHECKLIST (No Code Yet)  
**Scope:** Driver Submit → Manager Review → Approve/Decline flow

---

## 1. Status Model: Exact Statuses and Transitions

### Current Status Enum (lib/features/jobs/models/job.dart)

**Existing Statuses:**
```dart
enum JobStatus {
  open,
  assigned,
  started,
  inProgress,
  readyToClose,
  completed,
  cancelled,
}
```

**Required Additions:**
- `review` - Job submitted by driver, awaiting manager review
- `declined` - Job declined by manager (audit/history only, no rework)

**New Status Enum:**
```dart
enum JobStatus {
  open,
  assigned,
  started,
  inProgress,
  readyToClose,
  review,        // NEW: Driver submitted, awaiting manager review
  completed,
  declined,      // NEW: Manager declined (final, no rework)
  cancelled,
}
```

**Status Transitions:**
```
started/in_progress → (all trips complete + vehicle returned) → review → (manager action) → completed OR declined
```

**Database:**
- `jobs.job_status` is TEXT field (not enum type)
- No migration needed for column type
- Need to add 'review' and 'declined' to validation/constants

**Files to Update:**
- `lib/features/jobs/models/job.dart` - Add `review` and `declined` to enum
- `lib/core/constants.dart` - Add `review` and `declined` to `JobStatusConstants` and `JobStatusLabels`
- `lib/features/jobs/models/job.dart` - Update `fromString()` and `value` getter

---

## 2. Driver UI: Where "Submit Job" Appears and Exact Conditions

### Location: JobProgressScreen

**File:** `lib/features/jobs/screens/job_progress_screen.dart`

**Current Flow:**
- After vehicle return (`_returnVehicle()`), shows `JobCompletionDialog` and navigates to `/jobs`
- `_checkAndUpdateJobStatus()` checks if all steps completed → calls `updateJobStatusToCompleted()`

**Required Changes:**

**A) Add "Submit Job" Button:**
- **Location:** After vehicle return step is completed
- **Condition:** Show button when:
  - All trips completed: `validate_all_trips_completed(job_id) = true` OR `transport_completed_ind = true`
  - Vehicle returned: `driver_flow.job_closed_time IS NOT NULL`
  - Odometer captured: `driver_flow.job_closed_odo IS NOT NULL`
  - Current job status: `job_status IN ('started', 'in_progress')` (not already 'review' or 'completed')
  - User is assigned driver: `job.driver_id == current_user.id`

**B) Button Placement:**
- Replace or add after `vehicle_return` step action button
- Or show in a completion summary section after vehicle return modal closes
- Button label: "Submit Job for Review"
- Button style: Primary action (gold gradient)

**C) Button Action:**
- Call `DriverFlowApiService.submitJobForReview(jobId)`
- Show loading state
- On success: Show snackbar "Job submitted for review"
- Refresh job progress
- Update UI to show job as "Completed" (even though DB status is 'review')

**Files to Modify:**
- `lib/features/jobs/screens/job_progress_screen.dart`:
  - Add `_submitJobForReview()` method
  - Add "Submit Job" button in step actions (after vehicle return)
  - Update `_checkAndUpdateJobStatus()` to NOT auto-set to 'completed' (remove or conditionally call)

---

## 3. Driver Submit: Exact DB Update(s) Required

### Service Method: submitJobForReview

**File:** `lib/features/jobs/services/driver_flow_api_service.dart`

**Method Signature:**
```dart
static Future<void> submitJobForReview(int jobId) async
```

**DB Updates Required:**

**A) Update jobs table:**
```sql
UPDATE jobs
SET 
  job_status = 'review',
  updated_at = NOW()
WHERE id = job_id;
```

**B) Update driver_flow table (if driver_completed_at field exists):**
```sql
UPDATE driver_flow
SET 
  driver_completed_at = NOW(),  -- NEW FIELD: timestamp when driver submitted
  updated_at = NOW()
WHERE job_id = job_id;
```

**C) If driver_completed_at doesn't exist, use existing field:**
- Option 1: Add `driver_completed_at` column to `driver_flow` table
- Option 2: Use `job_closed_time` as proxy (already set during vehicle return)
- Option 3: Add `driver_submitted_at` to `jobs` table

**Validation Before Submit:**
- All trips completed: Call `validate_all_trips_completed(job_id)` → must return `true`
- Vehicle returned: `driver_flow.job_closed_time IS NOT NULL`
- Odometer captured: `driver_flow.job_closed_odo IS NOT NULL`
- Job not already submitted: `jobs.job_status != 'review'`

**Error Handling:**
- If validation fails: Throw exception with clear message
- If job already in 'review': Show "Job already submitted"
- If trips incomplete: Show "All trips must be completed before submitting"

**Files to Modify:**
- `lib/features/jobs/services/driver_flow_api_service.dart`:
  - Add `submitJobForReview(int jobId)` method
  - Add validation checks
  - Update `jobs.job_status = 'review'`

**Database Migration (if needed):**
- `supabase/migrations/202501XX000016_add_driver_completed_at.sql` (if adding new field)

---

## 4. Driver Job List Mapping: How 'review' Appears as Completed to Driver

### Current Filter Logic

**File:** `lib/features/jobs/jobs_screen.dart`

**Current `_filterJobs()` method (lines 872-899):**
```dart
case 'completed':
  return jobs.where((job) =>
    job.status == 'completed' ||
    job.status == 'closed' ||
    job.status == 'cancelled')
    .toList();
```

**Required Changes:**

**A) Update Completed Filter:**
- Include 'review' status in 'completed' filter for drivers
- Drivers should see 'review' jobs as "Completed" in their list

**B) Status Display Mapping:**
- In `JobCard` or status display widgets, map 'review' → "COMPLETED" label for drivers
- Use `JobStatusX.fromString()` but override label for drivers when status is 'review'

**C) Driver-Specific Status Mapping:**
- Create helper: `getDriverVisibleStatus(JobStatus status, bool isDriver)`
- If `isDriver && status == JobStatus.review` → return "COMPLETED"
- Otherwise return normal label

**Files to Modify:**
- `lib/features/jobs/jobs_screen.dart`:
  - Update `_filterJobs()` 'completed' case to include 'review'
- `lib/features/jobs/models/job.dart`:
  - Add helper method `getDriverVisibleStatus()` or extend `JobStatusX`
- `lib/features/jobs/widgets/job_card.dart`:
  - Use driver-specific status mapping when displaying status

**Alternative Approach:**
- Keep filter logic as-is
- In UI rendering, check: `if (job.status == 'review' && isDriver) { display 'COMPLETED' }`
- This avoids changing filter logic but requires UI-level mapping

---

## 5. Manager UI: Where Review Queue Exists and Actions Appear

### Current Manager View

**File:** `lib/features/jobs/screens/job_summary_screen.dart`

**Current Action Buttons (lines 2091-2247):**
- "Back to Jobs"
- "Confirm Job" (driver only)
- "Edit Job" (manager/admin)
- "View All Trips" (manager/admin)
- "Add Another Trip" (manager/admin)
- "Cancel Job" (admin only)

**Required Changes:**

**A) Add Review Queue Filter:**
- In `JobsScreen`, add filter button: "Review" or "Pending Review"
- Filter: `job_status == 'review'`
- Show count badge: Number of jobs awaiting review

**B) Add Approve/Decline Actions in JobSummaryScreen:**
- **Location:** `_buildActionButtons()` method
- **Condition:** Show when:
  - `job_status == 'review'`
  - User role: `manager` OR `administrator` OR `super_admin`
  - Job is assigned to manager: `job.manager_id == current_user.id` OR user is admin

**C) Action Buttons:**
- **Approve & Close:** Primary button (green/gold)
  - Label: "Approve & Close Job"
  - Icon: `Icons.check_circle`
  - Calls: `approveJob(jobId)`
- **Decline:** Secondary button (red/orange)
  - Label: "Decline Job"
  - Icon: `Icons.cancel`
  - Calls: `showDeclineDialog(jobId)` → requires reason input

**D) Review Queue Screen (Optional):**
- Create dedicated screen: `JobReviewScreen` or add to `JobsScreen`
- List all jobs with `job_status == 'review'`
- Show: Job number, driver, passenger, submitted date
- Quick actions: Approve/Decline from list view

**Files to Modify:**
- `lib/features/jobs/screens/job_summary_screen.dart`:
  - Add `_buildReviewActions()` method
  - Add Approve/Decline buttons in `_buildActionButtons()` when `job.status == 'review'`
  - Add `_showDeclineDialog()` method
- `lib/features/jobs/jobs_screen.dart`:
  - Add "Review" filter button
  - Update `_filterJobs()` to handle 'review' status
- `lib/features/jobs/screens/job_review_screen.dart` (NEW - optional):
  - Create dedicated review queue screen

---

## 6. Manager Approve: DB Updates, Timestamps, Actor Fields

### Service Method: approveJob

**File:** `lib/features/jobs/services/driver_flow_api_service.dart` OR new `job_review_service.dart`

**Method Signature:**
```dart
static Future<void> approveJob(int jobId, String managerId) async
```

**DB Updates Required:**

**A) Update jobs table:**
```sql
UPDATE jobs
SET 
  job_status = 'completed',
  approved_by = manager_id,           -- NEW FIELD: UUID of manager who approved
  approved_at = NOW(),                 -- NEW FIELD: Timestamp of approval
  updated_at = NOW()
WHERE id = job_id;
```

**B) If approved_by/approved_at don't exist:**
- Add columns to `jobs` table:
  - `approved_by uuid REFERENCES profiles(id)`
  - `approved_at timestamptz`
- Or use existing `manager_id` + add `approved_at` only

**C) Validation:**
- Job must be in 'review' status: `job_status == 'review'`
- User must be manager/admin: Check role
- Job must be assigned to manager (if not admin): `manager_id == current_user.id` OR user is admin

**Error Handling:**
- If job not in 'review': Throw "Job is not pending review"
- If not authorized: Throw "You do not have permission to approve this job"
- If already approved: Throw "Job has already been approved" (defensive check)

**Files to Modify:**
- `lib/features/jobs/services/driver_flow_api_service.dart`:
  - Add `approveJob(int jobId, String managerId)` method
- `lib/features/jobs/providers/jobs_provider.dart`:
  - Add `approveJob(String jobId)` method to provider
- `lib/features/jobs/screens/job_summary_screen.dart`:
  - Wire Approve button to provider method

**Database Migration:**
- `supabase/migrations/202501XX000017_add_job_approval_fields.sql`:
  - Add `approved_by uuid` column
  - Add `approved_at timestamptz` column
  - Add FK: `approved_by → profiles.id`
  - Add index: `idx_jobs_approved_by` on `(approved_by, approved_at)`

---

## 7. Manager Decline: Required Reason, DB Updates, Actor Fields

### Service Method: declineJob

**File:** `lib/features/jobs/services/driver_flow_api_service.dart` OR new `job_review_service.dart`

**Method Signature:**
```dart
static Future<void> declineJob(int jobId, String managerId, String reason) async
```

**DB Updates Required:**

**A) Update jobs table:**
```sql
UPDATE jobs
SET 
  job_status = 'declined',
  declined_by = manager_id,           -- NEW FIELD: UUID of manager who declined
  declined_at = NOW(),                 -- NEW FIELD: Timestamp of decline
  decline_reason = reason,              -- NEW FIELD: Required text reason (or reuse cancel_reason)
  updated_at = NOW()
WHERE id = job_id;
```

**B) If declined_by/declined_at/decline_reason don't exist:**
- Add columns to `jobs` table:
  - `declined_by uuid REFERENCES profiles(id)`
  - `declined_at timestamptz`
  - `decline_reason text NOT NULL` (required, no NULL allowed)
- Or reuse `cancel_reason` field (but this may conflict with cancellation flow)

**C) Validation:**
- Job must be in 'review' status: `job_status == 'review'`
- Reason must be provided: `reason.trim().isNotEmpty` (min length: 10 chars recommended)
- User must be manager/admin: Check role
- Job must be assigned to manager (if not admin): `manager_id == current_user.id` OR user is admin

**D) Decline Dialog:**
- Show modal/dialog with:
  - Title: "Decline Job"
  - Text field: "Reason for decline" (required, multiline, min 10 chars)
  - Buttons: "Cancel" / "Decline Job" (red)
- Validate reason before submitting

**Error Handling:**
- If job not in 'review': Throw "Job is not pending review"
- If reason empty: Show validation error in dialog
- If not authorized: Throw "You do not have permission to decline this job"
- If already declined: Throw "Job has already been declined" (defensive check)

**Files to Modify:**
- `lib/features/jobs/services/driver_flow_api_service.dart`:
  - Add `declineJob(int jobId, String managerId, String reason)` method
- `lib/features/jobs/providers/jobs_provider.dart`:
  - Add `declineJob(String jobId, String reason)` method to provider
- `lib/features/jobs/screens/job_summary_screen.dart`:
  - Add `_showDeclineDialog()` method
  - Wire Decline button to dialog → provider method
- `lib/features/jobs/widgets/decline_job_dialog.dart` (NEW - optional):
  - Create reusable decline dialog widget

**Database Migration:**
- `supabase/migrations/202501XX000018_add_job_decline_fields.sql`:
  - Add `declined_by uuid` column
  - Add `declined_at timestamptz` column
  - Add `decline_reason text NOT NULL` column (or reuse `cancel_reason` if appropriate)
  - Add FK: `declined_by → profiles.id`
  - Add index: `idx_jobs_declined_by` on `(declined_by, declined_at)`

---

## 8. Odometer/KM: Prerequisites + What Must Be Complete

### Current Odometer Capture Flow

**Start Odometer:**
- Captured in `VehicleCollectionModal` (vehicle collection step)
- Stored in: `driver_flow.odo_start_reading` (numeric)
- Photo stored in: `driver_flow.pdp_start_image` (text URL)

**End Odometer:**
- Captured in `VehicleReturnModal` (vehicle return step)
- Stored in: `driver_flow.job_closed_odo` (numeric)
- Photo stored in: `driver_flow.job_closed_odo_img` (text URL)

### Prerequisites for Submit Job

**Required Before Driver Can Submit:**
1. **All trips completed:**
   - `validate_all_trips_completed(job_id) = true`
   - OR `driver_flow.transport_completed_ind = true`
   - All `trip_progress.status = 'completed'`

2. **Vehicle returned:**
   - `driver_flow.job_closed_time IS NOT NULL`
   - `driver_flow.current_step = 'vehicle_return'` OR `'completed'`

3. **End odometer captured:**
   - `driver_flow.job_closed_odo IS NOT NULL`
   - `driver_flow.job_closed_odo_img IS NOT NULL` (photo required)

4. **Start odometer captured (should already exist):**
   - `driver_flow.odo_start_reading IS NOT NULL`
   - `driver_flow.pdp_start_image IS NOT NULL` (photo required)

### Validation in submitJobForReview()

**Add validation checks:**
```dart
// 1. Check all trips completed
final allTripsCompleted = await validateAllTripsCompleted(jobId);
if (!allTripsCompleted) {
  throw Exception('All trips must be completed before submitting');
}

// 2. Check vehicle returned
final driverFlow = await getDriverFlowData(jobId);
if (driverFlow['job_closed_time'] == null) {
  throw Exception('Vehicle must be returned before submitting');
}

// 3. Check end odometer
if (driverFlow['job_closed_odo'] == null || driverFlow['job_closed_odo_img'] == null) {
  throw Exception('End odometer reading and photo must be captured');
}

// 4. Check start odometer (should exist, but validate)
if (driverFlow['odo_start_reading'] == null || driverFlow['pdp_start_image'] == null) {
  throw Exception('Start odometer reading and photo must be captured');
}
```

### Manager View: Odometer Display

**In JobSummaryScreen:**
- Already displays odometer readings (lines 1288-1321)
- Shows: Start KM, End KM, Total Distance
- **Missing:** Photo preview/links

**Required Addition:**
- Add "View Start Photo" / "View End Photo" buttons
- Generate signed URLs for photos (60 min expiry)
- Show image preview dialog (similar to expense slip preview)

**Files to Modify:**
- `lib/features/jobs/services/driver_flow_api_service.dart`:
  - Add validation in `submitJobForReview()`
- `lib/features/jobs/screens/job_summary_screen.dart`:
  - Add photo preview methods (similar to `_showSlipPreview` in expenses_card.dart)
  - Add "View Photo" buttons next to odometer readings

---

## 9. Database Schema Changes Summary

### New Columns Required

**jobs table:**
- `approved_by uuid REFERENCES profiles(id)` - Manager who approved
- `approved_at timestamptz` - Approval timestamp
- `declined_by uuid REFERENCES profiles(id)` - Manager who declined
- `declined_at timestamptz` - Decline timestamp
- `decline_reason text NOT NULL` - Required reason for decline (or reuse `cancel_reason`)

**driver_flow table (optional):**
- `driver_completed_at timestamptz` - When driver submitted (or reuse `job_closed_time`)

### Migrations Required

1. **Migration 16:** Add `driver_completed_at` to `driver_flow` (if needed)
2. **Migration 17:** Add `approved_by` and `approved_at` to `jobs`
3. **Migration 18:** Add `declined_by`, `declined_at`, and `decline_reason` to `jobs`

### Indexes Recommended

- `idx_jobs_approved_by` on `jobs(approved_by, approved_at)` WHERE `approved_by IS NOT NULL`
- `idx_jobs_declined_by` on `jobs(declined_by, declined_at)` WHERE `declined_by IS NOT NULL`
- `idx_jobs_review_status` on `jobs(job_status)` WHERE `job_status = 'review'` (for review queue queries)

---

## 10. Implementation Order (Phased)

### Phase 1: Database Schema + Status Enum
1. Create migrations for new columns (approved_by, declined_by, etc.)
2. Update JobStatus enum to include 'review' and 'declined'
3. Update constants and labels
4. Test enum parsing/display

### Phase 2: Driver Submit Flow
1. Add `submitJobForReview()` service method
2. Add validation checks (trips, odometer, vehicle return)
3. Add "Submit Job" button in JobProgressScreen
4. Update driver job list to show 'review' as "Completed"
5. Test driver submit flow end-to-end

### Phase 3: Manager Review UI
1. Add "Review" filter in JobsScreen
2. Add Approve/Decline buttons in JobSummaryScreen
3. Add decline dialog with reason input
4. Test manager review actions

### Phase 4: Manager Approve/Decline Logic
1. Add `approveJob()` service method
2. Add `declineJob()` service method
3. Wire buttons to service methods
4. Test approve/decline flow

### Phase 5: Odometer Photo Display
1. Add signed URL generation for odometer photos
2. Add photo preview in JobSummaryScreen
3. Test photo display for managers

### Phase 6: Testing + Polish
1. E2E test: Driver submit → Manager review → Approve
2. E2E test: Driver submit → Manager review → Decline
3. Test edge cases (already submitted, unauthorized, etc.)
4. Update any missing error messages
5. Verify declined jobs don't appear in driver active list

---

## 11. Test Checklist

### Driver Flow Tests

- [ ] Driver completes all trips → "Submit Job" button appears
- [ ] Driver returns vehicle → "Submit Job" button still visible
- [ ] Driver clicks "Submit Job" → Job status becomes 'review'
- [ ] Driver sees job as "Completed" in job list (even though DB is 'review')
- [ ] Driver cannot submit if trips incomplete → Error shown
- [ ] Driver cannot submit if odometer missing → Error shown
- [ ] Driver cannot submit twice → Error shown

### Manager Flow Tests

- [ ] Manager sees "Review" filter in JobsScreen
- [ ] Manager sees count of jobs awaiting review
- [ ] Manager opens 'review' job → Sees Approve/Decline buttons
- [ ] Manager clicks "Approve & Close" → Job status becomes 'completed'
- [ ] Manager clicks "Decline" → Dialog appears with reason field
- [ ] Manager submits decline with reason → Job status becomes 'declined'
- [ ] Manager cannot decline without reason → Validation error
- [ ] Manager cannot approve/decline non-review job → Error shown
- [ ] Manager can view odometer photos in review screen

### Edge Cases

- [ ] Driver submits → Manager approves → Job shows as completed
- [ ] Driver submits → Manager declines → Job shows as declined (driver sees as completed, manager sees declined)
- [ ] Multiple managers → Only assigned manager can approve/decline (unless admin)
- [ ] Admin can approve/decline any 'review' job
- [ ] Declined jobs don't appear in driver active list
- [ ] Declined jobs appear in manager's job history

---

## 12. Files to Create/Modify Summary

### New Files
- `supabase/migrations/202501XX000016_add_driver_completed_at.sql` (optional)
- `supabase/migrations/202501XX000017_add_job_approval_fields.sql`
- `supabase/migrations/202501XX000018_add_job_decline_fields.sql`
- `lib/features/jobs/widgets/decline_job_dialog.dart` (optional, can inline in screen)

### Modified Files
- `lib/features/jobs/models/job.dart` - Add 'review' and 'declined' to enum
- `lib/core/constants.dart` - Add status constants and labels
- `lib/features/jobs/services/driver_flow_api_service.dart` - Add submitJobForReview, approveJob, declineJob
- `lib/features/jobs/providers/jobs_provider.dart` - Add approveJob, declineJob methods
- `lib/features/jobs/screens/job_progress_screen.dart` - Add Submit Job button
- `lib/features/jobs/screens/job_summary_screen.dart` - Add Approve/Decline buttons, decline dialog
- `lib/features/jobs/jobs_screen.dart` - Add Review filter, update completed filter
- `lib/features/jobs/widgets/job_card.dart` - Update status display for drivers

---

**END OF CHECKLIST**

