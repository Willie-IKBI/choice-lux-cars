# Roles & Permissions — Build Execution Plan (Phase 1)

**Source Spec:** ROLES_PERMISSIONS_SPEC.md (v1.0 — LOCKED)  
**Execution Mode:** Batch-based, no scope expansion  
**Rule:** Implement exactly what is specified — no interpretation

---

## Execution Principles

1. **One batch at a time** — Complete each batch before starting the next
2. **Commit after each batch** — Each batch is a discrete, testable unit
3. **No cross-batch changes** — Don't refactor code from previous batches
4. **No spec edits** — Spec is locked; if changes needed, create v1.1
5. **Test after each batch** — Verify batch works before proceeding

---

## Batch A — Pre-flight & Audit (READ-ONLY)

**Purpose:** Verify current state before enforcement  
**No code changes in this batch**  
**Duration:** ~30 minutes

### Tasks

1. **Router Guard Audit**
   - [ ] Identify existing router guard implementation
   - [ ] Document current route protection logic
   - [ ] List all protected routes
   - [ ] Identify gaps in current protection

2. **Role/Status Check Audit**
   - [ ] Find all files with role checks (`isAdmin`, `role == 'xxx'`, etc.)
   - [ ] Find all files with status checks
   - [ ] Document current permission patterns
   - [ ] Identify inconsistencies

3. **Job Filtering Audit**
   - [ ] Review current job filtering logic in `jobs_repository.dart`
   - [ ] Document current driver job visibility rules
   - [ ] Document current Driver Manager job visibility
   - [ ] Identify gaps vs spec requirements

4. **Vehicle Access Audit**
   - [ ] Find all vehicle access points (routes, UI, repositories)
   - [ ] Document current vehicle visibility rules
   - [ ] Identify where vehicles are shown/hidden
   - [ ] Check vehicle selection in job creation

5. **User Management Audit**
   - [ ] Find all user management entry points
   - [ ] Document current role assignment logic
   - [ ] Document current activation/deactivation logic
   - [ ] Document current branch assignment logic

6. **Client Access Audit**
   - [ ] Find all client access points
   - [ ] Document current client visibility rules
   - [ ] Identify where clients are shown/hidden

### Output

**Deliverable:** Audit report listing:
- Files involved per concern
- Current behavior vs spec requirements
- Gaps identified
- No refactors, no fixes

### Files to Review

- `lib/core/router/guards.dart`
- `lib/features/auth/providers/auth_provider.dart`
- `lib/features/jobs/data/jobs_repository.dart`
- `lib/features/vehicles/vehicles_screen.dart`
- `lib/features/users/users_screen.dart`
- `lib/features/users/widgets/user_form.dart`
- `lib/features/dashboard/dashboard_screen.dart`
- `lib/shared/widgets/luxury_drawer.dart`
- `lib/app/app.dart`

---

## Batch B — Router Guard Enforcement

**Spec Reference:**  
- Section 6: Sign-In & Access Control
- Section 5: Status vs Role Priority

**Purpose:** Enforce access control at router level  
**Duration:** ~2 hours

### Tasks

1. **Update Router Guards**
   - [ ] Add status check (`deactivated`, `suspended`)
   - [ ] Add role assignment check (`unassigned`)
   - [ ] Add route-level role permissions
   - [ ] Update `RouterGuards.guardRoute()` method

2. **Update Sign-In Flow**
   - [ ] Add status check in `auth_provider.dart`
   - [ ] Block sign-in for `deactivated` status
   - [ ] Block sign-in for `suspended` role
   - [ ] Redirect `unassigned` to `/pending-approval`
   - [ ] Show appropriate error messages

3. **Add Route-Level Protection**
   - [ ] Protect `/users` route (Admin, Super Admin, Manager only)
   - [ ] Protect `/vehicles` route (Admin, Super Admin only)
   - [ ] Protect `/clients` route (Admin, Super Admin only)
   - [ ] Protect `/insights` route (Admin, Super Admin, Manager only)
   - [ ] Protect `/settings/notifications` route (Super Admin only)

### Files to Modify

- `lib/core/router/guards.dart`
- `lib/features/auth/providers/auth_provider.dart`
- `lib/app/app.dart`

### Rules Implemented

- ✅ Deactivated → block all access
- ✅ Suspended → block all access
- ✅ Unassigned → redirect to `/pending-approval`
- ✅ Role-based route protection

### Testing

- [ ] Unassigned user → Redirected to `/pending-approval`
- [ ] Deactivated user → Blocked from sign-in
- [ ] Suspended user → Blocked from sign-in
- [ ] Protected routes → Access denied for unauthorized roles

---

## Batch C — Permission Service

**Spec Reference:**  
- Section 10: Implementation Requirements (Permission Service)

