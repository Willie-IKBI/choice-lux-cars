# Driver Flow Navigation & Expenses Implementation Plan

## TASK A: Navigate Button Trace

### Current Implementation

**File:** `lib/features/jobs/screens/job_progress_screen.dart`

**Location:**
- Lines 652-663: Mobile layout Navigate button
- Lines 690-702: Desktop layout Navigate button

**Code Snippet:**
```dart
// Lines 602-654
if (stepAddress != null && stepAddress.isNotEmpty) ...[
  // Address display container
  // ...
  ElevatedButton.icon(
    onPressed: () => _openNavigation(stepAddress!),
    icon: const Icon(Icons.navigation, size: 16),
    label: const Text('Navigate'),
    // ... styling
  ),
]
```

**Condition for Display:**
- Line 602: `if (stepAddress != null && stepAddress.isNotEmpty)`
- `stepAddress` is set at lines 483-487:
  ```dart
  String? stepAddress;
  if (step.id == 'pickup_arrival' || step.id == 'passenger_pickup') {
    stepAddress = _jobAddresses['pickup'];
  } else if (step.id == 'dropoff_arrival') {
    stepAddress = _jobAddresses['dropoff'];
  }
  ```

**Button Functionality:**
- Lines 44-59: `_openNavigation(String address)` method
- Opens Google Maps with destination address
- Uses `launchUrl` with `LaunchMode.externalApplication`

**Why It Appears Inactive:**
- Button is NOT disabled (`onPressed` is set)
- Likely cause: `stepAddress` is `null` or empty, so button doesn't render
- OR: `_jobAddresses` map doesn't contain 'pickup'/'dropoff' keys
- OR: Addresses are not loaded from `DriverFlowApiService.getJobAddresses()`

**Root Cause:**
- Button is conditionally rendered based on address availability
- If addresses aren't loaded or are empty, button doesn't appear
- User may be seeing the button in some cases but it's not consistently visible

**Recommendation:**
- **FOR NOW:** Remove/hide the Navigate button entirely for all roles
- **Scope:** Remove from both mobile and desktop layouts in `job_progress_screen.dart`
- **Rationale:** Feature not wanted now, and conditional rendering makes it unreliable

---

## TASK B: Expenses Capture UI Trace

### What EXISTS

#### 1. Database & RLS
- ✅ Table: `public.expenses` exists (from migrations)
- ✅ RLS policies: Drivers can INSERT for their assigned jobs (Migration 7)
- ✅ RPC: `approve_job_expenses(p_job_id)` exists for manager approval

#### 2. Data Layer
**File:** `lib/features/jobs/models/expense.dart`
- ✅ Complete Expense model with all fields:
  - `id`, `jobId`, `driverId`, `expenseType`, `amount`, `expDate`
  - `expenseDescription`, `otherDescription`, `slipImage`, `expenseLocation`
  - `approvedBy`, `approvedAt`, `createdAt`, `updatedAt`
- ✅ Helper methods: `isApproved`, `displayDescription`
- ✅ `toJson()` / `fromJson()` methods

**File:** `lib/features/jobs/data/expenses_repository.dart`
- ✅ `getExpensesForJob(int jobId)` - SELECT method
- ✅ `approveJobExpenses(int jobId)` - RPC call for approval
- ❌ **MISSING:** `createExpense(Expense expense)` - INSERT method
- ❌ **MISSING:** `updateExpense(Expense expense)` - UPDATE method
- ❌ **MISSING:** `deleteExpense(int expenseId)` - DELETE method

#### 3. State Management
**File:** `lib/features/jobs/providers/expenses_provider.dart`
- ✅ `expensesForJobProvider(jobId)` - AsyncValue<List<Expense>>
- ✅ `refresh()` - Reload expenses
- ✅ `approveAll()` - Manager approval action
- ❌ **MISSING:** `createExpense(Expense expense)` method
- ❌ **MISSING:** `updateExpense(Expense expense)` method
- ❌ **MISSING:** `deleteExpense(int expenseId)` method

#### 4. UI - Read-Only Display
**File:** `lib/features/jobs/widgets/expenses_card.dart`
- ✅ Displays expenses list with totals
- ✅ Shows expense type, amount, date, description
- ✅ Approval button for managers (when job completed)
- ✅ Approval status indicators
- ❌ **MISSING:** "Add Expense" button
- ❌ **MISSING:** Expense creation form
- ❌ **MISSING:** Expense edit/delete actions

