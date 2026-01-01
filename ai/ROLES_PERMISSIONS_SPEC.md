# Roles & Permissions Specification — Phase 1

**Version:** 1.0  
**Date:** 2025-01-20  
**Status:** Phase 1 — Implementation Ready  
**Reference:** Based on requirements and DATA_SCHEMA.md


LOCKED SPEC — DO NOT EDIT DURING BUILD
Any change requires a new version (e.g., v1.1) and a logged deviation note.
This file is the source of truth for RBAC implementation.



---

## Table of Contents

1. [Overview](#overview)
2. [Role Definitions](#role-definitions)
3. [Permission Matrix](#permission-matrix)
4. [Branch-Scoping Rules](#branch-scoping-rules)
5. [Status vs Role Priority](#status-vs-role-priority)
6. [Sign-In & Access Control](#sign-in--access-control)
7. [Job Visibility Rules](#job-visibility-rules)
8. [Vehicle Management Rules](#vehicle-management-rules)
9. [User Management Rules](#user-management-rules)
10. [Implementation Requirements](#implementation-requirements)
11. [Edge Cases & Special Rules](#edge-cases--special-rules)
12. [Testing Checklist](#testing-checklist)

---

## Overview

This specification defines the role-based access control (RBAC) system for Choice Lux Cars. The system uses a combination of:
- **Role** (`profiles.role`): Defines user capabilities
- **Status** (`profiles.status`): Defines user availability (active/deactivated/unassigned)
- **Branch ID** (`profiles.branch_id`): Defines data scope (NULL = national, non-NULL = branch-scoped)

### Key Principles

1. **Status takes priority over role** — Deactivated users cannot access app regardless of role
2. **Suspended role blocks all access** — Treated as status override
3. **Admin/Super Admin are national** — Must have `branch_id = NULL`
4. **Branch-scoping is enforced** — Users can only access data from their branch (unless Admin/Super Admin)
5. **Unassigned users are blocked** — Must be assigned role by Admin/Super Admin before access

---

## Role Definitions

### Branch Constants

```dart
// From lib/features/branches/models/branch.dart
Branch.durbanId = 1          // 'Dbn'
Branch.capeTownId = 2        // 'Cpt'
Branch.johannesburgId = 3    // 'Jhb'
```

### Role Enum Values

From `user_role_enum` in database:
- `administrator` — Full system access (national)
- `super_admin` — Full system access + notification preferences + role assignment (national)
- `manager` — Management-level access (branch-scoped)
- `driver_manager` — Driver management access (branch-scoped)
- `driver` — Driver-level access (branch-scoped)
- `suspended` — Blocked access (status override)

### Status Values

From `profiles.status` check constraint:
- `active` — User can access app
- `deactivated` — User cannot access app (blocks all access)
- `unassigned` — User has no role assigned (blocks all access)

---

## Permission Matrix

### Super Admin (`super_admin`)

**Branch Assignment:** `branch_id = NULL` (forced, national access)

**Role Assignment:**
- ✅ Can assign any role (administrator, manager, driver_manager, driver)
- ✅ Can activate/deactivate users
- ✅ Can change user roles

**User Management:**
- ✅ Full access to all user information
- ✅ Can view, edit, activate/deactivate all users
- ✅ Can assign roles to users

**Data Access:**
- ✅ Full access to all data (national, all branches)
- ✅ Can see all clients, jobs, quotes, invoices, vehicles
- ✅ Can see all insights (all 5 tabs)

**Vehicle Management:**
- ✅ Can view and manage all vehicles (all branches)
- ✅ Can assign vehicles from any branch to any job (cross-branch allowed)
- ✅ Can create, edit, delete vehicles

**Job Management:**
- ✅ Can create, edit, cancel all jobs
- ✅ Can assign drivers from any branch
- ✅ Can assign vehicles from any branch
- ✅ Can select manager for any branch (even if no manager exists for that branch)

**Clients:**
- ✅ Can view and manage all clients

**Routes:**
- ✅ All routes accessible
- ✅ `/users` — Full access
- ✅ `/vehicles` — Full access
- ✅ `/clients` — Full access
- ✅ `/insights` — Full access (all tabs)
- ✅ `/settings/notifications` — Full access (only role with this)

**Special Permissions:**
- ✅ Can manage notification preferences (system-wide)
- ✅ Can update missing `branch_id` values (for jobs, vehicles, etc.)

---

### Administrator (`administrator`)

**Branch Assignment:** `branch_id = NULL` (forced, national access)

**Role Assignment:**
- ✅ Can assign manager, driver_manager, driver
- ❌ Cannot assign administrator or super_admin
- ❌ Cannot activate/deactivate users (Super Admin only)

**User Management:**
- ✅ Can view and edit basic user information (name, email, phone, etc.)
- ❌ Cannot change user roles (Super Admin only)
- ❌ Cannot activate/deactivate users (Super Admin only)

**Data Access:**
- ✅ Full access to all data (national, all branches)
- ✅ Can see all clients, jobs, quotes, invoices, vehicles
- ✅ Can see all insights (all 5 tabs)

**Vehicle Management:**
- ✅ Can view and manage all vehicles (all branches)
- ✅ Can assign vehicles from any branch to any job (cross-branch allowed)
- ✅ Can create, edit, delete vehicles

**Job Management:**
- ✅ Can create, edit, cancel all jobs
- ✅ Can assign drivers from any branch
- ✅ Can assign vehicles from any branch
- ✅ Can select manager for any branch (even if no manager exists for that branch)

**Clients:**
- ✅ Can view and manage all clients

**Routes:**
- ✅ All routes accessible (except notification preferences)
- ✅ `/users` — Full access (view/edit basic info only)
- ✅ `/vehicles` — Full access
- ✅ `/clients` — Full access
- ✅ `/insights` — Full access (all tabs)
- ❌ `/settings/notifications` — No access (Super Admin only)

**Special Permissions:**
- ✅ Can update missing `branch_id` values (for jobs, vehicles, etc.)

---

### Manager (`manager`)

**Branch Assignment:** `branch_id` required (must be 1, 2, or 3 — Durban, Cape Town, or Johannesburg)

**Role Assignment:**
- ✅ Can assign driver_manager and driver (only in their branch)
- ❌ Cannot assign administrator, super_admin, or manager
- ❌ Cannot activate/deactivate users

**User Management:**
- ✅ Can view and edit basic user information (branch users only)
- ❌ Cannot change user roles
- ❌ Cannot activate/deactivate users

**Data Access:**
- ✅ Branch-scoped access (only their branch data)
- ✅ Can see jobs, quotes, invoices in their branch
- ✅ Can see insights (1 tab only)
- ❌ Cannot see clients

**Vehicle Management:**
- ❌ Cannot see vehicles
- ❌ Cannot access `/vehicles` route
- ❌ Cannot create, edit, or delete vehicles
- ❌ Cannot select vehicles when creating jobs

**Job Management:**
- ✅ Can create, edit jobs in their branch
- ✅ Can assign drivers from their branch only
- ✅ Can assign vehicles (but cannot see vehicle list — Admin must assign)
- ✅ Manager is auto-selected when Driver Manager creates job (if manager exists for branch)

**Clients:**
- ❌ Cannot see clients
- ❌ Cannot access `/clients` route

**Routes:**
- ✅ `/jobs` — Branch-scoped
- ✅ `/quotes` — Branch-scoped
- ✅ `/invoices` — Branch-scoped
- ✅ `/insights` — Limited (1 tab)
- ✅ `/users` — Can view/edit branch users
- ❌ `/vehicles` — No access
- ❌ `/clients` — No access

---

### Driver Manager (`driver_manager`)

**Branch Assignment:** `branch_id` required (must be 1, 2, or 3)

**Display Title:** "Driver Manager"

**Role Assignment:**
- ❌ Cannot assign roles

**User Management:**
- ❌ Cannot manage users
- ❌ Cannot edit users

**Data Access:**
- ✅ Branch-scoped access (only their branch data)
- ✅ Can see jobs they created + jobs they allocated to drivers
- ❌ Cannot see clients

**Vehicle Management:**
- ❌ Cannot see vehicles
- ❌ Cannot access `/vehicles` route
- ❌ Cannot create, edit, or delete vehicles
- ❌ Cannot select vehicles when creating jobs

**Job Management:**
- ✅ Can create jobs in their branch
- ✅ Can edit jobs they created or allocated
- ✅ Can allocate drivers to jobs (only drivers from same branch)
- ✅ Manager for their branch is auto-selected when creating job (if manager exists)
- ✅ If no manager exists for branch, only Admin can select manager

**Job Visibility:**
- ✅ Jobs where `created_by = driver_manager_id`
- ✅ Jobs where `manager_id = driver_manager_id` (jobs they allocated)
- ✅ If Driver Manager is also assigned as driver (`driver_id = driver_manager_id`), show job once (as Driver Manager allocation, not as driver)

**Clients:**
- ❌ Cannot see clients
- ❌ Cannot access `/clients` route

**Routes:**
- ✅ `/jobs` — Branch-scoped (filtered by created_by/manager_id)
- ✅ `/quotes` — Branch-scoped
- ✅ `/invoices` — Branch-scoped
- ❌ `/vehicles` — No access
- ❌ `/clients` — No access
- ❌ `/insights` — No access
- ❌ `/users` — No access

---

### Driver (`driver`)

**Branch Assignment:** `branch_id` required (must be 1, 2, or 3)

**Role Assignment:**
- ❌ Cannot assign roles

**User Management:**
- ✅ Can view and edit own profile only
- ❌ Cannot manage other users

**Data Access:**
- ✅ Can see jobs allocated to them (with special filtering)
- ❌ Cannot see clients

**Vehicle Management:**
- ❌ Cannot see vehicles
- ❌ Cannot access `/vehicles` route
- ✅ Can see vehicle information in job details (read-only, for assigned jobs only)

**Job Visibility (Special Filtering):**
- ✅ **Unconfirmed Jobs:** Always visible
  - Where `driver_id = user_id` AND (`driverConfirmation = false` OR `isConfirmed = false`)
- ✅ **Confirmed Jobs:** Only visible 1 day before start date
  - Where `driver_id = user_id` AND (`driverConfirmation = true` OR `isConfirmed = true`) AND `jobStartDate >= today` AND `jobStartDate <= today + 1 day`
- ✅ **Jobs without `jobStartDate`:** Show as unconfirmed with indicator "No start date available"
  - Where `driver_id = user_id` AND `jobStartDate IS NULL`
  - Display indicator: "⚠️ No start date available"
  - Always visible (treated as unconfirmed)

**Job Actions:**
- ✅ Can confirm jobs
- ✅ Can update job progress
- ✅ Can view job details for assigned jobs

**Clients:**
- ❌ Cannot see clients
- ❌ Cannot access `/clients` route

**Routes:**
- ✅ `/jobs` — Filtered (unconfirmed always, confirmed 1 day before)
- ✅ `/jobs/:id/progress` — For assigned jobs
- ✅ `/jobs/:id/summary` — For assigned jobs
- ❌ `/vehicles` — No access
- ❌ `/clients` — No access
- ❌ `/quotes` — No access
- ❌ `/invoices` — No access
- ❌ `/insights` — No access
- ❌ `/users` — No access

---

### Suspended (`suspended`)

**Branch Assignment:** N/A (blocked from access)

**Access:**
- ❌ Cannot sign in
- ❌ Cannot access any routes
- ❌ Cannot be assigned to jobs
- ❌ Cannot be used in any operations

**Treatment:**
- Treated as status override (same as `deactivated`)
- Blocked at router guard level
- Blocked at sign-in level

---

## Branch-Scoping Rules

### User Branch Assignment

**Admin/Super Admin:**
- **MUST** have `branch_id = NULL` (forced, national access)
- Cannot be assigned to a branch
- Can see all branches' data

**Manager, Driver Manager, Driver:**
- **MUST** have `branch_id` assigned (1, 2, or 3)
- Cannot have `branch_id = NULL`
- Can only see data from their branch

### Data Branch-Scoping

**Jobs:**
- Filtered by `jobs.branch_id`
- Admin/Super Admin see all jobs
- Others see only jobs from their branch

**Vehicles:**
- Filtered by `vehicles.branch_id`
- Admin/Super Admin see all vehicles
- Others cannot see vehicles (Admin/Super Admin only)

**Users:**
- Filtered by `profiles.branch_id`
- Admin/Super Admin see all users
- Managers see only users from their branch

**Quotes, Invoices:**
- Filtered by branch (if applicable)
- Admin/Super Admin see all
- Others see only their branch

### Cross-Branch Operations

**Vehicle Assignment:**
- ✅ Admin/Super Admin can assign vehicles from any branch to any job
- Example: Cape Town vehicle can be assigned to Johannesburg job
- Rationale: Operational flexibility (vehicle might be needed in different location)

**Driver Assignment:**
- ❌ Managers can only assign drivers from their branch
- ❌ Driver Managers can only allocate drivers from their branch
- ✅ Admin/Super Admin can assign drivers from any branch

---

## Status vs Role Priority

### Priority Order

1. **Status Check First:**
   - If `status = 'deactivated'` → Block access (regardless of role)
   - If `status = 'unassigned'` → Block access (redirect to pending approval)
   - If `role = 'suspended'` → Block access (treated as status override)

2. **Role Check Second:**
   - If status is `active` and role is assigned → Check role permissions

### Status Values

**Active:**
- User can access app (subject to role permissions)
- Default status for assigned users

**Deactivated:**
- User cannot sign in
- User cannot access any routes
- Blocks all access regardless of role
- Only Super Admin can activate/deactivate

**Unassigned:**
- User has no role assigned
- Redirected to `/pending-approval`
- Cannot access app until role is assigned
- Admin/Super Admin must assign role

---

## Sign-In & Access Control

### Sign-In Flow

1. **User attempts sign-in**
2. **Check authentication** (Supabase auth)
3. **Check status:**
   - If `status = 'deactivated'` → Block sign-in, show message: "Your account has been deactivated. Please contact an administrator."
   - If `status = 'unassigned'` → Allow sign-in but redirect to `/pending-approval`
   - If `role = 'suspended'` → Block sign-in, show message: "Your account has been suspended. Please contact an administrator."
4. **Check role assignment:**
   - If `role = null` OR `role = 'unassigned'` → Redirect to `/pending-approval`
   - If role is assigned → Proceed to dashboard
5. **Router guard checks:**
   - Check status on every route navigation
   - Check role permissions for protected routes
   - Redirect if access denied

### Router Guard Logic

```dart
// Pseudo-code for router guard
if (!isAuthenticated) {
  if (publicRoute) return null; // Allow
  return '/login'; // Redirect
}

if (status == 'deactivated' || role == 'suspended') {
  return '/login'; // Block access
}

if (role == null || role == 'unassigned') {
  if (currentRoute == '/pending-approval') return null; // Allow
  return '/pending-approval'; // Redirect
}

// Check route-level permissions
if (routeRequiresAdmin && !isAdmin && !isSuperAdmin) {
  return '/'; // Redirect to dashboard
}

// Allow access
return null;
```

---

## Job Visibility Rules

### Driver Job Filtering

**Unconfirmed Jobs (Always Visible):**
```sql
WHERE driver_id = user_id 
  AND (driver_confirm_ind = false OR is_confirmed = false)
```

**Confirmed Jobs (1 Day Before Start):**
```sql
WHERE driver_id = user_id 
  AND (driver_confirm_ind = true OR is_confirmed = true)
  AND job_start_date >= CURRENT_DATE
  AND job_start_date <= CURRENT_DATE + INTERVAL '1 day'
```

**Jobs Without Start Date (Always Visible, Unconfirmed):**
```sql
WHERE driver_id = user_id 
  AND job_start_date IS NULL
```
- Display indicator: "⚠️ No start date available"
- Treated as unconfirmed (always visible)

### Driver Manager Job Visibility

**Jobs Created by Driver Manager:**
```sql
WHERE created_by = driver_manager_id
```

**Jobs Allocated by Driver Manager:**
```sql
WHERE manager_id = driver_manager_id
```

**Special Case: Driver Manager as Driver:**
- If Driver Manager is also assigned as driver (`driver_id = driver_manager_id`), show job once
- Show as Driver Manager allocation (not as driver)
- Prevent duplicate display

### Manager Job Visibility

**All Jobs in Branch:**
```sql
WHERE branch_id = manager_branch_id
```

### Admin/Super Admin Job Visibility

**All Jobs:**
```sql
-- No branch filter, see all jobs
```

---

## Vehicle Management Rules

### Vehicle Access

**Who Can See Vehicles:**
- ✅ Admin
- ✅ Super Admin
- ❌ Manager
- ❌ Driver Manager
- ❌ Driver

### Vehicle Branch Assignment

**All Vehicles:**
- Must have `branch_id` assigned (1, 2, or 3)
- Cannot have `branch_id = NULL`
- If `branch_id` is NULL, Admin/Super Admin can update it

### Vehicle Selection in Jobs

**Admin/Super Admin:**
- Can see all vehicles (all branches)
- Can assign vehicles from any branch to any job (cross-branch allowed)
- Example: Cape Town vehicle → Johannesburg job (allowed)

**Others:**
- Cannot see vehicles
- Cannot select vehicles (Admin must assign)

### Vehicle Branch Validation

**When Admin Assigns Vehicle to Job:**
- No branch validation required (cross-branch allowed)
- Admin can assign any vehicle to any job

---

## User Management Rules

### Role Assignment Permissions

**Super Admin:**
- ✅ Can assign any role (administrator, manager, driver_manager, driver)
- ✅ Can change user roles

**Admin:**
- ✅ Can assign manager, driver_manager, driver
- ❌ Cannot assign administrator or super_admin
- ❌ Cannot change user roles (Super Admin only)

**Manager:**
- ✅ Can assign driver_manager and driver (only in their branch)
- ❌ Cannot assign administrator, super_admin, or manager

**Driver Manager, Driver:**
- ❌ Cannot assign roles

### Activation/Deactivation

**Super Admin:**
- ✅ Can activate/deactivate users
- ✅ Can change user status

**Admin:**
- ❌ Cannot activate/deactivate users (Super Admin only)
- ❌ Cannot change user status (Super Admin only)

**Others:**
- ❌ Cannot activate/deactivate users

### Branch Assignment

**Admin/Super Admin:**
- **MUST** have `branch_id = NULL` (forced, national access)
- Cannot be assigned to a branch
- When creating/editing Admin/Super Admin user, force `branch_id = NULL`

**Manager, Driver Manager, Driver:**
- **MUST** have `branch_id` assigned (1, 2, or 3)
- Cannot have `branch_id = NULL`
- When creating/editing these users, require `branch_id` selection

### Missing Branch ID Updates

**Who Can Update:**
- ✅ Admin
- ✅ Super Admin

**What Can Be Updated:**
- Jobs with `branch_id = NULL`
- Vehicles with `branch_id = NULL`
- Users with `branch_id = NULL` (if role allows)

**How:**
- Admin/Super Admin can manually set `branch_id` when viewing/editing
- Should be prompted to set `branch_id` if NULL

---

## Implementation Requirements

### Router Guards

**Required Checks:**
1. Authentication check
2. Status check (`deactivated`, `suspended`)
3. Role assignment check (`unassigned`)
4. Route-level role permissions

**Protected Routes:**
- `/users` — Admin, Super Admin, Manager only
- `/vehicles` — Admin, Super Admin only
- `/clients` — Admin, Super Admin only (Manager, Driver Manager, Driver blocked)
- `/insights` — Admin, Super Admin, Manager only
- `/settings/notifications` — Super Admin only

### Permission Service

**Create:** `lib/core/services/permission_service.dart`

**Methods:**
- `canAccessRoute(route, userRole, userStatus)`
- `canAssignRole(assignerRole, targetRole)`
- `canActivateDeactivate(userRole)`
- `canViewClients(userRole)`
- `canViewVehicles(userRole)`
- `isBranchScoped(userRole)`
- `getBranchFilter(userRole, userBranchId)`

### Role Constants

**Create:** `lib/core/constants/roles.dart`

**Constants:**
- Role enum/constants
- Permission flags per role
- Branch requirement per role

### Job Filtering Service

**Update:** `lib/features/jobs/data/jobs_repository.dart`

**Driver Filtering:**
- Implement unconfirmed jobs (always visible)
- Implement confirmed jobs (1 day before start)
- Implement jobs without start date (always visible with indicator)

**Driver Manager Filtering:**
- Filter by `created_by` and `manager_id`
- Prevent duplicate if Driver Manager is also driver

### Vehicle Access Control

**Update Files:**
- `lib/features/vehicles/vehicles_screen.dart` — Add role check
- `lib/features/dashboard/dashboard_screen.dart` — Hide Vehicles card for non-admin
- `lib/shared/widgets/luxury_drawer.dart` — Hide Vehicles menu for non-admin
- `lib/app/app.dart` — Add route guard for `/vehicles`

### Manager Auto-Selection

**Update:** `lib/features/jobs/screens/create_job_screen.dart`

**Logic:**
- When Driver Manager creates job, query manager for their branch
- If manager exists, auto-select
- If no manager exists, only Admin can select manager
- Show warning if no manager for branch

---

## Edge Cases & Special Rules

### 1. Admin with Branch ID

**Rule:** Admin/Super Admin MUST have `branch_id = NULL`
**Implementation:** Force `branch_id = NULL` when creating/editing Admin/Super Admin user
**Validation:** Check on user creation/update, show error if branch_id is set

### 2. Suspended Role

**Rule:** Treated as status override, blocks all access
**Implementation:** Check in router guard and sign-in flow
**Message:** "Your account has been suspended. Please contact an administrator."

### 3. Jobs Without Start Date

**Rule:** Show as unconfirmed with indicator
**Implementation:** 
- Always visible for drivers
- Display indicator: "⚠️ No start date available"
- Treated as unconfirmed (can be confirmed by driver)

### 4. Driver Manager as Driver

**Rule:** Don't show job twice
**Implementation:** 
- Check if `driver_id = driver_manager_id` AND `manager_id = driver_manager_id`
- Show once as Driver Manager allocation
- Filter out from driver view if already shown in Driver Manager view

### 5. No Manager for Branch

**Rule:** Only Admin can select manager
**Implementation:**
- When Driver Manager creates job, check if manager exists for branch
- If no manager, hide manager dropdown for Driver Manager
- Show message: "No manager assigned to this branch. Administrator must assign manager."
- Admin can always select manager (even if not from that branch)

### 6. Missing Branch ID

**Rule:** Admin/Super Admin can update
**Implementation:**
- Show warning/indicator when `branch_id = NULL`
- Allow Admin/Super Admin to set `branch_id` when viewing/editing
- Prompt to set `branch_id` if NULL

### 7. Cross-Branch Vehicle Assignment

**Rule:** Admin/Super Admin can assign vehicles from any branch
**Implementation:**
- No branch validation when Admin assigns vehicle
- Show all vehicles in dropdown (no branch filter)
- Allow selection of any vehicle

### 8. Real-Time Permission Updates

**Rule:** Check permissions on route navigation
**Implementation:**
- Router guard checks on every navigation
- If user is deactivated/suspended during session, redirect to login
- If role changes, permissions update on next navigation (no forced logout)

---

## Testing Checklist

### Sign-In & Access

- [ ] Unassigned user → Redirected to `/pending-approval`
- [ ] Deactivated user → Blocked from sign-in
- [ ] Suspended user → Blocked from sign-in
- [ ] Active user with role → Can sign in and access app

### Role Assignment

- [ ] Super Admin can assign any role
- [ ] Admin can assign manager, driver_manager, driver
- [ ] Admin cannot assign administrator or super_admin
- [ ] Manager can assign driver_manager and driver (branch only)
- [ ] Manager cannot assign administrator, super_admin, or manager

### Activation/Deactivation

- [ ] Super Admin can activate/deactivate users
- [ ] Admin cannot activate/deactivate users
- [ ] Deactivated user cannot sign in
- [ ] Deactivated user is logged out if already signed in

### Branch Assignment

- [ ] Admin/Super Admin must have `branch_id = NULL`
- [ ] Manager, Driver Manager, Driver must have `branch_id` assigned
- [ ] Admin cannot be assigned to branch
- [ ] Non-admin cannot have `branch_id = NULL`

### Job Visibility

- [ ] Driver sees unconfirmed jobs (always)
- [ ] Driver sees confirmed jobs (1 day before start)
- [ ] Driver sees jobs without start date (with indicator)
- [ ] Driver Manager sees jobs they created
- [ ] Driver Manager sees jobs they allocated
- [ ] Driver Manager as driver doesn't see job twice
- [ ] Manager sees all jobs in branch
- [ ] Admin sees all jobs

### Vehicle Access

- [ ] Admin can see vehicles
- [ ] Super Admin can see vehicles
- [ ] Manager cannot see vehicles
- [ ] Driver Manager cannot see vehicles
- [ ] Driver cannot see vehicles
- [ ] Admin can assign vehicles from any branch
- [ ] Vehicles card hidden from dashboard for non-admin

### Client Access

- [ ] Admin can see clients
- [ ] Super Admin can see clients
- [ ] Manager cannot see clients
- [ ] Driver Manager cannot see clients
- [ ] Driver cannot see clients
- [ ] Clients route blocked for non-admin

### Manager Auto-Selection

- [ ] Driver Manager creates job → Manager auto-selected (if exists)
- [ ] No manager for branch → Only Admin can select manager
- [ ] Driver Manager cannot select manager if none exists

### Missing Branch ID

- [ ] Admin can update missing `branch_id` for jobs
- [ ] Admin can update missing `branch_id` for vehicles
- [ ] Warning shown when `branch_id = NULL`

---

## Migration Notes

### Existing Data

**Users:**
- Check for Admin/Super Admin with `branch_id != NULL` → Set to NULL
- Check for Manager/Driver Manager/Driver with `branch_id = NULL` → Require assignment
- Check for users with `role = null` → Set to 'unassigned' or assign role

**Jobs:**
- Check for jobs with `branch_id = NULL` → Admin can update
- Check for jobs with `job_start_date = NULL` → Show indicator

**Vehicles:**
- Check for vehicles with `branch_id = NULL` → Admin can update
- Ensure all vehicles have `branch_id` assigned

### Data Validation

**Before Implementation:**
1. Audit all users for correct `branch_id` assignment
2. Audit all jobs for `branch_id` assignment
3. Audit all vehicles for `branch_id` assignment
4. Identify users with `role = null` or `status = null`

**After Implementation:**
1. Verify Admin/Super Admin have `branch_id = NULL`
2. Verify non-admin users have `branch_id` assigned
3. Verify vehicle access is restricted to Admin/Super Admin
4. Verify client access is restricted to Admin/Super Admin

---

## Appendix

### Branch ID Constants

```dart
// From lib/features/branches/models/branch.dart
static const int durbanId = 1;           // 'Dbn'
static const int capeTownId = 2;         // 'Cpt'
static const int johannesburgId = 3;     // 'Jhb'
```

### Database Schema Reference

- **profiles.role:** `user_role_enum` (administrator, manager, driver_manager, driver, suspended, super_admin)
- **profiles.status:** text (active, deactivated, unassigned)
- **profiles.branch_id:** bigint (NULL = Admin/National, 1/2/3 = Branch)
- **jobs.branch_id:** bigint (FK to branches.id)
- **jobs.job_start_date:** date (nullable)
- **vehicles.branch_id:** bigint (FK to branches.id, required)

---

**End of Specification**

