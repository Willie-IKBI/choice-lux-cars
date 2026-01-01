# Driver Job Flow - Step 1 Migration Checklist

**Generated:** 2025-01-XX  
**Audience:** CLC-ARCH, CLC-BUILD, CLC-REVIEW  
**Purpose:** Ordered migration plan with operations, rollback notes, and test checklists

**Based on:** `ai/DRIVER_JOB_FLOW_DATABASE_CONTRACT.md` (with PATCH 1-5 applied)

---

## Migration Order

Migrations must be executed in this exact order. Each migration builds on the previous one.

1. **202501XX000001_expenses_schema_enhancements.sql** - Schema changes (columns, constraints, indexes)
2. **202501XX000002_expenses_data_migration.sql** - Data migration for existing records
3. **202501XX000003_expense_approval_functions.sql** - RPC functions for expense approval
4. **202501XX000004_trip_validation_functions.sql** - Functions for trip completion validation
5. **202501XX000005_expense_immutability_triggers.sql** - Triggers for approved expense protection
6. **202501XX000006_job_closure_validation_trigger.sql** - Trigger for job closure validation
7. **202501XX000007_expenses_rls_policies.sql** - RLS policies for expenses table
8. **202501XX000008_expense_audit_log_table.sql** - Audit log table for admin overrides (optional but recommended)

---

## Migration 1: expenses_schema_enhancements.sql

**Purpose:** Add new columns, constraints, and indexes to expenses table

### Operations

1. **ALTER TABLE expenses - Add expense_type column**
   - Add column: `expense_type text NOT NULL`
   - Add CHECK constraint: `expense_type IN ('fuel', 'parking', 'toll', 'other')`
   - Add column comment

2. **ALTER TABLE expenses - Add approval columns**
   - Add column: `approved_by uuid` (nullable)
   - Add column: `approved_at timestamptz` (nullable)
   - Add column comments

3. **ALTER TABLE expenses - Change job_id to NOT NULL**
   - Check if any NULL job_id values exist (should fail if found)
   - ALTER COLUMN job_id SET NOT NULL
   - Update foreign key constraint description

4. **ALTER TABLE expenses - Convert user column to UUID**
   - Check current type of `user` column
   - If text, convert to uuid: `ALTER COLUMN user TYPE uuid USING user::uuid`
   - If already uuid, skip conversion

5. **ALTER TABLE expenses - Add foreign key constraints**
   - Add FK: `user` → `profiles.id` (ON DELETE RESTRICT)
   - Add FK: `approved_by` → `profiles.id` (ON DELETE SET NULL)
   - Verify existing FK: `job_id` → `jobs.id` (ON DELETE CASCADE)

6. **ALTER TABLE expenses - Add CHECK constraints**
   - Add constraint: `exp_amount > 0`
   - Add constraint: `(expense_type = 'other' AND other_description IS NOT NULL AND other_description != '') OR (expense_type != 'other')`

7. **CREATE INDEX operations**
   - Create index: `idx_expenses_job_id` on `expenses(job_id)`
   - Create index: `idx_expenses_approved` on `expenses(approved_by, approved_at)` WHERE `approved_by IS NOT NULL` (partial index)
   - Create index: `idx_expenses_user` on `expenses(user)`
   - Create index: `idx_expenses_job_approval` on `expenses(job_id, approved_by)` WHERE `approved_by IS NULL` (partial index)

8. **COMMENT operations**
   - Add comment on `expense_type` column
   - Add comment on `other_description` column
   - Add comment on `approved_by` column
   - Add comment on `approved_at` column

### Rollback Notes

**Rollback Steps:**
1. DROP all indexes created in this migration
2. DROP all CHECK constraints added
3. DROP foreign key constraints added
4. ALTER COLUMN `user` back to text (if converted) - requires data conversion
5. ALTER COLUMN `job_id` back to nullable (if changed)
6. DROP columns: `approved_at`, `approved_by`, `expense_type`

**Data Loss Risk:** Medium
- Converting `user` from text to uuid may fail if invalid UUIDs exist
- Setting `job_id` to NOT NULL will fail if NULL values exist
- Must handle existing data before rollback

**Rollback Migration File:** `202501XX000001_expenses_schema_enhancements_rollback.sql`

### Test Checklist

