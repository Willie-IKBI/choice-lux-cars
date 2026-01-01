# Fix Plan: Started Jobs Disappearing from In-Progress Screen

## Problem Summary
When a driver or driver manager starts a job, it disappears from the "in progress" screen because the driver visibility query doesn't include started/in-progress jobs. The query only shows:
- Unconfirmed jobs
- Confirmed jobs within today/tomorrow window
- Jobs without start date

**Missing:** Jobs that are already started (`job_status = 'started'`, `'in_progress'`, or `'ready_to_close'`) should ALWAYS be visible to the driver, regardless of date/confirmation rules.

## Additional Requirement (MUST IMPLEMENT)
**"In Progress" visibility must include jobs linked to the current user either as:**
- The assigned driver (`driver_id == userId`), OR
- The assigned manager for the job (`manager_id == userId`)

**Confirmed Column Name:** `manager_id` (verified in schema and code)
- Database column: `manager_id` (uuid, foreign key to profiles.id)
- Job model field: `managerId` (maps to `manager_id`)
- No `driver_manager_id` column exists - only `manager_id`

**Implementation Rule:**
```
(driver_id == userId OR manager_id == userId) AND job_status IN ('started', 'in_progress', 'ready_to_close')
```

This must bypass date windows (today/tomorrow) for these statuses.

---

## IMPORTANT IMPLEMENTATION NOTES

### PostgREST Filter Syntax Fallback
**If the nested PostgREST filter string fails:**
```
and(or(driver_id.eq.$userId,manager_id.eq.$userId),job_status.in.(started,in_progress,ready_to_close))
```

**Then replace it with two OR-chain clauses (no nested or()):**
```
and(driver_id.eq.$userId,job_status.in.(started,in_progress,ready_to_close)),
and(manager_id.eq.$userId,job_status.in.(started,in_progress,ready_to_close))
```

**Rationale:** Some PostgREST versions or configurations may not support nested `or()` functions. The fallback approach uses two separate AND conditions in the OR chain, which achieves the same logical result: `(driver_id == userId OR manager_id == userId) AND job_status IN (...)`.

### Column Name Verification for `getJobsByStatus()`
**CRITICAL:** Ensure `getJobsByStatus()` filters on the correct status column:
- Database column: `job_status` (confirmed)
- Current code uses: `.eq('status', status)` (line 353) - **NEEDS VERIFICATION**
- **Action Required:** Verify if PostgREST endpoint/view maps `status` to `job_status`, or if the code should use `job_status` explicitly
- If the endpoint is a view that truly exposes `status`, then `.eq('status', status)` is correct
- If not, change to `.eq('job_status', status)` or use the correct column name

**Note:** The IN filter for started jobs must use `job_status` (not `status`) unless confirmed otherwise.

---

## Tasks

### Task 1: Fix Driver Visibility Query in `fetchJobs()` Method
**File:** `lib/features/jobs/data/jobs_repository.dart`  
**Location:** Lines 53-73  
**Current Issue:** Missing condition for started/in-progress jobs

**Action:**
- Add a new condition at the beginning of the OR chain to always show started/in-progress jobs
- Condition must include BOTH driver_id AND manager_id linkage
- Condition: `and(or(driver_id.eq.$userId,manager_id.eq.$userId),job_status.in.(started,in_progress,ready_to_close))`

**Code Change (Preferred - Nested OR):**
```dart
// Driver visibility: 
// 1. Started/in-progress jobs (ALWAYS visible once started) - for driver OR manager
// 2. Unconfirmed jobs
// 3. Confirmed jobs in window
// 4. Jobs without start date
query = query.or(
  'and(or(driver_id.eq.$userId,manager_id.eq.$userId),job_status.in.(started,in_progress,ready_to_close)),'  // NEW: Always show started jobs (driver OR manager)
  'and(driver_id.eq.$userId,driver_confirm_ind.eq.false),'
  'and(driver_id.eq.$userId,is_confirmed.eq.false),'
  'and(driver_id.eq.$userId,job_start_date.is.null),'
  'and(driver_id.eq.$userId,driver_confirm_ind.eq.true,job_start_date.gte.$todayISO,job_start_date.lte.$tomorrowISO),'
  'and(driver_id.eq.$userId,is_confirmed.eq.true,job_start_date.gte.$todayISO,job_start_date.lte.$tomorrowISO)'
);
```