**Purpose:** Create centralized permission checking  
**Duration:** ~2 hours

### Tasks

1. **Create Permission Service**
   - [ ] Create `lib/core/services/permission_service.dart`
   - [ ] Implement `canAccessRoute(route, userRole, userStatus)`
   - [ ] Implement `canAssignRole(assignerRole, targetRole)`
   - [ ] Implement `canActivateDeactivate(userRole)`
   - [ ] Implement `canViewClients(userRole)`
   - [ ] Implement `canViewVehicles(userRole)`
   - [ ] Implement `isBranchScoped(userRole)`
   - [ ] Implement `getBranchFilter(userRole, userBranchId)`

2. **Create Role Constants**
   - [ ] Create `lib/core/constants/roles.dart`
   - [ ] Define role enum/constants
   - [ ] Define permission flags per role
   - [ ] Define branch requirement per role

### Files to Create

- `lib/core/services/permission_service.dart`
- `lib/core/constants/roles.dart`

### Methods Required

```dart
// Permission Service Methods
bool canAccessRoute(String route, String? userRole, String? userStatus)
bool canAssignRole(String? assignerRole, String targetRole)
bool canActivateDeactivate(String? userRole)
bool canViewClients(String? userRole)
bool canViewVehicles(String? userRole)
bool isBranchScoped(String? userRole)
int? getBranchFilter(String? userRole, int? userBranchId)
```

### Testing

- [ ] Permission service methods return correct values for each role
- [ ] Role constants are properly defined
- [ ] Branch scoping logic works correctly

---

## Batch D — Job Visibility Logic

**Spec Reference:**  
- Section 7: Job Visibility Rules
- Section 11: Edge Cases & Special Rules (Driver, Driver Manager)

**Purpose:** Implement job filtering per role  
**Duration:** ~3 hours

### Tasks

1. **Driver Job Filtering**
   - [ ] Implement unconfirmed jobs (always visible)
   - [ ] Implement confirmed jobs (1 day before start date)
   - [ ] Implement jobs without start date (always visible with indicator)
   - [ ] Add indicator for jobs without start date: "⚠️ No start date available"

2. **Driver Manager Job Filtering**
   - [ ] Filter by `created_by = driver_manager_id`
   - [ ] Filter by `manager_id = driver_manager_id`
   - [ ] Prevent duplicate if Driver Manager is also driver
   - [ ] Show job once (as Driver Manager allocation, not as driver)

3. **Manager Job Filtering**
   - [ ] Filter by `branch_id = manager_branch_id`
   - [ ] Show all jobs in branch

4. **Admin/Super Admin Job Filtering**
   - [ ] No branch filter (see all jobs)

### Files to Modify

- `lib/features/jobs/data/jobs_repository.dart`
- `lib/features/jobs/jobs_screen.dart` (if needed for UI indicators)

### SQL Filters to Implement

**Driver Unconfirmed:**
```sql
WHERE driver_id = user_id 
  AND (driver_confirm_ind = false OR is_confirmed = false)
```

**Driver Confirmed (1 day before):**
```sql
WHERE driver_id = user_id 
  AND (driver_confirm_ind = true OR is_confirmed = true)
  AND job_start_date >= CURRENT_DATE
  AND job_start_date <= CURRENT_DATE + INTERVAL '1 day'
```

**Driver No Start Date:**
```sql
WHERE driver_id = user_id 
  AND job_start_date IS NULL
```

**Driver Manager:**
```sql
WHERE created_by = driver_manager_id
   OR manager_id = driver_manager_id
```

### Testing

- [ ] Driver sees unconfirmed jobs (always)
- [ ] Driver sees confirmed jobs (1 day before start)
- [ ] Driver sees jobs without start date (with indicator)
- [ ] Driver Manager sees jobs they created
- [ ] Driver Manager sees jobs they allocated
- [ ] Driver Manager as driver doesn't see job twice
- [ ] Manager sees all jobs in branch
- [ ] Admin sees all jobs

---

## Batch E — Vehicle Access Control

**Spec Reference:**  
- Section 8: Vehicle Management Rules

**Purpose:** Restrict vehicle access to Admin/Super Admin only  
**Duration:** ~2 hours

### Tasks

1. **Vehicle Route Protection**
   - [ ] Add role check in `vehicles_screen.dart`
   - [ ] Block access for non-admin roles
   - [ ] Show access denied message

2. **Vehicle UI Visibility**
   - [ ] Hide Vehicles card from dashboard for non-admin
   - [ ] Hide Vehicles menu item from drawer for non-admin
   - [ ] Update dashboard cards logic