**Pre-Migration Tests:**
- [ ] Query: `SELECT COUNT(*) FROM expenses WHERE job_id IS NULL` - Should return 0 or handle existing NULLs
- [ ] Query: `SELECT COUNT(*) FROM expenses WHERE user IS NOT NULL AND user !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'` - Check for invalid UUIDs in user column
- [ ] Query: `SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'expenses' AND column_name = 'user'` - Verify current user column type

**Post-Migration Tests:**
- [ ] Query: `SELECT column_name, is_nullable, data_type FROM information_schema.columns WHERE table_name = 'expenses' AND column_name IN ('expense_type', 'approved_by', 'approved_at', 'job_id', 'user')` - Verify all columns exist with correct types and nullability
- [ ] Query: `SELECT constraint_name, constraint_type FROM information_schema.table_constraints WHERE table_name = 'expenses' AND constraint_type = 'CHECK'` - Verify CHECK constraints exist
- [ ] Query: `SELECT indexname FROM pg_indexes WHERE tablename = 'expenses' AND indexname LIKE 'idx_expenses_%'` - Verify all indexes created
- [ ] Test: Insert expense with `expense_type = 'fuel'` - Should succeed
- [ ] Test: Insert expense with `expense_type = 'invalid'` - Should fail with CHECK constraint error
- [ ] Test: Insert expense with `expense_type = 'other'` and `other_description = NULL` - Should fail with CHECK constraint error
- [ ] Test: Insert expense with `expense_type = 'other'` and `other_description = ''` - Should fail with CHECK constraint error
- [ ] Test: Insert expense with `exp_amount = 0` - Should fail with CHECK constraint error
- [ ] Test: Insert expense with `exp_amount = -10` - Should fail with CHECK constraint error
- [ ] Test: Insert expense with `job_id = NULL` - Should fail with NOT NULL constraint error

---

## Migration 2: expenses_data_migration.sql

**Purpose:** Migrate existing expense data to new schema requirements

### Operations

1. **Data migration for expense_type**
   - UPDATE all expenses where `expense_type IS NULL` SET `expense_type = 'other'`
   - This sets default for existing records

2. **Data migration for other_description**
   - UPDATE expenses where `expense_type = 'other'` AND `other_description IS NULL` SET `other_description = expense_description`
   - Copies existing description to other_description for 'other' type expenses

3. **Data validation**
   - Verify no expenses have NULL expense_type after migration
   - Verify all 'other' type expenses have non-empty other_description

### Rollback Notes

**Rollback Steps:**
1. UPDATE expenses where `expense_type = 'other'` AND `other_description = expense_description` SET `other_description = NULL` (if we can identify migrated records)
2. UPDATE expenses SET `expense_type = NULL` where `expense_type = 'other'` (if we can identify migrated records)

**Data Loss Risk:** Low
- Only sets defaults, doesn't delete data
- May lose distinction between originally 'other' vs migrated 'other' expenses

**Rollback Migration File:** `202501XX000002_expenses_data_migration_rollback.sql`

### Test Checklist

**Pre-Migration Tests:**
- [ ] Query: `SELECT COUNT(*) FROM expenses WHERE expense_type IS NULL` - Count records needing migration
- [ ] Query: `SELECT COUNT(*) FROM expenses WHERE expense_type = 'other' AND (other_description IS NULL OR other_description = '')` - Count records needing other_description

**Post-Migration Tests:**
- [ ] Query: `SELECT COUNT(*) FROM expenses WHERE expense_type IS NULL` - Should return 0
- [ ] Query: `SELECT COUNT(*) FROM expenses WHERE expense_type = 'other' AND (other_description IS NULL OR other_description = '')` - Should return 0
- [ ] Query: `SELECT expense_type, COUNT(*) FROM expenses GROUP BY expense_type` - Verify expense_type distribution
- [ ] Query: `SELECT * FROM expenses WHERE expense_type = 'other' LIMIT 5` - Verify other_description populated

---

## Migration 3: expense_approval_functions.sql

**Purpose:** Create RPC functions for expense approval workflow

### Operations

1. **CREATE FUNCTION: approve_job_expenses**
   - Function signature: `approve_job_expenses(p_job_id bigint, p_manager_id uuid) RETURNS void`
   - Security: SECURITY DEFINER
   - Logic:
     - Verify job exists and `job_status = 'completed'`
     - If job not completed, raise exception
     - UPDATE all expenses for job where `approved_by IS NULL` SET `approved_by = p_manager_id`, `approved_at = NOW()`, `updated_at = NOW()`
     - Log action (RAISE NOTICE)
   - Grant EXECUTE to authenticated role