**Usage:**
- ✅ Used in `JobSummaryScreen` (desktop: line 453-457, mobile: line 510-514)
- ❌ **NOT used in** `JobProgressScreen` (driver flow screen)

#### 5. Service Layer
**File:** `lib/features/jobs/services/expense_approval_service.dart`
- ✅ `computeTotals(List<Expense>)` - Calculate totals
- ✅ `mapApprovalErrorToMessage(AppException)` - Error mapping
- ❌ **MISSING:** Expense validation service
- ❌ **MISSING:** Expense creation service

### What is MISSING

#### 1. Repository Methods
- ❌ `ExpensesRepository.createExpense(Expense expense)` - INSERT into expenses table
- ❌ `ExpensesRepository.updateExpense(Expense expense)` - UPDATE expense (if not approved)
- ❌ `ExpensesRepository.deleteExpense(int expenseId)` - DELETE expense (if not approved)

#### 2. Provider Methods
- ❌ `ExpensesNotifier.createExpense(Expense expense)` - Create and refresh
- ❌ `ExpensesNotifier.updateExpense(Expense expense)` - Update and refresh
- ❌ `ExpensesNotifier.deleteExpense(int expenseId)` - Delete and refresh

#### 3. UI Components
- ❌ Expense form widget (`expense_form.dart` or `add_expense_modal.dart`)
  - Expense type dropdown (fuel, parking, toll, other)
  - Amount input
  - Date/time picker
  - Description input (required for "other")
  - Location input (optional)
  - Receipt image upload (optional)
- ❌ "Add Expense" button in `JobProgressScreen`
- ❌ Expense list with edit/delete actions in `JobProgressScreen`
- ❌ Expense creation screen/modal

#### 4. Integration Points
- ❌ ExpensesCard or expense list in `JobProgressScreen` (driver view)
- ❌ Navigation from driver flow to expense creation
- ❌ Expense validation (amount > 0, description required for "other", etc.)

### Intended Roles (from DB Contract & RLS)

**CREATE Expenses:**
- ✅ Drivers can INSERT expenses for their assigned jobs (RLS policy: `expenses_insert_policy`)
- ❌ Managers cannot create expenses (RLS blocks)
- ❌ Admins cannot create expenses (RLS blocks)

**APPROVE Expenses:**
- ✅ Managers can approve via RPC `approve_job_expenses` (for jobs they manage)
- ✅ Admins can approve via RPC (for any job)
- ❌ Drivers cannot approve

**Constraints (from DB triggers):**
- ✅ Expenses cannot be added after job has approved expenses (Migration 10: `trg_block_expense_inserts_after_approval`)
- ✅ Expenses cannot be updated/deleted after approval (Migration 5: immutability trigger)
- ✅ Expenses can only be approved when job_status = 'completed' (RPC validation)

---

## GAP ANALYSIS

### Summary: "We have X, missing Y and Z"

**✅ WE HAVE:**
1. Database schema with RLS policies
2. Expense model (data structure)
3. Repository SELECT and APPROVE methods
4. Provider for fetching and approving
5. Read-only display widget (ExpensesCard)
6. Manager approval workflow (RPC + UI)

**❌ WE ARE MISSING:**
1. Repository INSERT/UPDATE/DELETE methods
2. Provider create/update/delete methods
3. Expense form widget (all fields)
4. Expense creation UI (button + modal/screen)
5. Expense list with actions in driver flow screen
6. Integration of expenses in JobProgressScreen
7. Image upload for receipt/slip
8. Validation service for expense creation

**📋 SCREENS THAT SHOULD HOST ACTIONS:**
- **JobProgressScreen** (driver view): Add "Add Expense" button + expense list
- **JobSummaryScreen** (manager view): Already has ExpensesCard (read-only + approval) ✅

**🧭 NAVIGATION REQUIRED:**
- From JobProgressScreen → Expense creation modal/screen
- Return to JobProgressScreen after expense creation
- Refresh expense list after creation

---

## PROPOSED UX DECISIONS

### 1. Navigate Button - Hide/Remove

**Decision:** Remove Navigate button entirely from `JobProgressScreen`

**Scope:**
- Remove from mobile layout (lines 649-664)
- Remove from desktop layout (lines 689-703)
- Keep `_openNavigation()` method for potential future use (or remove if not needed)
- Keep address display (lines 602-643) but remove navigation button

**Files to Change:**
- `lib/features/jobs/screens/job_progress_screen.dart` (remove button widgets only)

