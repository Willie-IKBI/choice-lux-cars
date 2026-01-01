# Driver Job Flow - Migration Checklist V2 (Summary)

**Version:** 2.0 (Corrected)  
**Based on:** `ai/DRIVER_JOB_FLOW_DATABASE_CONTRACT.md` (PATCH 1-5)

---

## Migration Order

1. **202501XX000001_expenses_schema_enhancements.sql**
2. **202501XX000002_expenses_data_migration.sql**
3. **202501XX000003_expense_approval_functions.sql**
4. **202501XX000004_trip_validation_functions.sql**
5. **202501XX000005_expense_immutability_triggers.sql**
6. **202501XX000006_job_closure_validation_trigger.sql**
7. **202501XX000007_expenses_rls_policies.sql**
8. **202501XX000008_expense_audit_log_table.sql** (REQUIRED, not optional)

---

## Key Changes in V2

### Migration 1: expenses_schema_enhancements.sql

**FIX 1: Safe expense_type NOT NULL sequencing**
- Add `expense_type` as **nullable first** (no NOT NULL initially)
- Add temporary CHECK constraint allowing NULL: `expense_type IN (...) OR expense_type IS NULL`
- Migration 2 will set defaults, then Migration 2 will add NOT NULL constraint
- Prevents migration failure on existing rows

**FIX 3: Column naming - user → driver_id**
- Rename `expenses.user` to `expenses.driver_id` for clarity and consistency
- If rename not possible, add new `driver_id` column and migrate data
- Update all references: indexes, FKs, comments
- Document: "Previously named 'user'"

---

### Migration 2: expenses_data_migration.sql

**FIX 1: Complete data migration before NOT NULL**
- Set default values: UPDATE NULL expense_type to 'other'
- Migrate other_description data
- **Then** add NOT NULL constraint to expense_type
- Update CHECK constraint to remove NULL allowance
- Ensures safe transition for existing data

---

### Migration 3: expense_approval_functions.sql

**FIX 5: SECURITY DEFINER hardening**
- Set `search_path = ''` (or explicit 'public') in all functions
- Use fully qualified table names (public.expenses, public.jobs, public.profiles)
- In `approve_job_expenses()`:
  - Verify `p_manager_id` exists in profiles and has manager/admin role
  - Verify `p_manager_id = auth.uid()` (caller must be the manager)
  - Verify job exists and status = 'completed'
  - Raise exception on any verification failure
- Prevents search_path injection and unauthorized approvals

---

### Migration 7: expenses_rls_policies.sql

**FIX 2: Re-assert profiles.id == auth.uid()**
- Add explicit notes in all RLS policies: "Assumes profiles.id = auth.uid() (same UUID value)"
- Document this critical assumption in driver, manager, and admin policies
- Removes ambiguity about canonical identity

**FIX 4: Manager policy SELECT-only**
- Remove UPDATE policy for managers
- Manager policy: SELECT operation only
- Approvals must go through `approve_job_expenses()` RPC function
- Trigger in Migration 5 enforces RPC-only approval (blocks direct UPDATE)

---

### Migration 8: expense_audit_log_table.sql

**FIX 6: Required (not optional)**
- Change status from "optional but recommended" to **REQUIRED**
- Must be executed before admin overrides are used
- Admin overrides require audit logging (PATCH 5 requirement)
- Without audit log, admin actions cannot be tracked

---

## Summary of All Fixes

1. **Migration 1:** Safe expense_type NOT NULL (add nullable first, NOT NULL in Migration 2)
2. **Migration 7:** Re-assert profiles.id == auth.uid() in all RLS policies
3. **Migration 1:** Rename expenses.user → expenses.driver_id (or document naming convention)
4. **Migration 7:** Manager policy SELECT-only; approvals via RPC only
5. **Migration 3:** SECURITY DEFINER hardening (search_path + authorization checks)
6. **Migration 8:** Required migration (not optional) for admin override audit

---

**Document Status:** V2 Summary - Ready for Implementation  
**Last Updated:** 2025-01-XX