2. **CREATE FUNCTION: get_job_expenses_summary**
   - Function signature: `get_job_expenses_summary(p_job_id bigint) RETURNS TABLE(...)`
   - Security: SECURITY DEFINER
   - Returns: `total_expenses`, `approved_expenses`, `pending_expenses`, `expense_count`, `is_approved`
   - Logic:
     - Calculate total expenses amount
     - Calculate approved expenses amount (where approved_by IS NOT NULL)
     - Calculate pending expenses amount (where approved_by IS NULL)
     - Count total expenses
     - Check if all expenses approved (BOOL_AND)
   - Grant EXECUTE to authenticated role

### Rollback Notes

**Rollback Steps:**
1. REVOKE EXECUTE on functions from authenticated role
2. DROP FUNCTION `get_job_expenses_summary`
3. DROP FUNCTION `approve_job_expenses`

**Data Loss Risk:** None
- Functions don't modify data structure
- Only removes function definitions

**Rollback Migration File:** `202501XX000003_expense_approval_functions_rollback.sql`

### Test Checklist

**Post-Migration Tests:**
- [ ] Query: `SELECT routine_name FROM information_schema.routines WHERE routine_name IN ('approve_job_expenses', 'get_job_expenses_summary')` - Verify functions exist
- [ ] Test: Call `approve_job_expenses(job_id, manager_id)` where job_status = 'completed' - Should succeed
- [ ] Test: Call `approve_job_expenses(job_id, manager_id)` where job_status != 'completed' - Should fail with exception
- [ ] Test: Call `get_job_expenses_summary(job_id)` - Should return summary with correct totals
- [ ] Test: Verify `approved_by` and `approved_at` are set after calling approve_job_expenses
- [ ] Test: Verify only unapproved expenses are updated (approved_by IS NULL check)
- [ ] Test: Verify function handles job with no expenses (should return zeros)

---

## Migration 4: trip_validation_functions.sql

**Purpose:** Create functions to validate trip completion for job closure

### Operations

1. **CREATE FUNCTION: validate_all_trips_completed**
   - Function signature: `validate_all_trips_completed(p_job_id bigint) RETURNS boolean`
   - Security: SECURITY DEFINER
   - Logic:
     - Count total trips from `transport` table where `job_id = p_job_id`
     - If count = 0, return `true` (no trips, can close)
     - Count completed trips from `trip_progress` table where `job_id = p_job_id` AND `status = 'completed'`
     - Return `true` if `completed_trips = total_trips`, else `false`
   - Grant EXECUTE to authenticated role

2. **CREATE FUNCTION: get_trip_completion_status**
   - Function signature: `get_trip_completion_status(p_job_id bigint) RETURNS TABLE(...)`
   - Security: SECURITY DEFINER
   - Returns: `total_trips`, `completed_trips`, `current_trip_index`, `all_completed`
   - Logic:
     - Get total trips count from `transport` table
     - Get completed trips count from `trip_progress` table
     - Get current_trip_index from `driver_flow` table
     - Call `validate_all_trips_completed(p_job_id)` for all_completed boolean
   - Grant EXECUTE to authenticated role

### Rollback Notes

**Rollback Steps:**
1. REVOKE EXECUTE on functions from authenticated role
2. DROP FUNCTION `get_trip_completion_status`
3. DROP FUNCTION `validate_all_trips_completed`

**Data Loss Risk:** None
- Functions are read-only (validation only)
- No data structure changes

**Rollback Migration File:** `202501XX000004_trip_validation_functions_rollback.sql`

### Test Checklist

**Post-Migration Tests:**
- [ ] Query: `SELECT routine_name FROM information_schema.routines WHERE routine_name IN ('validate_all_trips_completed', 'get_trip_completion_status')` - Verify functions exist
- [ ] Test: Call `validate_all_trips_completed(job_id)` for job with no trips - Should return `true`
- [ ] Test: Call `validate_all_trips_completed(job_id)` for job with 3 trips, all completed - Should return `true`
- [ ] Test: Call `validate_all_trips_completed(job_id)` for job with 3 trips, only 2 completed - Should return `false`
- [ ] Test: Call `get_trip_completion_status(job_id)` - Should return correct counts and status
- [ ] Test: Verify function handles non-existent job_id gracefully