**Code Change (Fallback - Two Separate Clauses):**
If nested OR fails, use this instead:
```dart
// Driver visibility: 
// 1. Started/in-progress jobs (ALWAYS visible once started) - for driver OR manager
// 2. Unconfirmed jobs
// 3. Confirmed jobs in window
// 4. Jobs without start date
query = query.or(
  'and(driver_id.eq.$userId,job_status.in.(started,in_progress,ready_to_close)),'  // NEW: Always show started jobs (driver)
  'and(manager_id.eq.$userId,job_status.in.(started,in_progress,ready_to_close)),'  // NEW: Always show started jobs (manager)
  'and(driver_id.eq.$userId,driver_confirm_ind.eq.false),'
  'and(driver_id.eq.$userId,is_confirmed.eq.false),'
  'and(driver_id.eq.$userId,job_start_date.is.null),'
  'and(driver_id.eq.$userId,driver_confirm_ind.eq.true,job_start_date.gte.$todayISO,job_start_date.lte.$tomorrowISO),'
  'and(driver_id.eq.$userId,is_confirmed.eq.true,job_start_date.gte.$todayISO,job_start_date.lte.$tomorrowISO)'
);
```

**Note:** 
- Preferred approach uses nested OR: `or(driver_id.eq.$userId,manager_id.eq.$userId)`
- Fallback approach uses two separate AND conditions in the OR chain
- Both achieve the same logical result: `(driver_id == userId OR manager_id == userId) AND job_status IN (...)`

**Validation:**
- Verify the OR condition syntax is correct for PostgREST
- Test nested OR approach first: `or(driver_id.eq.$userId,manager_id.eq.$userId)`
- If nested OR fails, use fallback: two separate AND conditions
- Ensure `job_status` is the correct column name (not `status`) for the IN filter
- Test that the query doesn't break existing functionality

---

### Task 2: Fix Driver Visibility Query in `getJobsByStatus()` Method
**File:** `lib/features/jobs/data/jobs_repository.dart`  
**Location:** Lines 368-388  
**Current Issue:** Same missing condition for started/in-progress jobs

**Action:**
- Apply the same fix as Task 1
- Add the started/in-progress condition at the beginning of the OR chain
- Include BOTH driver_id AND manager_id linkage

**Code Change (Preferred - Nested OR):**
```dart
// Driver visibility: 
// 1. Started/in-progress jobs (ALWAYS visible once started) - for driver OR manager
// 2. Unconfirmed jobs
// 3. Confirmed jobs in window
// 4. Jobs without start date
query = query.or(
  'and(or(driver_id.eq.$userId,manager_id.eq.$userId),job_status.in.(started,in_progress,ready_to_close)),'  // NEW: Always show started jobs (driver OR manager)
  'and(driver_id.eq.$userId,driver_confirm_ind.eq.false),'
  'and(driver_id.eq.$userId,is_confirmed.eq.false),'
  'and(driver_id.eq.$userId,job_start_date.is.null),'
  'and(driver_id.eq.$userId,driver_confirm_ind.eq.true,job_start_date.gte.$todayISO,job_start_date.lte.$tomorrowISO),'
  'and(driver_id.eq.$userId,is_confirmed.eq.true,job_start_date.gte.$todayISO,job_start_date.lte.$tomorrowISO)'
);
```