3. **Vehicle Selection in Jobs**
   - [ ] Ensure only Admin/Super Admin can see vehicle dropdown
   - [ ] Allow cross-branch vehicle assignment (no branch validation)
   - [ ] Show all vehicles (no branch filter) for Admin/Super Admin

4. **Vehicle Branch Assignment**
   - [ ] Ensure vehicles have `branch_id` (validation)
   - [ ] Allow Admin/Super Admin to update missing `branch_id`

### Files to Modify

- `lib/features/vehicles/vehicles_screen.dart`
- `lib/features/dashboard/dashboard_screen.dart`
- `lib/shared/widgets/luxury_drawer.dart`
- `lib/app/app.dart` (route guard already in Batch B)
- `lib/features/jobs/screens/create_job_screen.dart` (vehicle dropdown)

### Rules Implemented

- ✅ Admin/Super Admin only can see vehicles
- ✅ Cross-branch vehicle assignment allowed
- ✅ Vehicles card hidden for non-admin
- ✅ Vehicles menu hidden for non-admin

### Testing

- [ ] Admin can see vehicles
- [ ] Super Admin can see vehicles
- [ ] Manager cannot see vehicles
- [ ] Driver Manager cannot see vehicles
- [ ] Driver cannot see vehicles
- [ ] Admin can assign vehicles from any branch
- [ ] Vehicles card hidden from dashboard for non-admin

---

## Batch F — UI Visibility Gating

**Spec Reference:**  
- Section 3: Permission Matrix (Routes per role)
- Section 8: Vehicle Management Rules
- Section 9: User Management Rules

**Purpose:** Hide/show UI elements based on role  
**Duration:** ~2 hours

### Tasks

1. **Navigation Menu Updates**
   - [ ] Hide Vehicles menu for non-admin (already in Batch E)
   - [ ] Hide Clients menu for Manager, Driver Manager, Driver
   - [ ] Hide Insights menu for Driver Manager, Driver
   - [ ] Hide Users menu for Driver Manager, Driver
   - [ ] Hide Notification Settings for non-Super Admin

2. **Dashboard Cards Updates**
   - [ ] Hide Vehicles card for non-admin (already in Batch E)
   - [ ] Hide Clients card for Manager, Driver Manager, Driver
   - [ ] Show appropriate cards per role

3. **User Management UI**
   - [ ] Restrict role assignment dropdown (Super Admin: all, Admin: manager/driver_manager/driver, Manager: driver_manager/driver)
   - [ ] Hide activation/deactivation toggle for non-Super Admin
   - [ ] Force `branch_id = NULL` for Admin/Super Admin
   - [ ] Require `branch_id` for non-admin roles

4. **Job Creation UI**
   - [ ] Auto-select manager for Driver Manager (if exists)
   - [ ] Hide manager dropdown for Driver Manager if no manager exists
   - [ ] Show message if no manager for branch
   - [ ] Only Admin can select manager if none exists

### Files to Modify

- `lib/shared/widgets/luxury_drawer.dart`
- `lib/shared/widgets/luxury_app_bar.dart`
- `lib/features/dashboard/dashboard_screen.dart`
- `lib/features/users/widgets/user_form.dart`
- `lib/features/jobs/screens/create_job_screen.dart`

### Rules Implemented

- ✅ Clients hidden for Manager, Driver Manager, Driver
- ✅ Vehicles hidden for non-admin (already in Batch E)
- ✅ Role assignment restricted per role
- ✅ Activation/deactivation restricted to Super Admin
- ✅ Branch assignment enforced (NULL for Admin/Super Admin, required for others)

### Testing

- [ ] Clients menu hidden for Manager, Driver Manager, Driver
- [ ] Clients card hidden for Manager, Driver Manager, Driver
- [ ] Role assignment dropdown shows correct options per role
- [ ] Activation/deactivation toggle only for Super Admin
- [ ] Branch assignment enforced correctly

---

## Batch G — Validation & Migration

**Spec Reference:**  
- Section 12: Migration Notes
- Section 12: Testing Checklist

**Purpose:** Validate data and prepare migration  
**Duration:** ~1 hour

### Tasks

1. **Data Validation**
   - [ ] Audit users for correct `branch_id` assignment
   - [ ] Identify Admin/Super Admin with `branch_id != NULL`
   - [ ] Identify non-admin users with `branch_id = NULL`
   - [ ] Identify users with `role = null` or `status = null`
   - [ ] Audit jobs for `branch_id = NULL`
   - [ ] Audit vehicles for `branch_id = NULL`

2. **Migration Preparation**
   - [ ] Document data violations found
   - [ ] Create migration script (if needed)
   - [ ] Plan manual corrections
   - [ ] Document migration steps

3. **Final Testing**
   - [ ] Run full testing checklist from spec
   - [ ] Verify all routes are protected
   - [ ] Verify all UI elements are hidden/shown correctly
   - [ ] Verify job filtering works correctly
   - [ ] Verify vehicle access is restricted