---

## Migration 5: expense_immutability_triggers.sql

**Purpose:** Create triggers to enforce immutability of approved expenses

### Operations

1. **CREATE FUNCTION: prevent_approved_expense_update**
   - Function signature: `prevent_approved_expense_update() RETURNS trigger`
   - Security: SECURITY DEFINER
   - Logic:
     - Check if OLD.approved_by IS NOT NULL
     - If approved, check if attempting to update approved_by or approved_at directly (not via RPC)
     - If updating approved_by/approved_at directly, raise exception (unless service role)
     - If updating any other column (except updated_at), raise exception (unless service role or administrator)
     - Allow updated_at changes (automatic trigger updates)
   - Grant EXECUTE to authenticated role

2. **CREATE FUNCTION: prevent_approved_expense_delete**
   - Function signature: `prevent_approved_expense_delete() RETURNS trigger`
   - Security: SECURITY DEFINER
   - Logic:
     - Check if OLD.approved_by IS NOT NULL
     - If approved, raise exception (unless service role or administrator)
     - Allow deletion if approved_by IS NULL
   - Grant EXECUTE to authenticated role

3. **CREATE FUNCTION: prevent_expense_insert_after_approval**
   - Function signature: `prevent_expense_insert_after_approval() RETURNS trigger`
   - Security: SECURITY DEFINER
   - Logic:
     - Check if job has any expenses where approved_by IS NOT NULL
     - If ANY expense is approved, raise exception (unless service role or administrator)
     - Allow insert if no approved expenses exist for the job
   - Grant EXECUTE to authenticated role

4. **CREATE FUNCTION: prevent_direct_approval_update**
   - Function signature: `prevent_direct_approval_update() RETURNS trigger`
   - Security: SECURITY DEFINER
   - Logic:
     - Check if NEW.approved_by or NEW.approved_at is being set/changed
     - If OLD.approved_by IS NULL and NEW.approved_by IS NOT NULL, this is an approval attempt
     - Raise exception: "Expense approvals must use approve_job_expenses() RPC function"
     - Exception: Allow if service role or administrator (for admin overrides)
   - Grant EXECUTE to authenticated role

5. **CREATE TRIGGER: trigger_prevent_approved_expense_update**
   - Trigger: BEFORE UPDATE on expenses
   - Function: prevent_approved_expense_update
   - When: FOR EACH ROW

6. **CREATE TRIGGER: trigger_prevent_approved_expense_delete**
   - Trigger: BEFORE DELETE on expenses
   - Function: prevent_approved_expense_delete
   - When: FOR EACH ROW

7. **CREATE TRIGGER: trigger_prevent_expense_insert_after_approval**
   - Trigger: BEFORE INSERT on expenses
   - Function: prevent_expense_insert_after_approval
   - When: FOR EACH ROW

8. **CREATE TRIGGER: trigger_prevent_direct_approval_update**
   - Trigger: BEFORE UPDATE on expenses
   - Function: prevent_direct_approval_update
   - When: FOR EACH ROW

### Rollback Notes

**Rollback Steps:**
1. DROP TRIGGER `trigger_prevent_direct_approval_update`
2. DROP TRIGGER `trigger_prevent_expense_insert_after_approval`
3. DROP TRIGGER `trigger_prevent_approved_expense_delete`
4. DROP TRIGGER `trigger_prevent_approved_expense_update`
5. DROP FUNCTION `prevent_direct_approval_update`
6. DROP FUNCTION `prevent_expense_insert_after_approval`
7. DROP FUNCTION `prevent_approved_expense_delete`
8. DROP FUNCTION `prevent_approved_expense_update`

**Data Loss Risk:** None
- Triggers only prevent operations, don't modify data
- Removing triggers restores previous behavior

**Rollback Migration File:** `202501XX000005_expense_immutability_triggers_rollback.sql`

### Test Checklist

