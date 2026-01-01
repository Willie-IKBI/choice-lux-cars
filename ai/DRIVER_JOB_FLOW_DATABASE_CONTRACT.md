# Driver Job Flow - Database Contract

**Generated:** 2025-01-XX  
**Audience:** CLC-ARCH, CLC-BUILD, CLC-REVIEW  
**Purpose:** Database-only contract defining schema, constraints, and enforcement rules for driver job flow features

---

## Table of Contents

1. [Canonical Identity Decision](#canonical-identity-decision)
2. [Expenses Table Definition](#expenses-table-definition)
3. [Immutability Rules After Approval](#immutability-rules-after-approval)
4. [Server-Side Job Closure Enforcement](#server-side-job-closure-enforcement)
5. [RLS Policy Intent](#rls-policy-intent)

---

## Canonical Identity Decision

### Decision: Use `profiles.id` as Canonical User Identity

**Rationale:**
- `profiles` table is the application-level user identity table
- `profiles.id` (UUID) has a foreign key relationship to `auth.users.id`
- All application tables reference `profiles.id` for user relationships
- `auth.users` is the authentication layer and should not be directly referenced by application tables

**Implementation:**
- **All user foreign keys** in application tables MUST reference `profiles.id` (UUID)
- **Never reference `auth.users.id` directly** in application tables
- The relationship is: `auth.users.id` → `profiles.id` → application tables

**Existing Pattern:**
- `jobs.driver_id` → `profiles.id` ✅
- `jobs.manager_id` → `profiles.id` ✅
- `jobs.confirmed_by` → `auth.users.id` ❌ (inconsistent, but may be legacy)
- `jobs.cancelled_by` → `auth.users.id` ❌ (inconsistent, but may be legacy)

**For Expenses Table:**
- `expenses.user` (driver who created expense) → `profiles.id` ✅
- `expenses.approved_by` (manager who approved) → `profiles.id` ✅ (NOT `auth.users.id`)

**Note:** If `jobs.confirmed_by` and `jobs.cancelled_by` currently reference `auth.users.id`, they should be migrated to `profiles.id` for consistency, but this is outside the scope of this contract.

---

## Expenses Table Definition

### Final Schema

**Table Name:** `expenses`

**Purpose:** Tracks job-related expenses with type classification and manager approval workflow.

### Columns

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| `id` | `bigint` | NO | `auto-increment` | Primary key |
| `job_id` | `bigint` | YES | - | Foreign key to `jobs.id` |
| `expense_type` | `text` | NO | - | Expense type: 'fuel', 'parking', 'toll', or 'other' |
| `exp_amount` | `numeric(10,2)` | NO | - | Expense amount (must be > 0) |
| `exp_date` | `timestamptz` | NO | `now()` | Date and time when expense occurred |
| `expense_description` | `text` | YES | - | General expense description |
| `other_description` | `text` | YES | - | Required if `expense_type = 'other'`, optional otherwise |
| `slip_image` | `text` | YES | - | Receipt/slip image URL (Supabase Storage) |
| `expense_location` | `text` | YES | - | Location where expense occurred |
| `user` | `uuid` | NO | - | Driver who created the expense (FK to `profiles.id`) |
| `approved_by` | `uuid` | YES | - | Manager who approved expenses (FK to `profiles.id`) |
| `approved_at` | `timestamptz` | YES | - | Timestamp when expenses were approved |
| `created_at` | `timestamptz` | NO | `now()` | Creation timestamp |
| `updated_at` | `timestamptz` | NO | `now()` | Last update timestamp |

### Primary Key
- `id` (bigint, auto-increment)

### Foreign Keys
- `job_id` → `jobs.id` (ON DELETE CASCADE - if job deleted, expenses deleted)
- `user` → `profiles.id` (ON DELETE RESTRICT - cannot delete profile with expenses)
- `approved_by` → `profiles.id` (ON DELETE SET NULL - if manager deleted, approval info preserved but reference cleared)

### Check Constraints

1. **Expense Type Constraint:**
   ```sql
   CHECK (expense_type IN ('fuel', 'parking', 'toll', 'other'))
   ```

2. **Amount Constraint:**
   ```sql
   CHECK (exp_amount > 0)
   ```

3. **Other Description Required Constraint:**
   ```sql
   CHECK (
     (expense_type = 'other' AND other_description IS NOT NULL AND other_description != '') OR
     (expense_type != 'other')
   )
   ```
   **Rule:** If `expense_type = 'other'`, then `other_description` must be provided (NOT NULL and not empty string).

### Indexes

1. **Job ID Index:**
   ```sql
   CREATE INDEX idx_expenses_job_id ON expenses(job_id);
   ```
   **Purpose:** Fast queries for expenses by job

2. **Approval Status Index:**
   ```sql
   CREATE INDEX idx_expenses_approved ON expenses(approved_by, approved_at) 
   WHERE approved_by IS NOT NULL;
   ```
   **Purpose:** Fast queries for approved expenses, partial index for efficiency

3. **User Index:**
   ```sql
   CREATE INDEX idx_expenses_user ON expenses(user);
   ```
   **Purpose:** Fast queries for expenses by driver

4. **Job and Approval Composite Index:**
   ```sql
   CREATE INDEX idx_expenses_job_approval ON expenses(job_id, approved_by) 
   WHERE approved_by IS NULL;
   ```
   **Purpose:** Fast queries for pending approvals by job

### Column Comments

- `expense_type`: "Type of expense: 'fuel', 'parking', 'toll', or 'other'. 'other' requires other_description."
- `other_description`: "Required description when expense_type is 'other'. Optional for other types."
- `approved_by`: "Manager (from profiles) who approved all expenses for this job. NULL if not yet approved."
- `approved_at`: "Timestamp when manager approved expenses. NULL if not yet approved."

### Data Migration Notes

**For Existing Data:**
- If `user` column is currently `text`, convert to `uuid` using: `ALTER COLUMN user TYPE uuid USING user::uuid;`
- Set default `expense_type = 'other'` for existing records that don't have a type
- Set `other_description = expense_description` for existing records where `expense_type = 'other'` and `other_description` is NULL

---

## Immutability Rules After Approval

### Rule: Expenses Become Immutable After Approval

**Principle:** Once expenses are approved by a manager, they become read-only records. No modifications or deletions are allowed.

### Enforcement Rules

#### 1. Update Restrictions

**After `approved_by` is set (NOT NULL):**
- ❌ **Cannot UPDATE** any column except `updated_at` (automatically maintained by trigger)
- ❌ **Cannot UPDATE** `exp_amount`, `exp_date`, `expense_type`, `expense_description`, `other_description`, `slip_image`, `expense_location`
- ❌ **Cannot UPDATE** `user` (driver who created expense)
- ❌ **Cannot UPDATE** `approved_by` or `approved_at` (approval is final)
- ✅ **Can UPDATE** `updated_at` (automatic trigger only)

**Exception:** System-level operations (service role) may update `updated_at` via triggers, but no application-level updates are permitted.

#### 2. Delete Restrictions

**After `approved_by` is set (NOT NULL):**
- ❌ **Cannot DELETE** the expense record
- ✅ **Can DELETE** only if `approved_by` is NULL (unapproved expenses)

#### 3. Insert Restrictions

**After approval:**
- ✅ **Can INSERT** new expenses for the same job (if job not yet completed, or if job completed but manager hasn't approved yet)
- ❌ **Cannot INSERT** new expenses for a job if all existing expenses are already approved (business rule: approval is final for that approval cycle)

**Note:** The business rule states that approval is "all-or-nothing" per job. Once a manager approves expenses for a job, that approval is final. New expenses added after approval would require a new approval cycle, but this is not currently supported in the workflow.

### Database-Level Enforcement

**Implementation Method:** Database triggers and/or application-level validation

**Recommended Approach:**
1. **Application-level validation** (primary): Check `approved_by IS NULL` before allowing UPDATE or DELETE
2. **Database trigger** (secondary): Prevent UPDATE/DELETE if `approved_by IS NOT NULL` (defense in depth)

**Trigger Logic (if implemented):**
```sql
-- Prevent updates to approved expenses
CREATE TRIGGER prevent_approved_expense_updates
BEFORE UPDATE ON expenses
FOR EACH ROW
WHEN (OLD.approved_by IS NOT NULL)
EXECUTE FUNCTION raise_exception('Cannot update approved expense');

-- Prevent deletion of approved expenses
CREATE TRIGGER prevent_approved_expense_deletes
BEFORE DELETE ON expenses
FOR EACH ROW
WHEN (OLD.approved_by IS NOT NULL)
EXECUTE FUNCTION raise_exception('Cannot delete approved expense');
```

### Business Logic Implications

1. **Driver Actions:**
   - Drivers can create, update, and delete expenses **only before approval**
   - After approval, drivers can only **view** expenses (read-only)

2. **Manager Actions:**
   - Managers can approve expenses (sets `approved_by` and `approved_at`)
   - Managers **cannot** modify approved expenses
   - Managers **cannot** unapprove expenses (approval is final)

3. **System Actions:**
   - System can update `updated_at` via triggers
   - System cannot modify other fields of approved expenses

---

## Server-Side Job Closure Enforcement

### Rule: Jobs Cannot Be Closed Until All Trips Are Completed

**Principle:** A job can only be closed (status changed to 'completed') if all associated trips have been completed.

### Validation Logic

#### 1. Trip Completion Check

**Definition of "All Trips Completed":**
- Count of trips in `transport` table where `job_id = X` = Total trips
- Count of trips in `trip_progress` table where `job_id = X` AND `status = 'completed'` = Completed trips
- **All trips completed** if: `completed_trips = total_trips`

**Edge Cases:**
- If `total_trips = 0` (job has no trips), allow closure (job can be closed immediately)
- If `total_trips > 0` and `completed_trips < total_trips`, prevent closure

#### 2. Database Function: `validate_all_trips_completed`

**Function Signature:**
```sql
validate_all_trips_completed(p_job_id bigint) RETURNS boolean
```

**Logic:**
1. Count total trips: `SELECT COUNT(*) FROM transport WHERE job_id = p_job_id`
2. If count = 0, return `true` (no trips, can close)
3. Count completed trips: `SELECT COUNT(*) FROM trip_progress WHERE job_id = p_job_id AND status = 'completed'`
4. Return `true` if `completed_trips = total_trips`, else `false`

#### 3. Enforcement Points

**Enforcement Method 1: Database Trigger (Recommended)**
- **Trigger:** `BEFORE UPDATE` on `jobs` table
- **Condition:** When `job_status` is being changed to 'completed'
- **Action:** Call `validate_all_trips_completed(job_id)`
- **If false:** Raise exception, prevent update
- **If true:** Allow update

**Enforcement Method 2: Database Function Wrapper**
- Wrap job closure in a function: `close_job(job_id)`
- Function checks `validate_all_trips_completed(job_id)` before updating
- Application must call function instead of direct UPDATE

**Enforcement Method 3: Application-Level Validation (Primary)**
- Application checks `validate_all_trips_completed(job_id)` before calling update
- Database trigger provides defense in depth

**Recommended:** Use Method 3 (application-level) as primary, with Method 1 (trigger) as backup.

### Additional Validation: Job Confirmation

**Rule:** Jobs cannot be started unless confirmed by driver.

**Enforcement:**
- Check `driver_confirm_ind = true` OR `is_confirmed = true` before allowing `job_status = 'started'`
- This is application-level validation (not database constraint, as confirmation is a workflow step)

### Database Function: `get_trip_completion_status`

**Function Signature:**
```sql
get_trip_completion_status(p_job_id bigint) 
RETURNS TABLE(
    total_trips integer,
    completed_trips integer,
    current_trip_index integer,
    all_completed boolean
)
```

**Purpose:** Provide detailed trip completion status for UI and validation.

**Returns:**
- `total_trips`: Count of trips in `transport` table
- `completed_trips`: Count of completed trips in `trip_progress` table
- `current_trip_index`: Current trip index from `driver_flow` table
- `all_completed`: Result of `validate_all_trips_completed(p_job_id)`

### Error Messages

**When closure is attempted with incomplete trips:**
- Database exception: `"Cannot close job. All trips must be completed first. Completed: X of Y trips."`
- Include counts for clarity: `completed_trips` and `total_trips`

---

## RLS Policy Intent

### Overview

**Principle:** Row Level Security (RLS) policies enforce access control at the database level, ensuring users can only access data they are authorized to see or modify.

### Expenses Table RLS Policies

#### Policy Intent (Conceptual, Not SQL)

**1. Drivers Can Manage Their Own Expenses**

**Intent:**
- Drivers can **SELECT, INSERT, UPDATE, DELETE** expenses for jobs where they are the assigned driver
- Access is determined by: `jobs.driver_id = auth.uid()` AND `expenses.job_id = jobs.id`
- Drivers can only manage expenses for jobs assigned to them

**Scope:**
- **SELECT:** View expenses for their assigned jobs
- **INSERT:** Create expenses for their assigned jobs
- **UPDATE:** Modify expenses they created (only if not approved)
- **DELETE:** Delete expenses they created (only if not approved)

**Restrictions:**
- Cannot modify expenses after approval (`approved_by IS NOT NULL`)
- Cannot access expenses for jobs assigned to other drivers
- Cannot approve expenses (approval is manager-only)

**2. Managers Can Approve Expenses**

**Intent:**
- Managers can **SELECT** and **UPDATE** expenses for jobs they manage
- Access is determined by: `jobs.manager_id = auth.uid()` AND `expenses.job_id = jobs.id`
- Managers can only approve expenses after job is completed

**Scope:**
- **SELECT:** View expenses for jobs they manage
- **UPDATE:** Approve expenses (set `approved_by` and `approved_at`) for completed jobs only
- **INSERT:** Cannot create expenses (drivers only)
- **DELETE:** Cannot delete expenses

**Restrictions:**
- Can only approve expenses when `jobs.job_status = 'completed'`
- Cannot modify expense amounts, types, or other details (approval only)
- Cannot approve expenses for jobs they don't manage
- Cannot unapprove expenses (approval is final)

**3. Administrators Have Full Access**

**Intent:**
- Administrators (role = 'administrator' or 'super_admin') can **SELECT, INSERT, UPDATE, DELETE** all expenses
- Access is determined by: User role check in policy
- Administrators can override normal restrictions for administrative purposes

**Scope:**
- **SELECT:** View all expenses
- **INSERT:** Create expenses (administrative override)
- **UPDATE:** Modify any expenses (including approved ones, for corrections)
- **DELETE:** Delete any expenses (for data cleanup)

**Restrictions:**
- Should be used sparingly for administrative corrections
- Should log administrative actions for audit trail

**4. Other Roles Have No Access**

**Intent:**
- Users who are not drivers, managers, or administrators have **no access** to expenses
- Default deny policy for unknown roles

**Scope:**
- **SELECT:** No access
- **INSERT:** No access
- **UPDATE:** No access
- **DELETE:** No access

### Policy Implementation Notes

**Policy Evaluation Order:**
1. Check if user is administrator → Full access
2. Check if user is driver for the job → Driver access
3. Check if user is manager for the job → Manager access
4. Default → No access

**Policy Conflicts:**
- If user is both driver and manager for a job, they get driver permissions (can manage expenses) AND manager permissions (can approve)
- This is acceptable as it provides maximum flexibility

**Approval Workflow Enforcement:**
- RLS policies do NOT enforce the "job must be completed before approval" rule
- This is enforced by the `approve_job_expenses()` function logic
- RLS policies only control WHO can approve, not WHEN

**Immutability Enforcement:**
- RLS policies do NOT enforce immutability after approval
- This is enforced by application logic and/or database triggers
- RLS policies control access, not business rules

### Related Tables RLS Context

**Jobs Table:**
- Drivers can SELECT jobs assigned to them
- Managers can SELECT jobs they manage
- Administrators can SELECT all jobs
- This affects expense access indirectly (via job relationship)

**Profiles Table:**
- Users can SELECT their own profile
- Administrators can SELECT all profiles
- This affects expense access for user identification (driver name, manager name)

---

## Summary

### Key Decisions

1. **Identity:** Use `profiles.id` (UUID) as canonical user identity, not `auth.users.id`
2. **Expenses Schema:** Complete table definition with all constraints and indexes
3. **Immutability:** Approved expenses are read-only (no updates or deletes)
4. **Job Closure:** Server-side validation prevents closure until all trips completed
5. **RLS Policies:** Role-based access control with clear intent for each user type

### Enforcement Layers

1. **Database Constraints:** CHECK constraints, foreign keys, triggers
2. **Database Functions:** Validation functions, approval functions
3. **RLS Policies:** Access control at row level
4. **Application Logic:** Business rule validation (primary enforcement)

### Next Steps

1. Create migration files based on this contract
2. Implement database functions for validation and approval
3. Implement RLS policies according to intent
4. Test all constraints and policies
5. Document any deviations from this contract

---

## PATCH: Clarifications and Corrections

### PATCH 1: Clarify profiles.id Relationship to auth.uid()

**Location:** Section "Canonical Identity Decision", after line 32

**Add after line 32:**
```
**Critical Clarification:**
- `profiles.id` MUST equal `auth.users.id` for all authenticated users
- The relationship is 1:1: `profiles.id = auth.users.id` (same UUID value)
- `profiles.id` is a foreign key to `auth.users.id`, meaning they are the same value
- When checking user identity in RLS policies, use `auth.uid()` which returns the same UUID as `profiles.id`
- In application code, `auth.uid()` and `profiles.id` refer to the same user identity
```

**Rationale:** Removes ambiguity about whether profiles.id and auth.uid() are the same value (they are).

---

### PATCH 2: Change expenses.job_id to NOT NULL

**Location:** Section "Expenses Table Definition", line 61

**Change:**
- **FROM:** `| `job_id` | `bigint` | YES | - | Foreign key to `jobs.id` |`
- **TO:** `| `job_id` | `bigint` | NO | - | Foreign key to `jobs.id` |`

**Update Foreign Keys section (line 79):**
- **FROM:** `- `job_id` → `jobs.id` (ON DELETE CASCADE - if job deleted, expenses deleted)`
- **TO:** `- `job_id` → `jobs.id` (NOT NULL, ON DELETE CASCADE - if job deleted, expenses deleted)`

**Rationale:** Expenses must always be associated with a job. No orphaned expenses allowed.

---

### PATCH 3: Define Approval Method (RPC vs Direct UPDATE)

**Location:** Section "Immutability Rules After Approval", after line 179

**Add new subsection after line 179:**

```
#### 4. Approval Method: RPC Function Required

**Rule:** Expense approvals MUST go through the `approve_job_expenses()` RPC function. Direct UPDATE statements are NOT permitted for approval.

**Enforcement:**
- **Application MUST call:** `SELECT approve_job_expenses(job_id, manager_id)`
- **Application MUST NOT:** Direct UPDATE to set `approved_by` and `approved_at`
- **Database trigger:** Prevent direct UPDATE of `approved_by` or `approved_at` columns (defense in depth)

**Rationale:**
- RPC function enforces business rules (job must be completed, bulk approval)
- RPC function ensures atomicity (all expenses approved in single transaction)
- RPC function provides audit trail and validation
- Direct UPDATE bypasses validation and can cause data inconsistency

**Exception:**
- Administrators may use direct UPDATE for approved expenses ONLY through service role (bypasses RLS and triggers)
- Administrative updates must be logged separately for audit purposes
```

**Update "Database-Level Enforcement" section (line 185):**
- **Add:** "Approval operations must use `approve_job_expenses()` RPC function. Direct UPDATE of `approved_by` or `approved_at` is blocked by trigger."

---

### PATCH 4: Define Enforcement for 'No Inserts After Approval'

**Location:** Section "Immutability Rules After Approval", subsection "Insert Restrictions" (line 173)

**Replace lines 173-179 with:**

```
#### 3. Insert Restrictions

**Rule:** New expenses cannot be inserted for a job if that job has any approved expenses.

**Enforcement Logic:**
- Before INSERT, check if job has any expenses where `approved_by IS NOT NULL`
- If ANY expense for the job is approved, prevent INSERT of new expenses
- If NO expenses are approved (all `approved_by IS NULL`), allow INSERT

**Database-Level Enforcement:**
- **Trigger:** `BEFORE INSERT` on `expenses` table
- **Condition:** Check if job has approved expenses: `EXISTS (SELECT 1 FROM expenses WHERE job_id = NEW.job_id AND approved_by IS NOT NULL)`
- **Action:** If condition is true, raise exception: "Cannot add expenses to job with approved expenses. Approval is final."
- **Exception:** Administrators (service role) can bypass this restriction for administrative corrections

**Application-Level Enforcement:**
- Application must check approval status before allowing expense creation
- UI should disable "Add Expense" button if job has approved expenses
- Application should show clear message: "Cannot add expenses. Job expenses have been approved."

**Business Rule:**
- Approval is "all-or-nothing" per job
- Once ANY expense is approved, the approval cycle is complete
- New expenses require a new approval cycle (not currently supported in workflow)
- This prevents partial approvals and maintains data integrity
```

---

### PATCH 5: Define Admin Override Rules and Audit Expectation

**Location:** Section "RLS Policy Intent", subsection "3. Administrators Have Full Access" (line 359)

**Replace lines 359-374 with:**

```
**3. Administrators Have Full Access**

**Intent:**
- Administrators (role = 'administrator' or 'super_admin') can **SELECT, INSERT, UPDATE, DELETE** all expenses
- Access is determined by: User role check in policy (`profiles.role IN ('administrator', 'super_admin')`)
- Administrators can override normal restrictions for administrative corrections

**Scope:**
- **SELECT:** View all expenses (no restrictions)
- **INSERT:** Create expenses for any job (bypasses "no inserts after approval" rule)
- **UPDATE:** Modify any expenses, including approved ones (bypasses immutability rule)
- **DELETE:** Delete any expenses, including approved ones (bypasses delete restriction)

**Override Rules:**
1. **Approved Expense Modifications:**
   - Administrators CAN update approved expenses (amount, type, description, etc.)
   - Administrators CAN delete approved expenses
   - This is for data corrections and error fixes only

2. **Insert After Approval:**
   - Administrators CAN insert new expenses even if job has approved expenses
   - This is for adding missing expenses that should have been included

3. **Approval Override:**
   - Administrators CAN directly UPDATE `approved_by` and `approved_at` (bypasses RPC requirement)
   - Administrators CAN unapprove expenses (set `approved_by = NULL, approved_at = NULL`)
   - This is for correcting approval errors

**Audit Expectation:**
- **ALL administrative overrides MUST be logged** in an audit table or log
- **Required audit fields:**
  - `action_type`: 'admin_expense_update', 'admin_expense_delete', 'admin_expense_insert', 'admin_expense_approval_override'
  - `expense_id`: ID of affected expense (or job_id for bulk operations)
  - `admin_user_id`: Administrator who performed the action (`profiles.id`)
  - `action_timestamp`: When the action occurred
  - `previous_values`: JSONB snapshot of values before change (for UPDATE/DELETE)
  - `new_values`: JSONB snapshot of values after change (for UPDATE/INSERT)
  - `reason`: Text field explaining why administrative override was necessary

**Audit Table (Recommended):**
- Table name: `expense_audit_log` or add to general `audit_log` table
- Must be created and populated for all administrative expense operations
- RLS policies should allow administrators to view audit logs
- Audit logs are immutable (no updates or deletes)

**Restrictions:**
- Administrative overrides should be used **sparingly** and only for legitimate corrections
- Each override must have a documented reason
- Audit trail must be complete and searchable
- Regular review of audit logs should be conducted to ensure proper use
```

**Add new subsection after "Policy Implementation Notes" (after line 408):**

```
**Administrative Override Enforcement:**
- RLS policies allow administrators full access
- Database triggers should check for service role or administrator role before blocking
- Application should require additional confirmation for administrative overrides
- Audit logging should be automatic and cannot be bypassed
```

---

## PATCH: Clarifications and Corrections

This section lists exact edits to remove ambiguity in the database contract.

### PATCH 1: Clarify profiles.id Relationship to auth.uid()

**Location:** Section "Canonical Identity Decision", after line 32

**Action:** Add new paragraph after line 32

**Content to Add:**
```
**Critical Clarification:**
- `profiles.id` MUST equal `auth.users.id` for all authenticated users
- The relationship is 1:1: `profiles.id = auth.users.id` (same UUID value)
- `profiles.id` is a foreign key to `auth.users.id`, meaning they are the same value
- When checking user identity in RLS policies, use `auth.uid()` which returns the same UUID as `profiles.id`
- In application code, `auth.uid()` and `profiles.id` refer to the same user identity
```

---

### PATCH 2: Change expenses.job_id to NOT NULL

**Location:** Section "Expenses Table Definition", line 61

**Action 1:** Change column definition
- **FROM:** `| `job_id` | `bigint` | YES | - | Foreign key to `jobs.id` |`
- **TO:** `| `job_id` | `bigint` | NO | - | Foreign key to `jobs.id` |`

**Action 2:** Update Foreign Keys section (line 79)
- **FROM:** `- `job_id` → `jobs.id` (ON DELETE CASCADE - if job deleted, expenses deleted)`
- **TO:** `- `job_id` → `jobs.id` (NOT NULL, ON DELETE CASCADE - if job deleted, expenses deleted)`

---

### PATCH 3: Define Approval Method (RPC vs Direct UPDATE)

**Location:** Section "Immutability Rules After Approval", after line 179

**Action:** Add new subsection "4. Approval Method: RPC Function Required"

**Content to Add:**
```
#### 4. Approval Method: RPC Function Required

**Rule:** Expense approvals MUST go through the `approve_job_expenses()` RPC function. Direct UPDATE statements are NOT permitted for approval.

**Enforcement:**
- **Application MUST call:** `SELECT approve_job_expenses(job_id, manager_id)`
- **Application MUST NOT:** Direct UPDATE to set `approved_by` and `approved_at`
- **Database trigger:** Prevent direct UPDATE of `approved_by` or `approved_at` columns (defense in depth)

**Rationale:**
- RPC function enforces business rules (job must be completed, bulk approval)
- RPC function ensures atomicity (all expenses approved in single transaction)
- RPC function provides audit trail and validation
- Direct UPDATE bypasses validation and can cause data inconsistency

**Exception:**
- Administrators may use direct UPDATE for approved expenses ONLY through service role (bypasses RLS and triggers)
- Administrative updates must be logged separately for audit purposes
```

**Action 2:** Update "Database-Level Enforcement" section (line 185)
- **Add sentence:** "Approval operations must use `approve_job_expenses()` RPC function. Direct UPDATE of `approved_by` or `approved_at` is blocked by trigger."

---

### PATCH 4: Define Enforcement for 'No Inserts After Approval'

**Location:** Section "Immutability Rules After Approval", subsection "Insert Restrictions" (line 173)

**Action:** Replace entire subsection (lines 173-179)

**Replace WITH:**
```
#### 3. Insert Restrictions

**Rule:** New expenses cannot be inserted for a job if that job has any approved expenses.

**Enforcement Logic:**
- Before INSERT, check if job has any expenses where `approved_by IS NOT NULL`
- If ANY expense for the job is approved, prevent INSERT of new expenses
- If NO expenses are approved (all `approved_by IS NULL`), allow INSERT

**Database-Level Enforcement:**
- **Trigger:** `BEFORE INSERT` on `expenses` table
- **Condition:** Check if job has approved expenses: `EXISTS (SELECT 1 FROM expenses WHERE job_id = NEW.job_id AND approved_by IS NOT NULL)`
- **Action:** If condition is true, raise exception: "Cannot add expenses to job with approved expenses. Approval is final."
- **Exception:** Administrators (service role) can bypass this restriction for administrative corrections

**Application-Level Enforcement:**
- Application must check approval status before allowing expense creation
- UI should disable "Add Expense" button if job has approved expenses
- Application should show clear message: "Cannot add expenses. Job expenses have been approved."

**Business Rule:**
- Approval is "all-or-nothing" per job
- Once ANY expense is approved, the approval cycle is complete
- New expenses require a new approval cycle (not currently supported in workflow)
- This prevents partial approvals and maintains data integrity
```

---

### PATCH 5: Define Admin Override Rules and Audit Expectation

**Location:** Section "RLS Policy Intent", subsection "3. Administrators Have Full Access" (line 359)

**Action 1:** Replace entire subsection (lines 359-374)

**Replace WITH:**
```
**3. Administrators Have Full Access**

**Intent:**
- Administrators (role = 'administrator' or 'super_admin') can **SELECT, INSERT, UPDATE, DELETE** all expenses
- Access is determined by: User role check in policy (`profiles.role IN ('administrator', 'super_admin')`)
- Administrators can override normal restrictions for administrative corrections

**Scope:**
- **SELECT:** View all expenses (no restrictions)
- **INSERT:** Create expenses for any job (bypasses "no inserts after approval" rule)
- **UPDATE:** Modify any expenses, including approved ones (bypasses immutability rule)
- **DELETE:** Delete any expenses, including approved ones (bypasses delete restriction)

**Override Rules:**
1. **Approved Expense Modifications:**
   - Administrators CAN update approved expenses (amount, type, description, etc.)
   - Administrators CAN delete approved expenses
   - This is for data corrections and error fixes only

2. **Insert After Approval:**
   - Administrators CAN insert new expenses even if job has approved expenses
   - This is for adding missing expenses that should have been included

3. **Approval Override:**
   - Administrators CAN directly UPDATE `approved_by` and `approved_at` (bypasses RPC requirement)
   - Administrators CAN unapprove expenses (set `approved_by = NULL, approved_at = NULL`)
   - This is for correcting approval errors

**Audit Expectation:**
- **ALL administrative overrides MUST be logged** in an audit table or log
- **Required audit fields:**
  - `action_type`: 'admin_expense_update', 'admin_expense_delete', 'admin_expense_insert', 'admin_expense_approval_override'
  - `expense_id`: ID of affected expense (or job_id for bulk operations)
  - `admin_user_id`: Administrator who performed the action (`profiles.id`)
  - `action_timestamp`: When the action occurred
  - `previous_values`: JSONB snapshot of values before change (for UPDATE/DELETE)
  - `new_values`: JSONB snapshot of values after change (for UPDATE/INSERT)
  - `reason`: Text field explaining why administrative override was necessary

**Audit Table (Recommended):**
- Table name: `expense_audit_log` or add to general `audit_log` table
- Must be created and populated for all administrative expense operations
- RLS policies should allow administrators to view audit logs
- Audit logs are immutable (no updates or deletes)

**Restrictions:**
- Administrative overrides should be used **sparingly** and only for legitimate corrections
- Each override must have a documented reason
- Audit trail must be complete and searchable
- Regular review of audit logs should be conducted to ensure proper use
```

**Action 2:** Add new subsection after "Policy Implementation Notes" (after line 408)

**Add:**
```
**Administrative Override Enforcement:**
- RLS policies allow administrators full access
- Database triggers should check for service role or administrator role before blocking
- Application should require additional confirmation for administrative overrides
- Audit logging should be automatic and cannot be bypassed
```

---

**Document Status:** Database Contract - Ready for Implementation  
**Last Updated:** 2025-01-XX (PATCH Applied)  
**Next Steps:** Create migration files implementing this contract

