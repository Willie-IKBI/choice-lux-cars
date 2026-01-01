# Driver Job Flow - Comprehensive Planning Document

**Generated:** 2025-01-XX  
**Audience:** CLC-ARCH, CLC-BUILD, CLC-REVIEW  
**Purpose:** Detailed plan for implementing complete driver job flow with multi-trip support and expense management

---

## Table of Contents

1. [Overview](#overview)
2. [Current State Analysis](#current-state-analysis)
3. [Requirements](#requirements)
4. [Database Schema Changes](#database-schema-changes)
5. [Implementation Plan](#implementation-plan)
6. [Task Breakdown](#task-breakdown)
7. [Testing Strategy](#testing-strategy)
8. [Risk Assessment](#risk-assessment)
9. [Success Criteria](#success-criteria)

---

## Overview

This document outlines the complete implementation plan for the driver job flow feature, including:

1. **Job Confirmation Flow**: Drivers must confirm jobs before starting
2. **Multi-Trip Management**: Jobs can have 1 to many trips, all must be completed before closing
3. **Trip Progression**: Sequential trip handling with proper state management
4. **Expense Tracking**: Full expense CRUD with types (fuel, parking, toll, other)
5. **Expense Approval**: Manager approval workflow for expenses after job completion
6. **Job Summary Updates**: Display all trips and expenses in job review

---

## Current State Analysis

### Existing Components

#### Database Tables
- ✅ `jobs` - Has confirmation fields (`driver_confirm_ind`, `is_confirmed`, `confirmed_at`)
- ✅ `transport` - Stores trips for jobs (1 to many relationship via `job_id`)
- ✅ `trip_progress` - Tracks individual trip status with `trip_index` (unique per job)
- ✅ `driver_flow` - Tracks overall job progress with `current_trip_index`
- ✅ `expenses` - Exists but needs enhancement for expense types and approval

#### Code Components
- ✅ `JobsRepository` - Job CRUD operations (`lib/features/jobs/data/jobs_repository.dart`)
- ✅ `TripsRepository` - Trip CRUD operations (`lib/features/jobs/data/trips_repository.dart`)
- ✅ `DriverFlowApiService` - Job flow state management (`lib/features/jobs/services/driver_flow_api_service.dart`)
- ✅ `JobsProvider` - State management for jobs (`lib/features/jobs/providers/jobs_provider.dart`)
- ✅ `confirmJob()` method exists in `JobsProvider` (line 326)

#### Current Issues
1. ❌ Job confirmation not enforced before starting job
2. ❌ No validation that all trips are completed before closing job
3. ❌ Trip progression doesn't automatically show next trip after completion
4. ❌ Expenses table lacks expense type field (`fuel`, `parking`, `toll`, `other`)
5. ❌ No expense approval workflow (missing `approved_by`, `approved_at` fields)
6. ❌ Job summary doesn't show all trips properly when reviewed
7. ❌ No driver name tracking in expenses (only `user` text field, should be UUID to profiles)

---

## Requirements

### 1. Job Confirmation Flow

**Requirement:** A driver gets a job allocated to them and must confirm the job. Once confirmed, the job stays with that driver unless it is reassigned to another driver.

**Business Rules:**
- Driver receives job allocation notification (already implemented)
- Driver must explicitly confirm the job using existing `confirmJob()` method
- Confirmation sets `driver_confirm_ind = true` and `confirmed_at = timestamp`
- Only confirmed jobs can be started (validation needed)
- Confirmed jobs remain with the driver unless manager reassigns
- If job is reassigned, new driver must confirm again (confirmation reset)

**UI Requirements:**
- Show "Confirm Job" button for unconfirmed jobs assigned to current driver
- Disable "Start Job" button until job is confirmed
- Show confirmation status badge in job list cards
- Show confirmation timestamp in job details
- Clear visual indication of confirmation status

**Implementation Points:**
- `lib/features/jobs/services/driver_flow_api_service.dart` - `startJob()` method (line 10)
- `lib/features/jobs/screens/job_progress_screen.dart` - Start job button
- `lib/features/jobs/widgets/job_list_card.dart` - Confirmation status display

### 2. Multi-Trip Management

**Requirement:** The job can have from one to many trips. The driver will start the job, then complete each trip sequentially. Once all trips are completed, only then can the driver close the job.

**Business Rules:**
- Jobs are created with trips in `transport` table (already supported)
- Each trip has a `trip_index` in `trip_progress` table (1, 2, 3, ...)
- Driver must complete trips sequentially (trip 1, then 2, then 3, etc.)
- After completing a trip, next trip automatically shows if it exists
- Job can only be closed when all trips have status = 'completed'
- Job summary must show all trips when the job is reviewed

**Trip States (from `trip_progress.status`):**
- `pending` - Trip not started
- `pickup_arrived` - Driver arrived at pickup location
- `passenger_onboard` - Passenger picked up
- `dropoff_arrived` - Driver arrived at dropoff location
- `completed` - Trip completed

**Flow Sequence:**
1. Driver confirms job
2. Driver starts job → Collect Vehicle → Trip 1 begins
3. Driver completes Trip 1 → If more trips exist, automatically show Trip 2
4. Driver completes Trip 2 → If more trips exist, automatically show Trip 3
5. ... Continue until all trips completed
6. All trips completed → Enable "Close Job" button
7. Driver closes job → Job status = 'completed'

**Implementation Points:**
- `lib/features/jobs/services/driver_flow_api_service.dart` - `completeTrip()` method (line 346)
- `lib/features/jobs/data/trips_repository.dart` - Trip queries
- `lib/features/jobs/screens/job_progress_screen.dart` - Trip progression UI
- Database function: `complete_trip()` in migrations

### 3. Trip Progression

**Requirement:** After completing a trip, the next trip must automatically show if it exists. The same process (collect vehicle, arrive at destination, get passenger, drop passenger off, complete trip) is followed for each trip.

**Business Rules:**
- `driver_flow.current_trip_index` tracks current active trip (already exists)
- When trip is completed, increment `current_trip_index` to next trip
- If `current_trip_index > total_trips`, all trips are done
- UI must show current trip information (e.g., "Trip 2 of 3")
- UI must show trip progress indicator
- Each trip follows same flow: pickup → passenger onboard → dropoff → complete

**Implementation Points:**
- `lib/features/jobs/services/driver_flow_api_service.dart` - Update `current_trip_index` on trip completion
- `lib/features/jobs/data/trips_repository.dart` - Query total trips and current trip
- `lib/features/jobs/screens/job_progress_screen.dart` - Display current trip info
- `lib/features/jobs/widgets/trip_progress_widget.dart` - New widget for trip display

### 4. Expense Tracking

**Requirement:** Drivers can add expenses to trips/jobs. Expenses include: driver name, date and time, expense type (fuel, parking, toll, other), amount, and description (required for "other" type).

**Expense Types:**
- `fuel` - Fuel expenses
- `parking` - Parking fees
- `toll` - Toll fees
- `other` - Other expenses (requires description)

**Expense Fields Required:**
- Driver name (from `profiles.display_name` via `user` UUID)
- Date and time (timestamp from `exp_date`)
- Expense type (new field: `expense_type` enum)
- Amount (`exp_amount` - already exists)
- Description (`expense_description` - already exists, but required for "other" type)
- Other description (`other_description` - already exists, use for "other" type details)
- Receipt image (`slip_image` - already exists, optional)
- Location (`expense_location` - already exists, optional)
- Job ID (`job_id` - already exists, foreign key)

**Business Rules:**
- Expenses can be added during job execution (while job is active)
- Expenses can be added after job completion (before manager approval)
- "Other" type requires description in `other_description` field
- All expenses require manager approval after job completion
- Expenses are linked to job (not individual trips) - business decision

**Implementation Points:**
- `lib/features/expenses/models/expense.dart` - New model with expense type
- `lib/features/expenses/data/expenses_repository.dart` - New repository
- `lib/features/expenses/providers/expenses_provider.dart` - New provider
- `lib/features/expenses/widgets/expense_form.dart` - New form widget
- `lib/features/jobs/screens/job_progress_screen.dart` - Add expense button

### 5. Expense Approval Workflow

**Requirement:** Expenses must be approved by the manager after the job is completed. The manager needs to get a high-level overview of the job and expenses, then click confirm to approve all expenses for that job.

**Business Rules:**
- Expenses can only be approved after job status = 'completed'
- Manager sees high-level overview of job (summary with all trips)
- Manager sees list of all expenses for the job
- Manager clicks "Approve Expenses" to approve ALL expenses for the job (bulk approval)
- Approval sets `approved_by = manager_id` and `approved_at = timestamp` for all expenses
- Individual expense approval is not required (all-or-nothing per job)
- Once approved, expenses show approval status and timestamp

**Manager View Requirements:**
- Job summary header (job number, passenger, dates, etc.)
- List of all trips with completion status
- List of all expenses with details (type, amount, date, driver name)
- Total expense amount
- "Approve Expenses" button (only if job completed and expenses not yet approved)
- Approval status display (if approved, show manager name and timestamp)

**Implementation Points:**
- `lib/features/expenses/screens/expense_approval_screen.dart` - New screen
- `lib/features/expenses/services/expense_approval_service.dart` - New service
- `lib/features/jobs/screens/job_summary_screen.dart` - Add expense approval section
- Database function: `approve_job_expenses(job_id, manager_id)` - New function

### 6. Job Summary Updates

**Requirement:** The job details must update all required trips as per the job summary when the job is reviewed. Job summary must show all trips and expenses.

**Display Requirements:**
- List all trips with status indicators
- Show trip details (pickup location, dropoff location, pickup time, dropoff time)
- Show trip completion status (completed/pending)
- List all expenses with full details
- Show expense type icons/badges
- Show expense amounts and total
- Show expense approval status
- Show manager approval info (name, date/time) if approved
- Show job completion status
- Show driver confirmation status

**Implementation Points:**
- `lib/features/jobs/screens/job_summary_screen.dart` - Update to show trips and expenses
- `lib/features/jobs/widgets/job_trips_summary.dart` - New widget for trips
- `lib/features/jobs/widgets/job_expenses_summary.dart` - New widget for expenses

---

## Database Schema Changes

### 1. Expenses Table Enhancement

**Current Schema (from DATA_SCHEMA.md):**
```sql
CREATE TABLE expenses (
    id bigint PRIMARY KEY,
    job_id bigint REFERENCES jobs(id),
    expense_description text,
    exp_amount numeric,
    exp_date timestamptz,
    slip_image text,
    expense_location text,
    user text,  -- Currently text, should be UUID
    other_description text,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);
```

**Required Changes:**

#### Migration 1: Add Expense Type and Approval Fields
**File:** `supabase/migrations/YYYYMMDDHHMMSS_expense_enhancements.sql`

```sql
-- Add expense_type column with CHECK constraint
ALTER TABLE expenses 
ADD COLUMN expense_type text CHECK (expense_type IN ('fuel', 'parking', 'toll', 'other'));

-- Add approval fields
ALTER TABLE expenses 
ADD COLUMN approved_by uuid REFERENCES auth.users(id),
ADD COLUMN approved_at timestamptz;

-- Change user column from text to UUID (if not already UUID)
-- First, check if conversion is needed (may need data migration)
-- If user column contains UUIDs as text, convert:
ALTER TABLE expenses 
ALTER COLUMN user TYPE uuid USING user::uuid;

-- Add foreign key for user to profiles table
ALTER TABLE expenses 
ADD CONSTRAINT expenses_user_fkey FOREIGN KEY (user) REFERENCES profiles(id);

-- Add index for job_id queries
CREATE INDEX IF NOT EXISTS idx_expenses_job_id ON expenses(job_id);

-- Add index for approval status queries
CREATE INDEX IF NOT EXISTS idx_expenses_approved ON expenses(approved_by, approved_at);

-- Add comment for expense_type
COMMENT ON COLUMN expenses.expense_type IS 'Type of expense: fuel, parking, toll, or other';
COMMENT ON COLUMN expenses.approved_by IS 'Manager who approved the expense (UUID from auth.users)';
COMMENT ON COLUMN expenses.approved_at IS 'Timestamp when expenses were approved';
```

**Data Migration Considerations:**
- If existing expenses exist, set default `expense_type = 'other'` for existing records
- If `user` column has non-UUID values, may need data cleanup first

#### Migration 2: Add Database Functions for Expense Approval
**File:** `supabase/migrations/YYYYMMDDHHMMSS_expense_approval_functions.sql`

```sql
-- Function to approve all expenses for a job
CREATE OR REPLACE FUNCTION approve_job_expenses(
    p_job_id bigint,
    p_manager_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verify job is completed
    IF NOT EXISTS (
        SELECT 1 FROM jobs 
        WHERE id = p_job_id 
        AND job_status = 'completed'
    ) THEN
        RAISE EXCEPTION 'Job must be completed before expenses can be approved';
    END IF;
    
    -- Update all expenses for this job
    UPDATE expenses
    SET 
        approved_by = p_manager_id,
        approved_at = NOW(),
        updated_at = NOW()
    WHERE job_id = p_job_id
    AND approved_by IS NULL;  -- Only approve unapproved expenses
    
    -- Log the action
    RAISE NOTICE 'Approved expenses for job % by manager %', p_job_id, p_manager_id;
END;
$$;

-- Function to get expense summary for a job
CREATE OR REPLACE FUNCTION get_job_expenses_summary(p_job_id bigint)
RETURNS TABLE(
    total_expenses numeric,
    approved_expenses numeric,
    pending_expenses numeric,
    expense_count bigint,
    is_approved boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(SUM(exp_amount), 0) as total_expenses,
        COALESCE(SUM(CASE WHEN approved_by IS NOT NULL THEN exp_amount ELSE 0 END), 0) as approved_expenses,
        COALESCE(SUM(CASE WHEN approved_by IS NULL THEN exp_amount ELSE 0 END), 0) as pending_expenses,
        COUNT(*)::bigint as expense_count,
        BOOL_AND(approved_by IS NOT NULL) as is_approved
    FROM expenses
    WHERE job_id = p_job_id;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION approve_job_expenses(bigint, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION get_job_expenses_summary(bigint) TO authenticated;
```

#### Migration 3: Update RLS Policies for Expenses
**File:** `supabase/migrations/YYYYMMDDHHMMSS_expense_rls_update.sql`

```sql
-- Current policy allows all authenticated users full access
-- We need to ensure managers can approve expenses

-- Policy for drivers to manage their own expenses
CREATE POLICY "Drivers can manage their own expenses"
ON expenses
FOR ALL
USING (
    -- Drivers can see/manage expenses for jobs they are assigned to
    EXISTS (
        SELECT 1 FROM jobs
        WHERE jobs.id = expenses.job_id
        AND jobs.driver_id = auth.uid()
    )
);

-- Policy for managers to approve expenses
CREATE POLICY "Managers can approve expenses"
ON expenses
FOR UPDATE
USING (
    -- Managers can update (approve) expenses for jobs they manage
    EXISTS (
        SELECT 1 FROM jobs
        WHERE jobs.id = expenses.job_id
        AND jobs.manager_id = auth.uid()
        AND jobs.job_status = 'completed'
    )
);

-- Keep existing policy for backward compatibility (may need to adjust)
-- Or replace with more specific policies above
```

### 2. Trip Completion Validation

**No schema changes needed** - `trip_progress` table already supports this:
- `trip_index` - Sequential trip number (unique with job_id)
- `status` - Trip status (pending, pickup_arrived, passenger_onboard, dropoff_arrived, completed)
- `job_id` - Links to job

**Required:** Add validation function to ensure all trips are completed before job closure.

#### Migration 4: Add Trip Validation Function
**File:** `supabase/migrations/YYYYMMDDHHMMSS_trip_validation_functions.sql`

```sql
-- Function to validate all trips are completed for a job
CREATE OR REPLACE FUNCTION validate_all_trips_completed(p_job_id bigint)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    total_trips integer;
    completed_trips integer;
BEGIN
    -- Get total trips for this job from transport table
    SELECT COUNT(*) INTO total_trips
    FROM transport
    WHERE job_id = p_job_id;
    
    -- If no trips, return true (job can be closed)
    IF total_trips = 0 THEN
        RETURN true;
    END IF;
    
    -- Get completed trips from trip_progress table
    SELECT COUNT(*) INTO completed_trips
    FROM trip_progress
    WHERE job_id = p_job_id
    AND status = 'completed';
    
    -- Return true if all trips are completed
    RETURN completed_trips = total_trips;
END;
$$;

-- Function to get trip completion status
CREATE OR REPLACE FUNCTION get_trip_completion_status(p_job_id bigint)
RETURNS TABLE(
    total_trips integer,
    completed_trips integer,
    current_trip_index integer,
    all_completed boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        (SELECT COUNT(*) FROM transport WHERE job_id = p_job_id)::integer as total_trips,
        (SELECT COUNT(*) FROM trip_progress WHERE job_id = p_job_id AND status = 'completed')::integer as completed_trips,
        (SELECT current_trip_index FROM driver_flow WHERE job_id = p_job_id)::integer as current_trip_index,
        validate_all_trips_completed(p_job_id) as all_completed;
END;
$$;

-- Grant permissions
GRANT EXECUTE ON FUNCTION validate_all_trips_completed(bigint) TO authenticated;
GRANT EXECUTE ON FUNCTION get_trip_completion_status(bigint) TO authenticated;
```

### 3. Driver Flow Enhancement

**Current Schema:** Already has `current_trip_index` in `driver_flow` table.

**Required:** Add validation to prevent job closure if trips incomplete. This will be done in application code, but database function above supports it.

### 4. Trip Progress Initialization

**Requirement:** Automatically initialize `trip_progress` rows when a job transitions to 'started' status. This ensures all trips are tracked from the moment a job begins.

#### Recommended Approach: DB-Triggered Initialization

**Decision:** Use a database trigger that fires when `jobs.job_status` transitions to 'started'. This approach:
- Ensures data consistency (no race conditions)
- Centralizes logic in the database
- Works regardless of how the status change occurs (API, direct SQL, etc.)
- Automatically handles edge cases

**Trigger Logic:**
1. Fire on `BEFORE UPDATE OF job_status` on `public.jobs`
2. Detect transition: `OLD.job_status <> 'started' AND NEW.job_status = 'started'`
3. For the job, query all rows from `public.transport` where `job_id = NEW.id`
4. For each transport row, create a corresponding `trip_progress` row if it doesn't exist
5. Set initial status to 'pending' for all trips
6. Set `trip_index` based on ordering rule (see below)

#### Trip Index Ordering Rule

**Source of Truth:** `public.transport` table rows for the job.

**Ordering Rule:**
- Order by `id` (primary key) ascending to ensure consistent, deterministic ordering
- Alternative: If `transport` has an explicit ordering column (e.g., `sequence_number`, `trip_order`), use that instead
- If no explicit ordering exists, use `id` as the stable ordering mechanism
- First transport row (lowest `id`) = `trip_index = 1`
- Second transport row (next `id`) = `trip_index = 2`
- Continue sequentially

**Implementation:**
```sql
-- Pseudocode for ordering logic
SELECT id, ... FROM public.transport 
WHERE job_id = p_job_id 
ORDER BY id ASC  -- or ORDER BY sequence_number ASC if exists
```

**Trip Index Assignment:**
- Use `ROW_NUMBER()` window function to assign sequential `trip_index` values
- Ensure `trip_index` is unique per job (enforced by existing unique constraint on `(job_id, trip_index)`)
- First trip gets `trip_index = 1`, second gets `trip_index = 2`, etc.

#### Handling Existing Jobs (Backfill)

**Scope:** Jobs with `job_status IN ('open', 'started')` that may not have `trip_progress` rows initialized.

**Backfill Strategy:**
1. Create a one-time migration function to backfill existing jobs
2. Query all jobs where `job_status IN ('open', 'started')`
3. For each job:
   - Query `public.transport` rows for the job
   - Check which trips already have `trip_progress` rows
   - Create missing `trip_progress` rows with:
     - `trip_index` based on transport ordering
     - `status = 'pending'` (or current status if trip already in progress)
     - `job_id` from the job
     - Required timestamps (see below)
4. Handle edge cases:
   - Jobs with no transport rows (no trips) → skip initialization
   - Jobs with partial trip_progress rows → only create missing ones
   - Jobs where trips are already completed → preserve existing status

**Backfill Migration:**
- Create as a separate migration file (e.g., `YYYYMMDDHHMMSS_backfill_trip_progress.sql`)
- Run after the trigger is created
- Use `DO $$ ... END $$;` block or a function
- Include logging/notices for monitoring
- Make idempotent (safe to run multiple times)

#### Minimal Trip Progress Status Lifecycle

**Status Values (from existing schema):**
- `pending` - Initial state when trip_progress row is created
- `pickup_arrived` - Driver arrived at pickup location
- `passenger_onboard` - Passenger picked up
- `dropoff_arrived` - Driver arrived at dropoff location
- `completed` - Trip completed

**Required Timestamps:**
- `created_at` - When trip_progress row is created (default: `now()`)
- `updated_at` - Last update timestamp (default: `now()`, updated on status changes)
- Optional status-specific timestamps (if schema supports):
  - `pickup_arrived_at` - When status changed to 'pickup_arrived'
  - `passenger_onboard_at` - When status changed to 'passenger_onboard'
  - `dropoff_arrived_at` - When status changed to 'dropoff_arrived'
  - `completed_at` - When status changed to 'completed'

**Initialization Values:**
- `status = 'pending'` - All trips start as pending
- `created_at = now()` - Set automatically
- `updated_at = now()` - Set automatically
- `trip_index` - Assigned based on transport ordering (1, 2, 3, ...)
- `job_id` - From the job being initialized

**Status Transition Rules:**
- `pending` → `pickup_arrived` → `passenger_onboard` → `dropoff_arrived` → `completed`
- Transitions are sequential (cannot skip steps)
- Once `completed`, status should not change (immutable)
- Application code enforces valid transitions

#### Acceptance Tests for Job Closure Trigger

**Test Suite:** Verify that `trg_job_closure_requires_trips_completed` (from Migration 6) behaves correctly with trip progress initialization.

**Test 1: Job with Zero Trips**
- **Setup:** Create job with no transport rows
- **Action:** Attempt to set `job_status = 'completed'`
- **Expected:** Job closure succeeds (no trips to complete)
- **Verification:** `validate_all_trips_completed()` returns `true` for jobs with zero trips

**Test 2: Job with Single Trip - All Completed**
- **Setup:** 
  - Create job with 1 transport row
  - Job status transitions to 'started' → trigger creates trip_progress row
  - Complete the trip (status = 'completed')
- **Action:** Attempt to set `job_status = 'completed'`
- **Expected:** Job closure succeeds
- **Verification:** All trips have status = 'completed'

**Test 3: Job with Multiple Trips - All Completed**
- **Setup:**
  - Create job with 3 transport rows
  - Job status transitions to 'started' → trigger creates 3 trip_progress rows
  - Complete all 3 trips sequentially
- **Action:** Attempt to set `job_status = 'completed'`
- **Expected:** Job closure succeeds
- **Verification:** All 3 trips have status = 'completed'

**Test 4: Job with Multiple Trips - Some Incomplete**
- **Setup:**
  - Create job with 3 transport rows
  - Job status transitions to 'started' → trigger creates 3 trip_progress rows
  - Complete trip 1 and trip 2, leave trip 3 as 'pending'
- **Action:** Attempt to set `job_status = 'completed'`
- **Expected:** Job closure fails with exception: "Cannot close job: not all trips are completed"
- **Verification:** 
  - Exception is raised
  - Job status remains unchanged
  - `validate_all_trips_completed()` returns `false`

**Test 5: Job with Multiple Trips - None Completed**
- **Setup:**
  - Create job with 2 transport rows
  - Job status transitions to 'started' → trigger creates 2 trip_progress rows
  - Both trips remain 'pending'
- **Action:** Attempt to set `job_status = 'completed'`
- **Expected:** Job closure fails with exception
- **Verification:** Exception raised, job status unchanged

**Test 6: Trip Progress Initialization on Status Change**
- **Setup:** Create job with 2 transport rows, job_status = 'open'
- **Action:** Update job_status from 'open' to 'started'
- **Expected:** 
  - Trigger fires and creates 2 trip_progress rows
  - Both rows have `trip_index = 1` and `trip_index = 2` respectively
  - Both rows have `status = 'pending'`
  - Both rows have `job_id` matching the job
- **Verification:**
  - Query `trip_progress` table for the job
  - Confirm 2 rows exist
  - Confirm trip_index values are 1 and 2
  - Confirm status values are 'pending'

**Test 7: Idempotent Initialization**
- **Setup:** 
  - Create job with 1 transport row
  - Manually create trip_progress row for trip_index = 1 with status = 'pickup_arrived'
- **Action:** Update job_status from 'open' to 'started'
- **Expected:** 
  - Trigger does not create duplicate trip_progress row
  - Existing row remains unchanged
- **Verification:** Only 1 trip_progress row exists for the job

**Test 8: Backfill Existing Jobs**
- **Setup:**
  - Create 3 jobs with status 'open' or 'started', each with 2 transport rows
  - None have trip_progress rows
- **Action:** Run backfill migration
- **Expected:**
  - All 3 jobs get trip_progress rows created
  - Each job has 2 trip_progress rows
  - All rows have correct trip_index (1, 2)
  - All rows have status = 'pending'
- **Verification:**
  - Query trip_progress for each job
  - Confirm row counts match transport row counts
  - Confirm trip_index ordering is correct

**Test 9: Service Role Bypass**
- **Setup:** Create job with 1 incomplete trip
- **Action:** As service_role, attempt to set `job_status = 'completed'`
- **Expected:** Job closure succeeds (service_role bypasses validation)
- **Verification:** Job status changes to 'completed' despite incomplete trip

**Test 10: Trip Index Ordering Consistency**
- **Setup:**
  - Create job with 3 transport rows (ids: 100, 200, 300)
  - Initialize trip_progress
- **Action:** Verify trip_index assignment
- **Expected:**
  - Transport row with id=100 → trip_index=1
  - Transport row with id=200 → trip_index=2
  - Transport row with id=300 → trip_index=3
- **Verification:** Query trip_progress and confirm mapping is correct

**Test Implementation Notes:**
- All tests should be run in a transaction that can be rolled back
- Use test fixtures for consistent setup
- Verify both database state and exception messages
- Test edge cases (zero trips, single trip, many trips)
- Test concurrent scenarios if possible
- Document any test failures and expected vs actual results

---

## Implementation Plan

### Phase 1: Database Migrations (Foundation)
**Priority:** P0 - Must be done first  
**Estimated Time:** 2-3 hours

**Tasks:**
1. Create migration for expense type and approval fields
2. Create migration for expense approval functions
3. Update RLS policies for expenses
4. Create migration for trip validation functions
5. Test migrations on development database

**Files to Create:**
- `supabase/migrations/YYYYMMDDHHMMSS_expense_enhancements.sql`
- `supabase/migrations/YYYYMMDDHHMMSS_expense_approval_functions.sql`
- `supabase/migrations/YYYYMMDDHHMMSS_expense_rls_update.sql`
- `supabase/migrations/YYYYMMDDHHMMSS_trip_validation_functions.sql`

**Validation:**
- All migrations run successfully
- Existing data preserved
- Constraints work correctly
- Functions execute without errors

### Phase 2: Expense Model and Repository
**Priority:** P0 - Foundation for expense features  
**Estimated Time:** 3-4 hours

**Tasks:**
1. Create `Expense` model with new fields
2. Create `ExpensesRepository` with CRUD operations
3. Add expense type enum
4. Add expense approval methods
5. Create `ExpensesProvider` for state management

**Files to Create:**
- `lib/features/expenses/models/expense.dart`
- `lib/features/expenses/data/expenses_repository.dart`
- `lib/features/expenses/providers/expenses_provider.dart`

**Files to Update:**
- None (new feature)

### Phase 3: Job Confirmation Enforcement
**Priority:** P1 - Core business rule  
**Estimated Time:** 2-3 hours

**Tasks:**
1. Add validation in `startJob()` to check confirmation
2. Update UI to show confirmation status
3. Disable start button until confirmed
4. Add confirmation flow in job details screen
5. Create confirmation widget

**Files to Update:**
- `lib/features/jobs/services/driver_flow_api_service.dart` - `startJob()` method
- `lib/features/jobs/screens/job_progress_screen.dart` - Start job button logic
- `lib/features/jobs/widgets/job_list_card.dart` - Confirmation status display

**Files to Create:**
- `lib/features/jobs/widgets/job_confirmation_widget.dart`

### Phase 4: Multi-Trip Management
**Priority:** P1 - Core business rule  
**Estimated Time:** 4-5 hours

**Tasks:**
1. Add trip completion validation
2. Implement automatic trip progression
3. Update UI to show current trip
4. Add "next trip" logic after completion
5. Prevent job closure until all trips complete
6. Create trip progress widget

**Files to Update:**
- `lib/features/jobs/services/driver_flow_api_service.dart` - `completeTrip()` and `closeJob()` methods
- `lib/features/jobs/data/trips_repository.dart` - Add trip query methods
- `lib/features/jobs/screens/job_progress_screen.dart` - Trip progression UI

**Files to Create:**
- `lib/features/jobs/widgets/trip_progress_widget.dart`

### Phase 5: Expense Tracking UI
**Priority:** P1 - User-facing feature  
**Estimated Time:** 4-5 hours

**Tasks:**
1. Create expense form with type selection
2. Add expense list view
3. Add expense edit/delete functionality
4. Integrate expense capture in job flow
5. Add receipt image upload

**Files to Create:**
- `lib/features/expenses/screens/add_expense_screen.dart`
- `lib/features/expenses/widgets/expense_form.dart`
- `lib/features/expenses/widgets/expense_list.dart`

**Files to Update:**
- `lib/features/jobs/screens/job_progress_screen.dart` - Add expense button and list

### Phase 6: Expense Approval Workflow
**Priority:** P1 - Manager workflow  
**Estimated Time:** 3-4 hours

**Tasks:**
1. Create manager expense approval screen
2. Add job summary with expenses view
3. Implement bulk approval
4. Add approval status indicators
5. Send notifications on approval

**Files to Create:**
- `lib/features/expenses/screens/expense_approval_screen.dart`
- `lib/features/expenses/services/expense_approval_service.dart`

**Files to Update:**
- `lib/features/jobs/screens/job_summary_screen.dart` - Add expense approval section

### Phase 7: Job Summary Updates
**Priority:** P2 - Display enhancement  
**Estimated Time:** 3-4 hours

**Tasks:**
1. Update job summary to show all trips
2. Add expense section to job summary
3. Show trip completion status
4. Display expense approval status
5. Add totals and summaries

**Files to Create:**
- `lib/features/jobs/widgets/job_trips_summary.dart`
- `lib/features/jobs/widgets/job_expenses_summary.dart`

**Files to Update:**
- `lib/features/jobs/screens/job_summary_screen.dart`

---

## Task Breakdown

### Task Group 1: Database Foundation

#### Task 1.1: Create Expense Enhancement Migration
**File:** `supabase/migrations/YYYYMMDDHHMMSS_expense_enhancements.sql`  
**Priority:** P0  
**Estimated Time:** 1 hour

**Actions:**
- Add `expense_type` column with CHECK constraint
- Add `approved_by` and `approved_at` columns
- Convert `user` column to UUID if needed
- Add foreign key constraints
- Create indexes
- Add column comments

**Validation:**
- Migration runs successfully
- Existing data preserved (set defaults if needed)
- Constraints work correctly
- Indexes improve query performance

#### Task 1.2: Create Expense Approval Functions
**File:** `supabase/migrations/YYYYMMDDHHMMSS_expense_approval_functions.sql`  
**Priority:** P0  
**Estimated Time:** 1 hour

**Functions to Create:**
- `approve_job_expenses(job_id, manager_id)` - Approve all expenses for a job
- `get_job_expenses_summary(job_id)` - Get expense summary for a job

**Validation:**
- Functions execute correctly
- Return expected data types
- Handle edge cases (no expenses, already approved, etc.)
- Security definer works correctly

#### Task 1.3: Update RLS Policies for Expenses
**File:** `supabase/migrations/YYYYMMDDHHMMSS_expense_rls_update.sql`  
**Priority:** P0  
**Estimated Time:** 30 minutes

**Actions:**
- Create policy for drivers to manage their own expenses
- Create policy for managers to approve expenses
- Ensure backward compatibility
- Test with different user roles

**Validation:**
- Drivers can create/update expenses for their jobs
- Managers can approve expenses for jobs they manage
- Other users cannot access expenses inappropriately

#### Task 1.4: Create Trip Validation Functions
**File:** `supabase/migrations/YYYYMMDDHHMMSS_trip_validation_functions.sql`  
**Priority:** P0  
**Estimated Time:** 1 hour

**Functions to Create:**
- `validate_all_trips_completed(job_id)` - Check if all trips are completed
- `get_trip_completion_status(job_id)` - Get trip completion details

**Validation:**
- Functions return correct boolean/status
- Handle edge cases (no trips, all completed, partial completion)
- Performance is acceptable

### Task Group 2: Expense Model and Repository

#### Task 2.1: Create Expense Model
**File:** `lib/features/expenses/models/expense.dart`  
**Priority:** P0  
**Estimated Time:** 1 hour

**Fields:**
- `id` (String)
- `jobId` (int)
- `expenseType` (enum: ExpenseType)
- `amount` (double)
- `date` (DateTime)
- `description` (String?)
- `otherDescription` (String?) - Required if type is "other"
- `receiptImageUrl` (String?)
- `location` (String?)
- `driverId` (String - UUID)
- `approvedBy` (String? - UUID)
- `approvedAt` (DateTime?)
- `createdAt` (DateTime)
- `updatedAt` (DateTime)

**Methods:**
- `fromJson(Map<String, dynamic>)`
- `toJson()`
- `copyWith(...)`
- `isApproved` (getter)
- Validation methods

**Enum:**
```dart
enum ExpenseType {
  fuel,
  parking,
  toll,
  other;
  
  String get value => name;
  static ExpenseType fromString(String value) => ExpenseType.values.firstWhere((e) => e.value == value);
}
```

#### Task 2.2: Create Expenses Repository
**File:** `lib/features/expenses/data/expenses_repository.dart`  
**Priority:** P0  
**Estimated Time:** 2 hours

**Methods:**
- `fetchExpensesForJob(String jobId): Future<Result<List<Expense>>>`
- `createExpense(Expense expense): Future<Result<Map<String, dynamic>>>`
- `updateExpense(Expense expense): Future<Result<void>>`
- `deleteExpense(String expenseId): Future<Result<void>>`
- `approveJobExpenses(String jobId, String managerId): Future<Result<void>>`
- `getExpenseSummary(String jobId): Future<Result<Map<String, dynamic>>>`

**Implementation Notes:**
- Use Supabase client from provider
- Follow existing repository patterns (see `JobsRepository`)
- Return `Result<T>` pattern for error handling
- Use proper logging

#### Task 2.3: Create Expenses Provider
**File:** `lib/features/expenses/providers/expenses_provider.dart`  
**Priority:** P0  
**Estimated Time:** 1 hour

**Providers:**
- `expensesRepositoryProvider` - Repository provider
- `expensesProvider(jobId)` - List of expenses for a job (AsyncNotifierProvider)
- `expenseSummaryProvider(jobId)` - Summary data (FutureProvider)

**Methods:**
- `createExpense(Expense expense)`
- `updateExpense(Expense expense)`
- `deleteExpense(String expenseId)`
- `approveExpenses(String jobId)`
- `refreshExpenses(String jobId)`

### Task Group 3: Job Confirmation Enforcement

#### Task 3.1: Update Start Job Validation
**File:** `lib/features/jobs/services/driver_flow_api_service.dart`  
**Method:** `startJob()` (line 10)  
**Priority:** P1  
**Estimated Time:** 30 minutes

**Changes:**
```dart
// Before starting job, check if it's confirmed
final jobResponse = await _supabase
    .from('jobs')
    .select('driver_id, driver_confirm_ind, is_confirmed')
    .eq('id', jobId)
    .single();

final isConfirmed = jobResponse['driver_confirm_ind'] == true || 
                    jobResponse['is_confirmed'] == true;

if (!isConfirmed) {
  throw Exception('Job must be confirmed before starting. Please confirm the job first.');
}
```

**Validation:**
- Unconfirmed jobs cannot be started
- Error message is clear
- Confirmed jobs start normally

#### Task 3.2: Update Job Progress Screen
**File:** `lib/features/jobs/screens/job_progress_screen.dart`  
**Priority:** P1  
**Estimated Time:** 1 hour

**Changes:**
- Check job confirmation status on load
- Show confirmation status badge
- Disable "Start Job" button if not confirmed
- Show "Confirm Job" button if not confirmed
- Handle confirmation flow (call `confirmJob()` from provider)

**UI Elements:**
- Confirmation status indicator
- Confirm button (if not confirmed)
- Start button (disabled until confirmed)

#### Task 3.3: Create Confirmation Widget
**File:** `lib/features/jobs/widgets/job_confirmation_widget.dart`  
**Priority:** P1  
**Estimated Time:** 1 hour

**Features:**
- Confirmation button with loading state
- Status display (confirmed/unconfirmed)
- Timestamp display (when confirmed)
- Success/error feedback

### Task Group 4: Multi-Trip Management

#### Task 4.1: Add Trip Completion Validation
**File:** `lib/features/jobs/services/driver_flow_api_service.dart`  
**Method:** `completeTrip()` (line 346)  
**Priority:** P1  
**Estimated Time:** 1 hour

**Changes:**
- After completing trip, check if more trips exist
- Query total trips from `transport` table
- Query completed trips from `trip_progress` table
- If more trips exist, increment `current_trip_index` in `driver_flow`
- If all trips complete, set flag for job closure eligibility

**Logic:**
```dart
// After trip completion
final totalTrips = await _getTotalTripsForJob(jobId);
final completedTrips = await _getCompletedTripsForJob(jobId);

if (completedTrips < totalTrips) {
  // More trips to go - increment current_trip_index
  await _supabase
      .from('driver_flow')
      .update({
        'current_trip_index': tripIndex + 1,
        'current_step': 'pickup_arrival', // Reset for next trip
      })
      .eq('job_id', jobId);
} else {
  // All trips completed - ready for job closure
  await _supabase
      .from('driver_flow')
      .update({
        'current_step': 'ready_to_close',
      })
      .eq('job_id', jobId);
}
```

#### Task 4.2: Add Trip Progression Logic
**File:** `lib/features/jobs/data/trips_repository.dart`  
**Priority:** P1  
**Estimated Time:** 1 hour

**New Methods:**
- `getTotalTripsForJob(String jobId): Future<Result<int>>`
- `getCompletedTripsForJob(String jobId): Future<Result<int>>`
- `getCurrentTripIndex(String jobId): Future<Result<int?>>`
- `getNextTrip(String jobId): Future<Result<Trip?>>`
- `areAllTripsCompleted(String jobId): Future<Result<bool>>`

**Implementation:**
- Query `transport` table for total trips
- Query `trip_progress` table for completed trips
- Use database function `get_trip_completion_status()` if available

#### Task 4.3: Update Job Closure Validation
**File:** `lib/features/jobs/services/driver_flow_api_service.dart`  
**Method:** `closeJob()` (line 491)  
**Priority:** P1  
**Estimated Time:** 30 minutes

**Changes:**
- Before closing job, validate all trips are completed
- Use `validate_all_trips_completed()` database function
- Throw exception if trips incomplete
- Show clear error message

**Validation:**
```dart
// Before closing job
final allTripsCompleted = await _supabase
    .rpc('validate_all_trips_completed', params: {'p_job_id': jobId})
    .single();

if (!allTripsCompleted) {
  throw Exception('Cannot close job. All trips must be completed first.');
}
```

#### Task 4.4: Update Job Progress UI
**File:** `lib/features/jobs/screens/job_progress_screen.dart`  
**Priority:** P1  
**Estimated Time:** 2 hours

**Changes:**
- Show current trip number (e.g., "Trip 2 of 3")
- Automatically show next trip after completion
- Show trip completion status
- Disable "Close Job" until all trips done
- Show progress indicator

**UI Elements:**
- Trip counter ("Trip X of Y")
- Trip progress bar
- Current trip details
- Next trip preview (if available)
- Close job button (disabled with message if trips incomplete)

#### Task 4.5: Create Trip Progress Widget
**File:** `lib/features/jobs/widgets/trip_progress_widget.dart`  
**Priority:** P1  
**Estimated Time:** 1.5 hours

**Features:**
- Trip list with status indicators
- Current trip highlight
- Progress indicator (X of Y completed)
- Trip details display (pickup, dropoff, times)
- Visual status indicators (pending, in-progress, completed)

### Task Group 5: Expense Tracking UI

#### Task 5.1: Create Expense Form
**File:** `lib/features/expenses/widgets/expense_form.dart`  
**Priority:** P1  
**Estimated Time:** 2 hours

**Fields:**
- Expense type dropdown (fuel, parking, toll, other)
- Amount input (numeric, > 0)
- Date/time picker (defaults to now)
- Description input (required if type is "other")
- Location input (optional, text)
- Receipt image upload (optional, image picker)

**Validation:**
- Type required
- Amount > 0
- Description required if type is "other"
- Date required

**UI:**
- Form with proper validation
- Error messages
- Loading states
- Image preview for receipt

#### Task 5.2: Create Add Expense Screen
**File:** `lib/features/expenses/screens/add_expense_screen.dart`  
**Priority:** P1  
**Estimated Time:** 1.5 hours

**Features:**
- Expense form
- Save/Cancel buttons
- Image picker for receipt
- Integration with job context
- Navigation back to job screen on save

#### Task 5.3: Create Expense List Widget
**File:** `lib/features/expenses/widgets/expense_list.dart`  
**Priority:** P1  
**Estimated Time:** 1.5 hours

**Features:**
- List of expenses for a job
- Expense type icons/badges
- Amount display (formatted currency)
- Date/time display
- Driver name display
- Edit/Delete actions (if not approved)
- Approval status indicator
- Receipt image thumbnail (if available)

#### Task 5.4: Integrate Expenses in Job Flow
**File:** `lib/features/jobs/screens/job_progress_screen.dart`  
**Priority:** P1  
**Estimated Time:** 1 hour

**Changes:**
- Add "Add Expense" button (visible during job execution)
- Show expense list widget
- Link expenses to current job
- Allow expense management (add/edit/delete) during job
- Show expense total

### Task Group 6: Expense Approval Workflow

#### Task 6.1: Create Expense Approval Screen
**File:** `lib/features/expenses/screens/expense_approval_screen.dart`  
**Priority:** P1  
**Estimated Time:** 2 hours

**Features:**
- Job summary header (job number, passenger, dates, driver)
- List of all trips with completion status
- List of all expenses with details
- Total expense amount display
- "Approve Expenses" button (only if job completed and not approved)
- Approval status display (if approved, show manager name and timestamp)
- Navigation back to job summary

**Layout:**
- Job info section at top
- Trips summary section
- Expenses list section
- Approval action section at bottom

#### Task 6.2: Create Expense Approval Service
**File:** `lib/features/expenses/services/expense_approval_service.dart`  
**Priority:** P1  
**Estimated Time:** 1 hour

**Methods:**
- `approveJobExpenses(String jobId, String managerId): Future<Result<void>>`
- `getExpenseApprovalStatus(String jobId): Future<Result<Map<String, dynamic>>>`
- `sendApprovalNotification(String jobId, String managerId): Future<void>`

**Implementation:**
- Call database function `approve_job_expenses()`
- Handle errors appropriately
- Send notification to driver on approval
- Update local state

#### Task 6.3: Update Job Summary for Approval
**File:** `lib/features/jobs/screens/job_summary_screen.dart`  
**Priority:** P1  
**Estimated Time:** 1.5 hours

**Changes:**
- Add expense section to job summary
- Show expense list with approval status
- Show "Approve Expenses" button for managers (if job completed and not approved)
- Display approval status and timestamp
- Show expense totals
- Link to expense approval screen

### Task Group 7: Job Summary Updates

#### Task 7.1: Create Job Trips Summary Widget
**File:** `lib/features/jobs/widgets/job_trips_summary.dart`  
**Priority:** P2  
**Estimated Time:** 1.5 hours

**Features:**
- List all trips for the job
- Trip status indicators (completed/pending)
- Trip details (pickup location, dropoff location)
- Trip times (pickup time, dropoff time)
- Trip completion status
- Visual indicators (icons, colors)

#### Task 7.2: Create Job Expenses Summary Widget
**File:** `lib/features/jobs/widgets/job_expenses_summary.dart`  
**Priority:** P2  
**Estimated Time:** 1.5 hours

**Features:**
- List all expenses for the job
- Expense type icons/badges
- Amounts and totals
- Approval status
- Manager approval info (name, date/time) if approved
- Receipt thumbnails (if available)

#### Task 7.3: Update Job Summary Screen
**File:** `lib/features/jobs/screens/job_summary_screen.dart`  
**Priority:** P2  
**Estimated Time:** 2 hours

**Changes:**
- Add trips summary section (use `JobTripsSummaryWidget`)
- Add expenses summary section (use `JobExpensesSummaryWidget`)
- Show completion status
- Show totals and summaries
- Update layout to accommodate new sections
- Ensure responsive design

---

## Testing Strategy

### Unit Tests

#### Expense Model Tests
**File:** `test/features/expenses/models/expense_test.dart`

**Test Cases:**
- `fromJson()` with all fields
- `fromJson()` with missing optional fields
- `toJson()` returns correct structure
- `copyWith()` updates fields correctly
- Validation for "other" type requiring description
- `isApproved` getter returns correct value

#### Expense Repository Tests
**File:** `test/features/expenses/data/expenses_repository_test.dart`

**Test Cases:**
- `fetchExpensesForJob()` returns expenses
- `createExpense()` creates expense successfully
- `updateExpense()` updates expense
- `deleteExpense()` deletes expense
- `approveJobExpenses()` approves all expenses
- Error handling for invalid job ID
- Error handling for network errors

#### Trip Validation Tests
**File:** `test/features/jobs/services/trip_validation_test.dart`

**Test Cases:**
- `validate_all_trips_completed()` returns true when all completed
- `validate_all_trips_completed()` returns false when some incomplete
- `get_trip_completion_status()` returns correct counts
- Handles job with no trips
- Handles job with single trip

### Integration Tests

#### Job Confirmation Flow
**File:** `test/features/jobs/integration/job_confirmation_test.dart`

**Test Cases:**
- Driver can confirm job
- Job cannot be started without confirmation
- Confirmation persists after app restart
- Reassignment clears confirmation
- New driver must confirm after reassignment

#### Multi-Trip Flow
**File:** `test/features/jobs/integration/multi_trip_test.dart`

**Test Cases:**
- Single trip job completes and closes successfully
- Multi-trip job progresses through trips sequentially
- Job cannot be closed with incomplete trips
- Next trip shows automatically after completion
- All trips completed allows job closure

#### Expense Workflow
**File:** `test/features/expenses/integration/expense_workflow_test.dart`

**Test Cases:**
- Driver can add expense during job
- Driver can add expense after job completion
- "Other" type requires description
- Manager can approve expenses after job completion
- Approval updates all expenses for job
- Approval status displays correctly

### Manual Testing Scenarios

#### Scenario 1: Single Trip Job with Expenses
1. Manager creates job with 1 trip
2. Driver receives job notification
3. Driver confirms job
4. Driver starts job
5. Driver adds fuel expense
6. Driver completes trip
7. Driver closes job
8. Manager reviews job summary
9. Manager approves expenses
10. Verify approval status

#### Scenario 2: Multi-Trip Job
1. Manager creates job with 3 trips
2. Driver confirms job
3. Driver starts job
4. Driver completes trip 1 → trip 2 shows automatically
5. Driver adds parking expense
6. Driver completes trip 2 → trip 3 shows automatically
7. Driver completes trip 3 → "Close Job" button enabled
8. Driver tries to close job → succeeds (all trips done)
9. Manager reviews all trips and expenses
10. Manager approves expenses

#### Scenario 3: Expense Management
1. Driver adds fuel expense (R500)
2. Driver adds parking expense (R50)
3. Driver adds "other" expense (R100, description: "Cleaning")
4. Driver views expense list → sees all 3 expenses
5. Driver edits parking expense → updates to R75
6. Driver deletes "other" expense
7. Job completed → expenses show as pending approval
8. Manager views expenses → sees 2 expenses (fuel R500, parking R75)
9. Manager approves → both expenses marked as approved
10. Driver views expenses → sees approval status

#### Scenario 4: Job Reassignment
1. Manager assigns job to Driver A
2. Driver A confirms job
3. Manager reassigns job to Driver B
4. Driver A can no longer see/access job
5. Driver B receives notification
6. Driver B must confirm job (confirmation reset)
7. Driver B starts and completes job

#### Scenario 5: Error Cases
1. Try to start unconfirmed job → error message
2. Try to close job with incomplete trips → error message
3. Try to add "other" expense without description → validation error
4. Try to approve expenses before job completion → error message
5. Try to approve expenses twice → handled gracefully

---

## Risk Assessment

### High Risk

1. **Data Migration for Expenses**
   - **Risk:** Existing expense data may not have `expense_type`, causing migration failures
   - **Impact:** High - Migration could fail, blocking deployment
   - **Mitigation:** 
     - Set default `expense_type = 'other'` for existing records
     - Test migration on copy of production data first
     - Create rollback migration

2. **Trip Progression Logic**
   - **Risk:** Complex state management for multi-trip jobs could have bugs
   - **Impact:** High - Drivers might get stuck or skip trips
   - **Mitigation:** 
     - Thorough unit and integration testing
     - Clear state transitions with logging
     - Manual testing with various trip counts

3. **Job Closure Validation**
   - **Risk:** Jobs might be closed with incomplete trips due to race conditions
   - **Impact:** High - Data integrity issue
   - **Mitigation:** 
     - Database-level validation function
     - UI validation before API call
     - Clear error messages

### Medium Risk

1. **Expense Approval Workflow**
   - **Risk:** Approval might fail silently or partially
   - **Impact:** Medium - Expenses not properly approved
   - **Mitigation:** 
     - Proper error handling and user feedback
     - Transaction-based approval (all or nothing)
     - Status checks and notifications

2. **UI State Management**
   - **Risk:** UI might not reflect current trip state correctly
   - **Impact:** Medium - User confusion
   - **Mitigation:** 
     - Use Riverpod for reactive state
     - Proper refresh logic after state changes
     - Loading and error states

3. **Performance with Many Trips**
   - **Risk:** Jobs with many trips (10+) might be slow to load/process
   - **Impact:** Medium - Poor user experience
   - **Mitigation:** 
     - Efficient database queries with indexes
     - Lazy loading if needed
     - Pagination for trip lists if necessary

### Low Risk

1. **Expense Type Validation**
   - **Risk:** Invalid expense types might be submitted
   - **Impact:** Low - Data quality issue
   - **Mitigation:** 
     - Enum types in code
     - UI dropdown (no free text)
     - Database CHECK constraint

2. **Image Upload for Receipts**
   - **Risk:** Large images, upload failures, storage issues
   - **Impact:** Low - Feature might not work, but doesn't block core flow
   - **Mitigation:** 
     - Image compression before upload
     - Retry logic for failed uploads
     - Clear error messages
     - Optional feature (not required)

3. **RLS Policy Conflicts**
   - **Risk:** New RLS policies might conflict with existing ones
   - **Impact:** Low - Access issues
   - **Mitigation:** 
     - Test with different user roles
     - Review existing policies before adding new ones
     - Use policy names that don't conflict

---

## Success Criteria

### Functional Requirements
✅ Drivers must confirm jobs before starting  
✅ Confirmed jobs remain with driver unless reassigned  
✅ Jobs with multiple trips require all trips to be completed before closure  
✅ Next trip automatically shows after completing current trip  
✅ Expenses can be added with proper types (fuel, parking, toll, other)  
✅ "Other" expense type requires description  
✅ Managers can approve expenses after job completion  
✅ Job summary shows all trips with completion status  
✅ Job summary shows all expenses with approval status  
✅ Expense approval updates all expenses for a job (bulk approval)  

### Technical Requirements
✅ All database migrations run successfully  
✅ All database functions work correctly  
✅ RLS policies enforce proper access control  
✅ All unit tests pass  
✅ All integration tests pass  
✅ UI is responsive and user-friendly  
✅ Error handling is comprehensive  
✅ Loading states are shown appropriately  
✅ State management is reactive and consistent  

### User Experience Requirements
✅ Clear visual indicators for confirmation status  
✅ Clear visual indicators for trip progress  
✅ Clear visual indicators for expense approval status  
✅ Helpful error messages when operations fail  
✅ Intuitive navigation between screens  
✅ Fast loading times (< 2 seconds for most operations)  
✅ Works on mobile devices (primary platform)  

### Data Integrity Requirements
✅ No jobs can be closed with incomplete trips  
✅ No jobs can be started without confirmation  
✅ No expenses can be approved before job completion  
✅ All expense types are validated  
✅ All foreign key relationships are maintained  
✅ All timestamps are recorded correctly  

---

## Related Files

### Database
- `supabase/migrations/` - All migration files
- `ai/DATA_SCHEMA.md` - Complete schema documentation
- `supabase/queries/` - Query files for reference

### Code - Jobs Feature
- `lib/features/jobs/data/jobs_repository.dart` - Job data operations
- `lib/features/jobs/data/trips_repository.dart` - Trip data operations
- `lib/features/jobs/providers/jobs_provider.dart` - Job state management
- `lib/features/jobs/services/driver_flow_api_service.dart` - Job flow logic
- `lib/features/jobs/screens/job_progress_screen.dart` - Job execution UI
- `lib/features/jobs/screens/job_summary_screen.dart` - Job review UI
- `lib/features/jobs/widgets/job_list_card.dart` - Job list display

### Code - Expenses Feature (New)
- `lib/features/expenses/models/expense.dart` - Expense model
- `lib/features/expenses/data/expenses_repository.dart` - Expense data operations
- `lib/features/expenses/providers/expenses_provider.dart` - Expense state management
- `lib/features/expenses/screens/` - Expense screens
- `lib/features/expenses/widgets/` - Expense widgets
- `lib/features/expenses/services/expense_approval_service.dart` - Approval logic

### Documentation
- `ai/STATE_OF_APP.md` - Current app state baseline
- `ai/IN_PROGRESS_FIX.md` - Related job visibility fixes
- `ai/PROJECT.md` - Project overview and architecture
- `ai/DATA_SCHEMA.md` - Database schema reference

---

## Implementation Notes

### Architecture Patterns to Follow
- Use Riverpod for state management (AsyncNotifierProvider for async data)
- Use Repository pattern for data access (see `JobsRepository` as example)
- Use Result<T> pattern for error handling (see existing repositories)
- Follow existing UI patterns (see `job_progress_screen.dart`)
- Use existing theme and styling (see `app/theme.dart`)

### Code Quality Standards
- All methods must have proper error handling
- All database operations must use transactions where appropriate
- All UI must have loading and error states
- All user actions must provide feedback (success/error messages)
- All code must follow existing formatting and style

### Testing Requirements
- Unit tests for all models and repositories
- Integration tests for critical flows
- Manual testing for all user scenarios
- Performance testing for jobs with many trips
- Security testing for RLS policies

### Deployment Considerations
- Migrations must be reversible (create rollback migrations)
- Feature flags might be needed for gradual rollout
- Monitor database performance after deployment
- Monitor error rates and user feedback
- Have rollback plan ready

---

## Timeline Estimate

**Total Estimated Time:** 25-30 hours

**Breakdown:**
- Phase 1 (Database): 2-3 hours
- Phase 2 (Expense Model/Repo): 3-4 hours
- Phase 3 (Job Confirmation): 2-3 hours
- Phase 4 (Multi-Trip): 4-5 hours
- Phase 5 (Expense UI): 4-5 hours
- Phase 6 (Expense Approval): 3-4 hours
- Phase 7 (Job Summary): 3-4 hours
- Testing: 4-5 hours

**Recommended Approach:**
- Implement in phases, testing after each phase
- Start with database migrations (Phase 1)
- Build foundation (Phase 2)
- Implement core features (Phases 3-4)
- Add expense features (Phases 5-6)
- Polish and summary (Phase 7)

---

## Notes

- This implementation should be done incrementally to minimize risk
- Each phase should be tested before moving to the next
- Database migrations should be tested on development database first
- UI should provide clear feedback at each step
- Error messages should be user-friendly and actionable
- All changes should follow existing architecture patterns
- Consider mobile-first design for all new UI components
- Ensure accessibility (screen readers, keyboard navigation)
- Consider offline capability for expense capture (store locally, sync later)

---

**Document Status:** Ready for Implementation  
**Last Updated:** 2025-01-XX  
**Next Steps:** Review plan, prioritize phases, begin Phase 1 (Database Migrations)