### Output

**Deliverable:** Migration report with:
- Data violations identified
- Migration script (if needed)
- Manual correction steps
- Testing results

### Testing Checklist (Full)

**Sign-In & Access:**
- [ ] Unassigned user → Redirected to `/pending-approval`
- [ ] Deactivated user → Blocked from sign-in
- [ ] Suspended user → Blocked from sign-in
- [ ] Active user with role → Can sign in and access app

**Role Assignment:**
- [ ] Super Admin can assign any role
- [ ] Admin can assign manager, driver_manager, driver
- [ ] Admin cannot assign administrator or super_admin
- [ ] Manager can assign driver_manager and driver (branch only)
- [ ] Manager cannot assign administrator, super_admin, or manager

**Activation/Deactivation:**
- [ ] Super Admin can activate/deactivate users
- [ ] Admin cannot activate/deactivate users
- [ ] Deactivated user cannot sign in
- [ ] Deactivated user is logged out if already signed in

**Branch Assignment:**
- [ ] Admin/Super Admin must have `branch_id = NULL`
- [ ] Manager, Driver Manager, Driver must have `branch_id` assigned
- [ ] Admin cannot be assigned to branch
- [ ] Non-admin cannot have `branch_id = NULL`

**Job Visibility:**
- [ ] Driver sees unconfirmed jobs (always)
- [ ] Driver sees confirmed jobs (1 day before start)
- [ ] Driver sees jobs without start date (with indicator)
- [ ] Driver Manager sees jobs they created
- [ ] Driver Manager sees jobs they allocated
- [ ] Driver Manager as driver doesn't see job twice
- [ ] Manager sees all jobs in branch
- [ ] Admin sees all jobs

**Vehicle Access:**
- [ ] Admin can see vehicles
- [ ] Super Admin can see vehicles
- [ ] Manager cannot see vehicles
- [ ] Driver Manager cannot see vehicles
- [ ] Driver cannot see vehicles
- [ ] Admin can assign vehicles from any branch
- [ ] Vehicles card hidden from dashboard for non-admin

**Client Access:**
- [ ] Admin can see clients
- [ ] Super Admin can see clients
- [ ] Manager cannot see clients
- [ ] Driver Manager cannot see clients
- [ ] Driver cannot see clients
- [ ] Clients route blocked for non-admin

**Manager Auto-Selection:**
- [ ] Driver Manager creates job → Manager auto-selected (if exists)
- [ ] No manager for branch → Only Admin can select manager
- [ ] Driver Manager cannot select manager if none exists

**Missing Branch ID:**
- [ ] Admin can update missing `branch_id` for jobs
- [ ] Admin can update missing `branch_id` for vehicles
- [ ] Warning shown when `branch_id = NULL`

---

## Execution Checklist

### Pre-Build

- [ ] Read and understand ROLES_PERMISSIONS_SPEC.md
- [ ] Review DATA_SCHEMA.md for database structure
- [ ] Set up development environment
- [ ] Create feature branch: `feature/roles-permissions-phase1`

### During Build

- [ ] Complete Batch A (Audit)
- [ ] Review audit findings
- [ ] Complete Batch B (Router Guards)
- [ ] Test Batch B
- [ ] Commit Batch B
- [ ] Complete Batch C (Permission Service)
- [ ] Test Batch C
- [ ] Commit Batch C
- [ ] Complete Batch D (Job Visibility)
- [ ] Test Batch D
- [ ] Commit Batch D
- [ ] Complete Batch E (Vehicle Access)
- [ ] Test Batch E
- [ ] Commit Batch E
- [ ] Complete Batch F (UI Visibility)
- [ ] Test Batch F
- [ ] Commit Batch F
- [ ] Complete Batch G (Validation & Migration)
- [ ] Test Batch G
- [ ] Commit Batch G

### Post-Build

- [ ] Run full test suite
- [ ] Manual testing with all roles
- [ ] Code review
- [ ] Update documentation
- [ ] Merge to main branch

---

## Notes

- **No scope expansion** — If something isn't in the spec, don't implement it
- **No interpretation** — If spec is unclear, ask before implementing
- **Batch independence** — Each batch should work independently
- **Test after each batch** — Don't proceed if batch fails tests
- **Spec is locked** — Don't edit spec during build; create v1.1 if changes needed

---

## Risk Mitigation

1. **Breaking Changes:** Test after each batch to catch issues early
2. **Data Migration:** Validate data before enforcing rules
3. **User Impact:** Ensure existing users can still access app (with correct roles)
4. **Performance:** Monitor query performance for job filtering changes

---

**End of Build Plan**