**Post-Migration Tests:**
- [ ] Query: `SELECT trigger_name FROM information_schema.triggers WHERE event_object_table = 'expenses'` - Verify all triggers exist
- [ ] Test: UPDATE approved expense (approved_by IS NOT NULL) - Should fail with exception
- [ ] Test: DELETE approved expense (approved_by IS NOT NULL) - Should fail with exception
- [ ] Test: UPDATE unapproved expense (approved_by IS NULL) - Should succeed
- [ ] Test: DELETE unapproved expense (approved_by IS NULL) - Should succeed
- [ ] Test: INSERT expense for job with approved expenses - Should fail with exception
- [ ] Test: INSERT expense for job with no approved expenses - Should succeed
- [ ] Test: Direct UPDATE to set approved_by (not via RPC) - Should fail with exception
- [ ] Test: Direct UPDATE to set approved_at (not via RPC) - Should fail with exception
- [ ] Test: UPDATE approved expense via service role - Should succeed (admin override)
- [ ] Test: Verify updated_at can still be updated by triggers (automatic)

---

## Migration 6: job_closure_validation_trigger.sql

**Purpose:** Create trigger to prevent job closure until all trips are completed

### Operations

1. **CREATE FUNCTION: validate_job_closure**
   - Function signature: `validate_job_closure() RETURNS trigger`
   - Security: SECURITY DEFINER
   - Logic:
     - Check if NEW.job_status = 'completed' AND OLD.job_status != 'completed'
     - If status changing to 'completed', call `validate_all_trips_completed(NEW.id)`
     - If function returns `false`, raise exception with message including trip counts
     - If function returns `true`, allow update
     - If status not changing to 'completed', allow update
   - Grant EXECUTE to authenticated role

2. **CREATE TRIGGER: trigger_validate_job_closure**
   - Trigger: BEFORE UPDATE on jobs
   - Function: validate_job_closure
   - When: FOR EACH ROW

### Rollback Notes

**Rollback Steps:**
1. DROP TRIGGER `trigger_validate_job_closure`
2. DROP FUNCTION `validate_job_closure`

**Data Loss Risk:** None
- Trigger only prevents invalid updates
- Removing trigger restores previous behavior

**Rollback Migration File:** `202501XX000006_job_closure_validation_trigger_rollback.sql`

### Test Checklist

**Post-Migration Tests:**
- [ ] Query: `SELECT trigger_name FROM information_schema.triggers WHERE event_object_table = 'jobs' AND trigger_name = 'trigger_validate_job_closure'` - Verify trigger exists
- [ ] Test: UPDATE job_status to 'completed' where all trips completed - Should succeed
- [ ] Test: UPDATE job_status to 'completed' where some trips incomplete - Should fail with exception
- [ ] Test: UPDATE job_status to 'completed' where job has no trips - Should succeed
- [ ] Test: UPDATE job_status to 'in_progress' (not 'completed') - Should succeed (no validation)
- [ ] Test: UPDATE other job fields (not status) - Should succeed (no validation)
- [ ] Test: Verify error message includes trip counts (completed X of Y)

---

## Migration 7: expenses_rls_policies.sql

**Purpose:** Create RLS policies for expenses table access control

### Operations

1. **Enable RLS on expenses table** (if not already enabled)
   - ALTER TABLE expenses ENABLE ROW LEVEL SECURITY

2. **DROP existing policies** (if any exist that conflict)
   - DROP POLICY IF EXISTS "Allow authenticated access to expenses" (or similar)
   - Note: Check for existing policy names first

3. **CREATE POLICY: Drivers can manage their own expenses**
   - Policy name: "drivers_manage_own_expenses"
   - Operation: ALL (SELECT, INSERT, UPDATE, DELETE)
   - Using clause: Check if `jobs.driver_id = auth.uid()` AND `expenses.job_id = jobs.id`
   - With check clause: Same as using clause for INSERT/UPDATE
   - Description: Drivers can manage expenses for jobs assigned to them

4. **CREATE POLICY: Managers can approve expenses**
   - Policy name: "managers_approve_expenses"
   - Operation: SELECT, UPDATE
   - Using clause: Check if `jobs.manager_id = auth.uid()` AND `expenses.job_id = jobs.id`
   - With check clause: For UPDATE, verify job is completed (`jobs.job_status = 'completed'`)
   - Description: Managers can view and approve expenses for jobs they manage

5. **CREATE POLICY: Administrators have full access**
   - Policy name: "administrators_full_expense_access"
   - Operation: ALL (SELECT, INSERT, UPDATE, DELETE)
   - Using clause: Check if `profiles.role IN ('administrator', 'super_admin')` AND `profiles.id = auth.uid()`
   - With check clause: Same as using clause
   - Description: Administrators can access all expenses

