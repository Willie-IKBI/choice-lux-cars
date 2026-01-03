# Jobs RLS Security Fix - Trace and Implementation

## 1. TRACE: All Job Fetching Locations

### Primary Entry Point (Driver Login Flow)
**File:** `lib/features/jobs/jobs_screen.dart`
- **Method:** `build()` → `ref.watch(jobsProvider)`
- **Query:** Indirect via Riverpod provider
- **Caller Screen:** JobsScreen (main jobs list view)
- **Flow:** Screen loads → Provider auto-fetches on build

**File:** `lib/features/jobs/providers/jobs_provider.dart`
- **Method:** `build()` → `_fetchJobs()`
- **Query:** Calls `_jobsRepository.fetchJobs(userId, userRole, branchId)`
- **Caller:** JobsNotifier (Riverpod AsyncNotifier)

**File:** `lib/features/jobs/data/jobs_repository.dart`
- **Method:** `fetchJobs({userId, userRole, branchId})`
- **Query:** `_supabase.from('jobs').select()` with app-level filters
- **Driver Filter Logic (lines 53-78):** Complex OR condition including:
  - Started/in-progress jobs (driver OR manager)
  - Unconfirmed jobs
  - Confirmed jobs in date window
  - Jobs without start date
- **Issue:** App-level filtering exists BUT RLS allows all jobs, so if app logic fails, all jobs leak

### Secondary Entry Points

**File:** `lib/features/jobs/data/jobs_repository.dart`
- **Method:** `getJobsByStatus(status, {userId, userRole, branchId})`
- **Query:** `_supabase.from('jobs').select().eq('job_status', status)` + app filters
- **Caller:** `jobs_provider.dart:getJobsByStatus()`
- **Issue:** Same RLS leak

**File:** `lib/features/jobs/data/jobs_repository.dart`
- **Method:** `getJobsByDriver(driverId)`
- **Query:** `_supabase.from('jobs').select().eq('driver_id', driverId)`
- **Caller:** `jobs_provider.dart:getJobsByDriver()`
- **Issue:** No userId/role validation, relies on caller passing correct driverId

**File:** `lib/features/jobs/data/jobs_repository.dart`
- **Method:** `getJobsByClient(clientId, {userId, userRole, branchId})`
- **Query:** `_supabase.from('jobs').select().eq('client_id', clientId)` + app filters
- **Caller:** `jobs_provider.dart:getJobsByClient()`
- **Issue:** Same RLS leak

**File:** `lib/features/jobs/data/jobs_repository.dart`
- **Method:** `fetchJobById(jobId)`
- **Query:** `_supabase.from('jobs').select().eq('id', jobId).maybeSingle()`
- **Caller:** `jobs_provider.dart:fetchJobById()`
- **Issue:** No RLS filtering - any authenticated user can fetch any job by ID

**File:** `lib/core/services/supabase_service.dart`
- **Method:** `getJobsByClient(clientId, {branchId})`
- **Query:** `c.from('jobs').select().eq('client_id', clientId)` (no role filtering)
- **Caller:** Various legacy code paths
- **Issue:** No role/user filtering, relies entirely on RLS

**File:** `lib/features/jobs/data/jobs_repository.dart`
- **Method:** `fetchJobsWithInsightsFilters(...)`
- **Query:** `_supabase.from('jobs').select()` with complex filters
- **Caller:** Insights screens
- **Issue:** Manager filter exists but RLS allows all

### Realtime Subscriptions
**Status:** No realtime subscriptions found on `jobs` table
- Only subscriptions found are on `app_notifications` table

### RPC Functions / Views
**Status:** No RPC functions or views found that bypass RLS for jobs queries

---

## 2. VERIFY SECURITY MODEL

### Jobs Table Schema
**Columns:**
- `id` (bigint, PK)
- `driver_id` (uuid, nullable) - Foreign key to profiles.id
- `manager_id` (uuid, nullable) - Foreign key to profiles.id
- `created_by` (text, nullable) - User ID who created the job
- `job_status` (text, nullable)