**Code Change (Fallback - Two Separate Clauses):**
If nested OR fails, use this instead:
```dart
// Driver visibility: 
// 1. Started/in-progress jobs (ALWAYS visible once started) - for driver OR manager
// 2. Unconfirmed jobs
// 3. Confirmed jobs in window
// 4. Jobs without start date
query = query.or(
  'and(driver_id.eq.$userId,job_status.in.(started,in_progress,ready_to_close)),'  // NEW: Always show started jobs (driver)
  'and(manager_id.eq.$userId,job_status.in.(started,in_progress,ready_to_close)),'  // NEW: Always show started jobs (manager)
  'and(driver_id.eq.$userId,driver_confirm_ind.eq.false),'
  'and(driver_id.eq.$userId,is_confirmed.eq.false),'
  'and(driver_id.eq.$userId,job_start_date.is.null),'
  'and(driver_id.eq.$userId,driver_confirm_ind.eq.true,job_start_date.gte.$todayISO,job_start_date.lte.$tomorrowISO),'
  'and(driver_id.eq.$userId,is_confirmed.eq.true,job_start_date.gte.$todayISO,job_start_date.lte.$tomorrowISO)'
);
```

**CRITICAL NOTE:** 
- This method already filters by status parameter (line 353): `.eq('status', status)`
- **VERIFY:** Check if this should be `.eq('job_status', status)` instead
- The endpoint may be a view that exposes `status`, but confirm this before changing
- The IN filter for started jobs must use `job_status` (not `status`) unless confirmed otherwise

**Validation:**
- **CRITICAL:** Verify the status column name - check if `.eq('status', status)` should be `.eq('job_status', status)`
- Verify the condition works correctly when combined with the existing status filter
- Test that filtering by specific status still works correctly
- If nested OR fails, test the fallback approach (two separate clauses)

---

### Task 3: Verify Column Name Consistency
**File:** `lib/features/jobs/data/jobs_repository.dart`  
**Issue:** Potential inconsistency between `status` and `job_status` column names

**Action:**
- Verify that `job_status` is the correct database column name
- Verify that `manager_id` is the correct manager linkage column (CONFIRMED: `manager_id`)
- Check if PostgREST requires `status` vs `job_status` in queries
- Ensure consistency across all queries

**Investigation Points:**
- Check `Job.fromMap()` - uses `map['job_status']` (line 170 in job.dart)
- Check `Job.toMap()` - uses `'job_status': status` (line 221 in job.dart)
- Check `Job.fromMap()` - uses `map['manager_id']` (line 149 in job.dart)
- Check `Job.toMap()` - uses `'manager_id': managerId` (line 210 in job.dart)
- Check `driver_flow_api_service.dart` - uses `'job_status': 'started'` (line 38)
- Check `getJobsByStatus()` - uses `.eq('status', status)` (line 353)
- Check `DATA_SCHEMA.md` - confirms `manager_id` column exists (line 455)

**Confirmed Column Names:**
- ✅ `job_status` - Database column for job status
- ✅ `manager_id` - Database column for manager assignment (uuid, FK to profiles.id)
- ❌ `driver_manager_id` - Does NOT exist (only `manager_id`)

**Decision:**
- If PostgREST maps `status` to `job_status`, use `status` in the IN filter
- If not, use `job_status` explicitly
- Always use `manager_id` (not `driver_manager_id`)
- Document the correct column names for future reference

---

### Task 4: Test the Fix
**Test Scenarios:**

1. **Driver starts a job:**
   - Create a job assigned to a driver
   - Driver starts the job (status becomes 'started')
   - Verify job appears in "in progress" screen
   - Verify job appears in "all" jobs screen