6. **CREATE POLICY: Default deny (implicit)**
   - Note: Default deny is implicit in RLS - no explicit policy needed
   - Users not matching above policies have no access

### Rollback Notes

**Rollback Steps:**
1. DROP POLICY "administrators_full_expense_access"
2. DROP POLICY "managers_approve_expenses"
3. DROP POLICY "drivers_manage_own_expenses"
4. Optionally: Recreate old policy if it existed (for backward compatibility)
5. Optionally: ALTER TABLE expenses DISABLE ROW LEVEL SECURITY (if reverting completely)

**Data Loss Risk:** None
- Policies only control access, don't modify data
- Removing policies may expose data (security risk)

**Rollback Migration File:** `202501XX000007_expenses_rls_policies_rollback.sql`

### Test Checklist

**Post-Migration Tests:**
- [ ] Query: `SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'expenses'` - Verify RLS is enabled
- [ ] Query: `SELECT policyname FROM pg_policies WHERE tablename = 'expenses'` - Verify all policies exist
- [ ] Test: Driver user SELECT expenses for their assigned job - Should succeed
- [ ] Test: Driver user SELECT expenses for other driver's job - Should return empty (no access)
- [ ] Test: Driver user INSERT expense for their assigned job - Should succeed
- [ ] Test: Driver user INSERT expense for other driver's job - Should fail (no access)
- [ ] Test: Driver user UPDATE their own expense (not approved) - Should succeed
- [ ] Test: Driver user UPDATE approved expense - Should fail (trigger blocks, but policy allows)
- [ ] Test: Manager user SELECT expenses for job they manage - Should succeed
- [ ] Test: Manager user SELECT expenses for job they don't manage - Should return empty (no access)
- [ ] Test: Manager user UPDATE expenses for completed job (approval) - Should succeed (policy allows, but RPC required)
- [ ] Test: Manager user UPDATE expenses for incomplete job - Should fail (policy blocks)
- [ ] Test: Administrator user SELECT all expenses - Should succeed
- [ ] Test: Administrator user INSERT expense for any job - Should succeed
- [ ] Test: Administrator user UPDATE approved expense - Should succeed (policy allows, trigger may block)
- [ ] Test: Non-driver, non-manager, non-admin user SELECT expenses - Should return empty (no access)

---

## Migration 8: expense_audit_log_table.sql

**Purpose:** Create audit log table for administrative expense overrides (optional but recommended)

### Operations

1. **CREATE TABLE: expense_audit_log**
   - Columns:
     - `id` bigint PRIMARY KEY (auto-increment)
     - `action_type` text NOT NULL (CHECK constraint: 'admin_expense_update', 'admin_expense_delete', 'admin_expense_insert', 'admin_expense_approval_override')
     - `expense_id` bigint (nullable, FK to expenses.id)
     - `job_id` bigint (nullable, FK to jobs.id, for bulk operations)
     - `admin_user_id` uuid NOT NULL (FK to profiles.id)
     - `action_timestamp` timestamptz NOT NULL (default now())
     - `previous_values` jsonb (nullable, snapshot before change)
     - `new_values` jsonb (nullable, snapshot after change)
     - `reason` text (nullable, explanation for override)
     - `created_at` timestamptz NOT NULL (default now())
   - Primary key: `id`
   - Foreign keys: `expense_id` → `expenses.id`, `job_id` → `jobs.id`, `admin_user_id` → `profiles.id`

2. **CREATE INDEX operations**
   - Create index: `idx_expense_audit_log_admin` on `expense_audit_log(admin_user_id)`
   - Create index: `idx_expense_audit_log_expense` on `expense_audit_log(expense_id)` WHERE `expense_id IS NOT NULL`
   - Create index: `idx_expense_audit_log_job` on `expense_audit_log(job_id)` WHERE `job_id IS NOT NULL`
   - Create index: `idx_expense_audit_log_timestamp` on `expense_audit_log(action_timestamp)`

3. **Enable RLS on expense_audit_log**
   - ALTER TABLE expense_audit_log ENABLE ROW LEVEL SECURITY

4. **CREATE POLICY: Administrators can view audit logs**
   - Policy name: "administrators_view_audit_log"
   - Operation: SELECT
   - Using clause: Check if `profiles.role IN ('administrator', 'super_admin')` AND `profiles.id = auth.uid()`
   - Description: Only administrators can view audit logs