### Current RLS Policies (VERIFIED)
```sql
-- Policy: jobs_select_policy
-- Command: SELECT
-- Roles: authenticated
-- USING: true  ← PERMISSIVE! Allows ALL authenticated users to see ALL jobs
```

**PROOF OF LEAK:**
1. RLS policy `jobs_select_policy` has `USING (true)` - this means ANY authenticated user can SELECT ANY job
2. App-level filtering in `jobs_repository.dart` exists but:
   - Relies on correct `userId` and `userRole` being passed
   - Can be bypassed if app logic has bugs
   - Can be bypassed by direct Supabase client calls
3. **Root Cause:** Missing RLS enforcement at database level

**Conclusion:** 
- **Type A) Missing/Incorrect RLS** - The RLS policy is permissive (`USING true`)
- App-level filtering exists but is not sufficient for security
- Need to implement proper RLS policies that enforce driver-only access at DB level

---

## 3. FIX: Smallest Correct Change

### Primary Fix: RLS Migration

**File:** `supabase/migrations/202501XX000013_jobs_rls_policies.sql`

**Strategy:**
1. Drop existing permissive policy
2. Create role-based SELECT policy:
   - Drivers: Only jobs where `driver_id = auth.uid()`
   - Managers: Jobs where `manager_id = auth.uid()`
   - Admins: All jobs
3. Keep INSERT/UPDATE/DELETE policies as-is (or tighten if needed)

**Assumptions:**
- `profiles.id == auth.uid()` (same UUID)
- `profiles.role` contains user role ('driver', 'manager', 'administrator', 'super_admin')
- `jobs.driver_id` references `profiles.id` (UUID)
- `jobs.manager_id` references `profiles.id` (UUID)

### Secondary Fix: Defense-in-Depth

**File:** `lib/features/jobs/data/jobs_repository.dart`

**Changes:**
1. Ensure `fetchJobById()` validates user can access the job (or rely on RLS)
2. Verify `getJobsByDriver()` validates caller is the driver (or rely on RLS)
3. Keep existing app-level filters as defense-in-depth

---

## 4. TEST PLAN

### Test 1: Driver A Cannot See Driver B Jobs
**Steps:**
1. Login as Driver A (driver_id = UUID-A)
2. Create a job assigned to Driver B (driver_id = UUID-B)
3. Login as Driver A
4. Navigate to JobsScreen
5. **Expected:** Job assigned to Driver B should NOT appear in list
6. **Verify:** Check logs for query results, verify RLS blocks the row

### Test 2: Driver Can See Own Jobs
**Steps:**
1. Login as Driver A
2. Create a job assigned to Driver A
3. Navigate to JobsScreen
4. **Expected:** Job assigned to Driver A SHOULD appear
5. **Verify:** Job visible in list, can open job details

### Test 3: Manager Can See Managed Jobs
**Steps:**
1. Login as Manager (manager_id = UUID-M)
2. Create a job with manager_id = UUID-M
3. Navigate to JobsScreen
4. **Expected:** Job with manager_id = UUID-M SHOULD appear
5. **Verify:** Job visible in list

### Test 4: Manager Cannot See Other Manager Jobs
**Steps:**
1. Login as Manager A (manager_id = UUID-MA)
2. Create a job with manager_id = UUID-MB (different manager)
3. Login as Manager A
4. Navigate to JobsScreen
5. **Expected:** Job with manager_id = UUID-MB should NOT appear
6. **Verify:** Job not visible in list

### Test 5: Admin Can See All Jobs
**Steps:**
1. Login as Administrator
2. Navigate to JobsScreen
3. **Expected:** All jobs should appear (regardless of driver_id/manager_id)
4. **Verify:** Jobs from all drivers/managers visible

### Test 6: Direct Supabase Query Bypass (Security Test)
**Steps:**
1. Login as Driver A
2. Use Supabase client directly: `supabase.from('jobs').select()`
3. **Expected:** Only jobs where driver_id = Driver A UUID should return
4. **Verify:** RLS enforces at DB level, cannot bypass via direct query

---

## Implementation Files

1. **Migration:** `supabase/migrations/202501XX000013_jobs_rls_policies.sql`
2. **No app code changes needed** (app-level filtering already exists as defense-in-depth)