**Minimal Change:**
- Comment out or remove the `ElevatedButton.icon` widgets for Navigate
- Keep address display container (informational only)

### 2. Expense Capture - Add to Driver Flow

**Decision:** Add expense creation UI to `JobProgressScreen` (driver view)

**Where It Lives:**
- **Location:** `JobProgressScreen` - Add expense section below trip progress
- **UI Pattern:** 
  - "Add Expense" floating action button OR
  - "Expenses" card/section with "Add Expense" button inside
  - Expense list showing all expenses for the job
  - Each expense shows: type, amount, date, description
  - Edit/Delete actions (only if not approved)

**Fields Required:**
- Expense type: Dropdown (fuel, parking, toll, other) - **REQUIRED**
- Amount: Numeric input (> 0) - **REQUIRED**
- Date/Time: DateTime picker (default: now) - **REQUIRED**
- Description: Text input (required if type = "other") - **CONDITIONAL**
- Location: Text input (optional)
- Receipt image: Image picker + upload (optional)

**Validations:**
- Amount must be > 0
- Description required if expense_type = 'other'
- Date must be valid DateTime
- Job must not have approved expenses (DB trigger enforces)

**Access Control:**
- Only drivers can see "Add Expense" button
- Only for jobs where `driver_id = current_user.id`
- Button disabled if job has approved expenses (show message why)

---

## IMPLEMENTATION OUTLINE (Later)

### Phase 1: Repository & Provider Methods

**Files to Update:**
1. `lib/features/jobs/data/expenses_repository.dart`
   - Add `createExpense(Expense expense)` method
   - Add `updateExpense(Expense expense)` method (with approval check)
   - Add `deleteExpense(int expenseId)` method (with approval check)

2. `lib/features/jobs/providers/expenses_provider.dart`
   - Add `createExpense(Expense expense)` method
   - Add `updateExpense(Expense expense)` method
   - Add `deleteExpense(int expenseId)` method

### Phase 2: Expense Form Widget

**Files to Create:**
1. `lib/features/jobs/widgets/add_expense_modal.dart` OR
   `lib/features/jobs/widgets/expense_form_modal.dart`
   - Form with all expense fields
   - Validation logic
   - Image picker integration
   - Submit/Cancel buttons

### Phase 3: Integration in JobProgressScreen

**Files to Update:**
1. `lib/features/jobs/screens/job_progress_screen.dart`
   - Add expense section/widget
   - Add "Add Expense" button (driver only)
   - Show expense list
   - Handle navigation to expense form

### Phase 4: Remove Navigate Button

**Files to Update:**
1. `lib/features/jobs/screens/job_progress_screen.dart`
   - Remove Navigate button widgets (lines 649-664, 689-703)
   - Keep address display (informational)

### Phase 5: Image Upload (if needed)

**Files to Create/Update:**
1. Image upload service (if not exists)
2. Supabase Storage integration for receipt images
3. Update Expense model to handle image URLs

### RLS Updates Needed

**Status:** ✅ No RLS updates needed
- RLS policies already allow drivers to INSERT expenses for their jobs
- RLS policies already block updates/deletes after approval
- Migration 10 already blocks inserts after approval

---

## TEST CHECKLIST (Role-Based)

### Test 1: Driver Can Add Expense to Assigned Job
**Steps:**
1. Login as Driver A
2. Navigate to JobProgressScreen for job assigned to Driver A
3. Verify "Add Expense" button is visible
4. Click "Add Expense"
5. Fill form: type=fuel, amount=100, date=now, description=optional
6. Submit
7. **Expected:** Expense appears in list, success message shown

### Test 2: Driver Cannot Add Expense to Other Driver Job
**Steps:**
1. Login as Driver A
2. Navigate to JobProgressScreen for job assigned to Driver B
3. **Expected:** "Add Expense" button NOT visible (RLS blocks at DB level)
4. If button visible (UI bug), attempt to create expense
5. **Expected:** RLS error, expense creation fails

### Test 3: Driver Cannot Add Expense After Approval
**Steps:**
1. Login as Driver A
2. Navigate to job with approved expenses
3. **Expected:** "Add Expense" button disabled or hidden
4. If visible, attempt to create expense
5. **Expected:** DB trigger error: "Cannot add expenses to job with approved expenses"

### Test 4: Driver Can Edit Own Unapproved Expense
**Steps:**
1. Login as Driver A
2. Create expense (unapproved)
3. Click edit on expense
4. Update amount
5. Submit
6. **Expected:** Expense updated, list refreshed