2. **Job started outside date window:**
   - Create a job with `job_start_date` = 3 days ago
   - Driver starts the job
   - Verify job still appears in "in progress" screen (even though it's outside the today/tomorrow window)

3. **Job in different statuses:**
   - Test with `job_status = 'started'`
   - Test with `job_status = 'in_progress'`
   - Test with `job_status = 'ready_to_close'`
   - All should be visible to the driver

4. **Manager visibility for started jobs:**
   - Create a job with `manager_id = userId` (user is manager, not driver)
   - Set job status to 'started'
   - Verify job appears in "in progress" screen for the manager
   - Verify job appears even if outside date window
   - Test with `job_status = 'in_progress'` and `'ready_to_close'`

5. **Driver OR Manager linkage:**
   - Test job where user is driver (driver_id = userId, manager_id != userId)
   - Test job where user is manager (manager_id = userId, driver_id != userId)
   - Test job where user is both (driver_id = userId AND manager_id = userId)
   - All scenarios should show job in "in progress" when status is started/in_progress/ready_to_close

6. **Regression tests:**
   - Unconfirmed jobs still visible
   - Confirmed jobs in date window still visible
   - Jobs without start date still visible
   - Completed/cancelled jobs not shown in "in progress"

7. **Driver Manager visibility:**
   - Verify driver managers can still see started jobs they created/manage
   - No regression in driver manager job visibility

---

### Task 5: Update Documentation
**File:** `ai/BATCH_G_MIGRATION_NOTES.md` or create new file

**Action:**
- Document the fix in the migration notes
- Update job visibility rules section
- Add note about started jobs always being visible

**Content:**
```markdown
## Job Visibility Fix - Started Jobs

**Date:** 2025-01-XX
**Issue:** Started jobs disappearing from in-progress screen
**Root Cause:** Driver visibility query didn't include started/in-progress jobs
**Fix:** Added condition to always show jobs with `job_status IN ('started', 'in_progress', 'ready_to_close')`

**Files Modified:**
- `lib/features/jobs/data/jobs_repository.dart` - `fetchJobs()` method
- `lib/features/jobs/data/jobs_repository.dart` - `getJobsByStatus()` method

**Rule:** Once a job is started, it must ALWAYS be visible to:
- The assigned driver (`driver_id == userId`), OR
- The assigned manager (`manager_id == userId`)

This applies regardless of confirmation status or start date window.
```

---

### Task 6: Code Review Checklist
Before committing, verify:

- [ ] Both `fetchJobs()` and `getJobsByStatus()` methods updated
- [ ] OR condition syntax tested (nested OR preferred, fallback if needed)
- [ ] Column names (`job_status` and `manager_id`) are correct and consistent
- [ ] Manager linkage uses `manager_id` (not `driver_manager_id`)
- [ ] Nested OR condition `or(driver_id.eq.$userId,manager_id.eq.$userId)` tested, or fallback used
- [ ] `getJobsByStatus()` status column verified (`.eq('status', status)` vs `.eq('job_status', status)`)
- [ ] IN filter uses `job_status` (not `status`) unless confirmed otherwise
- [ ] No syntax errors or typos
- [ ] Logging statements are appropriate
- [ ] Code follows existing patterns
- [ ] No breaking changes to other role visibility rules

---

### Task 7: Commit and Test
**Commit Message:**
```
fix: Always show started/in-progress jobs to drivers

Fixed issue where started jobs disappeared from in-progress screen.
Added condition to driver visibility query to always show jobs with
job_status IN ('started', 'in_progress', 'ready_to_close'), regardless
of confirmation status or start date window.

Fixes: Started jobs disappearing after driver starts job
```

**Post-Commit:**
- Test on development environment
- Verify fix works for both drivers and driver managers
- Monitor for any query performance issues
- Check logs for any PostgREST query errors

---

## Implementation Order

1. **Task 3** (Verify column name) - Do this first to avoid incorrect syntax
2. **Task 1** (Fix `fetchJobs()`) - Primary fix
3. **Task 2** (Fix `getJobsByStatus()`) - Secondary fix
4. **Task 4** (Test) - Verify fix works
5. **Task 5** (Documentation) - Document the change
6. **Task 6** (Code Review) - Final check
7. **Task 7** (Commit) - Deploy fix

---

## Risk Assessment

**Low Risk:**
- Adding a condition to an OR chain (additive change)
- Only affects driver role visibility
- Doesn't change existing visibility rules, just adds new ones

**Potential Issues:**
- PostgREST query syntax might need adjustment (nested OR may not be supported)
- Column name inconsistency might cause issues (`status` vs `job_status`)
- Need to verify IN filter syntax works correctly
- `getJobsByStatus()` may need column name correction

**Mitigation:**
- Test nested OR approach first, fallback to two separate clauses if needed
- Test thoroughly before committing
- Check PostgREST documentation for correct IN filter syntax
- Verify column names before implementing (especially `getJobsByStatus()`)
- Test with real data if possible
- Have fallback approach ready if nested OR fails

---

## Success Criteria

✅ Started jobs appear in "in progress" screen immediately after starting  
✅ Started jobs remain visible even if outside date window  
✅ All started/in-progress/ready_to_close jobs are visible to drivers  
✅ All started/in-progress/ready_to_close jobs are visible to managers (via manager_id)  
✅ Jobs visible when user is driver OR manager (OR linkage works correctly)  
✅ No regression in existing job visibility rules  
✅ Driver managers can still see their started jobs  
✅ No performance degradation in job queries

---

## Technical Details

### Current Driver Visibility Logic
The current query filters jobs based on:
1. Unconfirmed jobs: `driver_confirm_ind = false` OR `is_confirmed = false`
2. Confirmed jobs in window: `driver_confirm_ind = true` AND `job_start_date` BETWEEN today AND tomorrow
3. Jobs without start date: `job_start_date IS NULL`

### Missing Logic
Once a job is started (`job_status IN ('started', 'in_progress', 'ready_to_close')`), it should ALWAYS be visible to:
- The assigned driver (`driver_id == userId`), OR
- The assigned manager (`manager_id == userId`)

This applies regardless of:
- Confirmation status
- Start date window
- Any other visibility rules

### Database Schema
- Column name: `job_status` (confirmed in `Job.fromMap()` and `Job.toMap()`)
- Possible values: `'open'`, `'assigned'`, `'started'`, `'in_progress'`, `'ready_to_close'`, `'completed'`, `'cancelled'`
- PostgREST query builder may use `status` as alias, but database column is `job_status`
- Manager column: `manager_id` (uuid, foreign key to profiles.id)
- Confirmed: No `driver_manager_id` column exists - only `manager_id`

### PostgREST Query Syntax
The IN filter syntax for PostgREST:
```
job_status.in.(started,in_progress,ready_to_close)
```

The nested OR syntax for driver_id OR manager_id:
```
or(driver_id.eq.$userId,manager_id.eq.$userId)
```

Combined condition (Preferred - Nested OR):
```
and(or(driver_id.eq.$userId,manager_id.eq.$userId),job_status.in.(started,in_progress,ready_to_close))
```

Fallback (Two Separate Clauses):
```
and(driver_id.eq.$userId,job_status.in.(started,in_progress,ready_to_close)),
and(manager_id.eq.$userId,job_status.in.(started,in_progress,ready_to_close))
```

**Note:** If nested OR is not supported by your PostgREST version, use the fallback approach. Both achieve the same logical result: `(driver_id == userId OR manager_id == userId) AND job_status IN (...)`.

**Column Name Note for `getJobsByStatus()`:**
- Current code uses: `.eq('status', status)` (line 353)
- Database column is: `job_status`
- **Action:** Verify if endpoint/view maps `status` to `job_status`, or change to `.eq('job_status', status)`
- The IN filter must use `job_status` (not `status`) unless confirmed otherwise

---

## Related Files

- `lib/features/jobs/data/jobs_repository.dart` - Main file to modify
- `lib/features/jobs/models/job.dart` - Job model (reference for column names)
- `lib/features/jobs/services/driver_flow_api_service.dart` - Job start logic (reference)
- `lib/features/jobs/jobs_screen.dart` - UI screen that displays jobs
- `ai/BATCH_D_JOB_VISIBILITY_POINTS.md` - Job visibility documentation
- `ai/ROLES_PERMISSIONS_SPEC.md` - Role-based access control specification

---

## Notes

- This fix is additive - it only adds visibility rules, doesn't remove any
- The fix applies to both `fetchJobs()` and `getJobsByStatus()` methods
- The fix includes BOTH driver and manager visibility for started jobs
- Manager linkage uses `manager_id` column (confirmed in schema)
- Driver managers are not affected by this change (they use different visibility rules)
- The fix ensures started jobs are always visible to both drivers and managers, which aligns with business logic: once a job is started, the assigned driver or manager needs to track it
- The OR linkage `(driver_id == userId OR manager_id == userId)` ensures jobs are visible to the appropriate user regardless of their role in the job