5. **CREATE POLICY: Service role can insert audit logs**
   - Policy name: "service_role_insert_audit_log"
   - Operation: INSERT
   - Using clause: Check if using service role (or allow all authenticated for application inserts)
   - Description: Application/service can insert audit log entries

6. **COMMENT operations**
   - Add comment on table: "Audit log for administrative expense overrides. Immutable."
   - Add comment on action_type column
   - Add comment on reason column

### Rollback Notes

**Rollback Steps:**
1. DROP POLICY "service_role_insert_audit_log"
2. DROP POLICY "administrators_view_audit_log"
3. ALTER TABLE expense_audit_log DISABLE ROW LEVEL SECURITY
4. DROP all indexes
5. DROP TABLE expense_audit_log

**Data Loss Risk:** High
- Dropping table deletes all audit log entries
- Should backup audit log before rollback if needed

**Rollback Migration File:** `202501XX000008_expense_audit_log_table_rollback.sql`

### Test Checklist

**Post-Migration Tests:**
- [ ] Query: `SELECT table_name FROM information_schema.tables WHERE table_name = 'expense_audit_log'` - Verify table exists
- [ ] Query: `SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = 'expense_audit_log'` - Verify all columns exist with correct types
- [ ] Query: `SELECT indexname FROM pg_indexes WHERE tablename = 'expense_audit_log'` - Verify all indexes created
- [ ] Query: `SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'expense_audit_log'` - Verify RLS is enabled
- [ ] Test: INSERT audit log entry (via service role or application) - Should succeed
- [ ] Test: Administrator SELECT audit log - Should succeed
- [ ] Test: Non-administrator SELECT audit log - Should return empty (no access)
- [ ] Test: UPDATE audit log entry - Should fail (immutable, no UPDATE policy)
- [ ] Test: DELETE audit log entry - Should fail (immutable, no DELETE policy)
- [ ] Test: INSERT with invalid action_type - Should fail with CHECK constraint error

---

## Overall Migration Test Checklist

**After All Migrations:**

1. **Schema Validation:**
   - [ ] Verify all columns exist in expenses table
   - [ ] Verify all constraints are active
   - [ ] Verify all indexes are created
   - [ ] Verify all foreign keys are active

2. **Function Validation:**
   - [ ] All functions exist and are callable
   - [ ] Functions return expected results
   - [ ] Functions handle edge cases correctly

3. **Trigger Validation:**
   - [ ] All triggers are active
   - [ ] Triggers fire correctly
   - [ ] Triggers allow admin overrides

4. **RLS Policy Validation:**
   - [ ] RLS is enabled on expenses table
   - [ ] All policies are active
   - [ ] Policies enforce correct access control

5. **Integration Tests:**
   - [ ] Complete expense workflow: Create → Approve → Verify immutability
   - [ ] Complete job workflow: Confirm → Start → Complete trips → Close
   - [ ] Admin override workflow: Update approved expense → Verify audit log

6. **Performance Tests:**
   - [ ] Indexes improve query performance
   - [ ] Triggers don't significantly slow down operations
   - [ ] RLS policies don't cause query timeouts

---

## Migration Execution Order Summary

1. **Migration 1** - Schema changes (must be first)
2. **Migration 2** - Data migration (depends on Migration 1)
3. **Migration 3** - Approval functions (depends on Migration 1)
4. **Migration 4** - Trip validation functions (independent)
5. **Migration 5** - Immutability triggers (depends on Migration 1, 3)
6. **Migration 6** - Job closure trigger (depends on Migration 4)
7. **Migration 7** - RLS policies (depends on Migration 1)
8. **Migration 8** - Audit log table (optional, independent)

**Dependencies:**
- Migration 2 depends on Migration 1 (needs new columns)
- Migration 5 depends on Migration 1 (needs columns) and Migration 3 (needs functions)
- Migration 6 depends on Migration 4 (needs validation function)
- Migration 7 depends on Migration 1 (needs table structure)

**Can Run in Parallel:**
- Migrations 3 and 4 (independent functions)
- Migration 8 (independent table)

---

**Document Status:** Migration Checklist - Ready for SQL Implementation  
**Last Updated:** 2025-01-XX  
**Next Steps:** Implement SQL for each migration file in order