### Test 5: Driver Cannot Edit Approved Expense
**Steps:**
1. Login as Driver A
2. Navigate to job with approved expense
3. **Expected:** Edit button NOT visible for approved expenses
4. If visible, attempt to update
5. **Expected:** DB trigger error: "Cannot update approved expense"

### Test 6: Manager Can View Expenses (Read-Only)
**Steps:**
1. Login as Manager
2. Navigate to JobSummaryScreen for managed job
3. **Expected:** ExpensesCard shows all expenses
4. **Expected:** "Approve Expenses" button visible if job completed and unapproved expenses exist

### Test 7: Manager Can Approve Expenses
**Steps:**
1. Login as Manager
2. Navigate to JobSummaryScreen for completed job with unapproved expenses
3. Click "Approve Expenses"
4. **Expected:** All expenses approved, approval status shown, button disabled

### Test 8: Navigate Button Removed
**Steps:**
1. Login as Driver
2. Navigate to JobProgressScreen
3. **Expected:** Navigate button NOT visible in any step
4. Address display may still be visible (informational)

---

## REQUIREMENTS CLARIFICATION LIST

**Decisions Needed:**

1. **Navigate Button:**
   - ✅ Decision: Remove entirely (confirmed by user)
   - ❓ Keep address display? (informational only, no button)

2. **Expense Creation Location:**
   - ✅ Decision: Add to JobProgressScreen (driver flow)
   - ❓ Modal vs. separate screen? (Recommend: Modal for mobile-first)
   - ❓ Where exactly in JobProgressScreen? (Below trip progress? Separate tab?)

3. **Expense List Display:**
   - ❓ Show expense list in JobProgressScreen? (Recommend: Yes, below trip progress)
   - ❓ Show expenses in JobSummaryScreen for drivers? (Currently only managers see it)

4. **Image Upload:**
   - ❓ Required for MVP? (Recommend: Optional, can add later)
   - ❓ Storage location? (Supabase Storage bucket)

5. **Expense Edit/Delete:**
   - ❓ Allow drivers to edit/delete unapproved expenses? (Recommend: Yes, for flexibility)
   - ❓ Show edit/delete in JobProgressScreen or only in form? (Recommend: Inline actions)

6. **Validation:**
   - ❓ Client-side validation only or also server-side? (Recommend: Both - client for UX, server for security)
   - ❓ Maximum amount limit? (Business decision)

7. **Expense Types:**
   - ✅ Confirmed: fuel, parking, toll, other (from model)
   - ❓ Add more types later? (Extensible design)

---

## FILE CHANGE SUMMARY

### Files to Modify:
1. `lib/features/jobs/screens/job_progress_screen.dart`
   - Remove Navigate button (lines 649-664, 689-703)
   - Add expense section/widget
   - Add "Add Expense" button (driver only)

2. `lib/features/jobs/data/expenses_repository.dart`
   - Add `createExpense()` method
   - Add `updateExpense()` method
   - Add `deleteExpense()` method

3. `lib/features/jobs/providers/expenses_provider.dart`
   - Add `createExpense()` method
   - Add `updateExpense()` method
   - Add `deleteExpense()` method

### Files to Create:
1. `lib/features/jobs/widgets/add_expense_modal.dart` (or `expense_form_modal.dart`)
   - Expense creation form
   - Validation
   - Image picker (optional)

2. `lib/features/jobs/widgets/expense_list_widget.dart` (optional, or inline in JobProgressScreen)
   - Expense list display
   - Edit/Delete actions

### Files NOT to Change:
- `lib/features/jobs/widgets/expenses_card.dart` (keep as-is for manager view)
- `lib/features/jobs/models/expense.dart` (model is complete)
- Database migrations (RLS and triggers already correct)

---

## ESTIMATED EFFORT

- **Remove Navigate Button:** 15 minutes
- **Repository Methods:** 1 hour
- **Provider Methods:** 30 minutes
- **Expense Form Widget:** 2-3 hours
- **Integration in JobProgressScreen:** 1-2 hours
- **Testing & Bug Fixes:** 1-2 hours

**Total:** ~6-8 hours

---

## NOTES

- RLS policies are already correctly configured (drivers can INSERT, managers can approve)
- Database triggers already enforce business rules (no inserts after approval, no updates after approval)
- Expense model is complete and matches database schema
- Approval workflow is already implemented (manager view in JobSummaryScreen)
- Missing piece is entirely the **creation UI** for drivers

