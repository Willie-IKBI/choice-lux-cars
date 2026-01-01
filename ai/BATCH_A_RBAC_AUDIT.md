# Batch A — Pre-flight RBAC Audit

**Date:** 2025-01-XX  
**Purpose:** Read-only audit of existing RBAC implementation  
**No modifications made**

---

## 1. Router / Navigation Guard Locations

### lib/core/router/guards.dart
**Purpose:** Centralized router guard implementation for authentication and authorization  
**RBAC Logic:** Partial
- Checks authentication (`isAuthenticated`)
- Checks role assignment (`hasAssignedRole` - checks for 'unassigned')
- Redirects unassigned users to `/pending-approval`
- No status checks (deactivated, suspended)
- No route-level role permissions
- Methods `hasRole`, `canAccessAdmin` are stubs (return false/true without logic)

### lib/app/app.dart
**Purpose:** GoRouter configuration with global redirect logic  
**RBAC Logic:** Partial
- Uses `RouterGuards.guardRoute()` for all routes
- No route-specific role guards
- All routes use same guard logic

---

## 2. Role / Status Checks

### lib/features/auth/providers/auth_provider.dart
**Purpose:** User authentication state and profile management  
**RBAC Logic:** Yes
- `UserProfile` model with `role`, `status`, `branchId` fields
- Getters: `isAdmin`, `isSuperAdmin`, `isManager`, `isDriverManager`, `isDriver`
- `isAdmin` includes both 'administrator' and 'super_admin'
- No status check during sign-in (deactivated users can sign in)
- No suspended role handling

### lib/features/users/users_screen.dart
**Purpose:** User management screen  
**RBAC Logic:** Yes
- Access check: `isAdmin || isManager` (blocks Driver Manager, Driver)
- Role dropdown includes 'agent' (inconsistent with DB enum)
- Status toggle restricted to `isAdmin` only
- No Super Admin distinction for activation/deactivation

### lib/features/users/widgets/user_form.dart
**Purpose:** User create/edit form  
**RBAC Logic:** Yes
- Role assignment: Only `isSuperAdmin` can assign roles
- Status assignment: `isAdmin` can assign status
- Branch assignment: `isAdmin` can assign branch (dropdown visible)
- Role dropdown includes 'agent' (inconsistent with DB enum)

### lib/features/users/providers/users_provider.dart
**Purpose:** User state management  
**RBAC Logic:** Yes
- Role change check: Only `isSuperAdmin` can change roles
- Branch filtering: Filters users by `branchId` (admin sees all, non-admin sees branch only)
- No activation/deactivation logic in provider

### lib/features/dashboard/dashboard_screen.dart
**Purpose:** Main dashboard with role-based cards  
**RBAC Logic:** Yes
- Role-based card visibility: `isDriver`, `isAdmin`, `isManager`
- Drivers see only Jobs card
- Admin/Manager see all cards (Users, Clients, Vehicles, Quotes, Jobs, Insights)
- Insights card: Only `isAdmin || isManager`

### lib/shared/widgets/luxury_drawer.dart
**Purpose:** Navigation drawer  
**RBAC Logic:** Yes
- Administration section: Only shown if `isAdmin`
- No role-specific menu item hiding (all users see same menu structure)

### lib/features/insights/screens/insights_screen.dart
**Purpose:** Business insights screen  
**RBAC Logic:** Yes
- Access check: `isAdmin || isManager` (blocks Driver Manager, Driver)
- Tab count: Admin sees 5 tabs, Manager sees 1 tab (Jobs only)

### lib/features/notifications/screens/notification_preferences_screen.dart
**Purpose:** Notification preferences management  
**RBAC Logic:** Yes
- Access check: Only `isSuperAdmin` can access
- Shows access denied message for non-Super Admin

### lib/features/vehicles/vehicle_editor_screen.dart
**Purpose:** Vehicle create/edit screen  
**RBAC Logic:** Partial
- Branch dropdown: Only visible if `isAdmin`
- No access restriction to screen itself

---

## 3. Job List / Job Query Filtering Logic

### lib/features/jobs/data/jobs_repository.dart
**Purpose:** Job data access layer with role-based filtering  
**RBAC Logic:** Yes
- `fetchJobs()`: Role-based filtering
  - Admin/Super Admin: See all jobs (no filter)
  - Manager/Driver Manager: `OR(manager_id.eq.userId, driver_id.eq.userId)`
  - Driver: `driver_id.eq.userId`
  - Branch filtering: Applied after role filter (if `branchId != null`)
- `getJobsByStatus()`: Same role-based logic
- `getJobsByClient()`: Same role-based logic with client filter
- `getCompletedJobsByClient()`: Same role-based logic
- `getCompletedJobsRevenueByClient()`: Same role-based logic
- No driver confirmation/start date filtering (unconfirmed always visible, confirmed 1 day before)
- No handling for jobs without start date
- Driver Manager logic: Uses `OR(created_by.eq.userId, driver_id.eq.userId)` - potential duplicate if Driver Manager is also driver

### lib/features/jobs/jobs_screen.dart
**Purpose:** Job list UI  
**RBAC Logic:** Partial
- No role-based access restriction
- UI-level filtering by status, month, search
- No driver-specific visibility rules (unconfirmed always, confirmed 1 day before)

### lib/features/jobs/providers/jobs_provider.dart
**Purpose:** Job state management  
**RBAC Logic:** Partial
- Calls `jobsRepository.fetchJobs()` with `userId`, `userRole`, `branchId`
- No additional filtering logic

---

## 4. Vehicle-Related Routes, Screens, and Repositories

### lib/features/vehicles/vehicles_screen.dart
**Purpose:** Vehicle list screen  
**RBAC Logic:** No
- No role-based access check
- All users can access vehicle list

### lib/features/vehicles/vehicle_editor_screen.dart
**Purpose:** Vehicle create/edit screen  
**RBAC Logic:** Partial
- Branch dropdown: Only visible if `isAdmin`
- No access restriction to screen itself

### lib/features/vehicles/data/vehicles_repository.dart
**Purpose:** Vehicle data access layer  
**RBAC Logic:** Partial
- `fetchVehicles()`: Filters by `branchId` if provided (admin sees all, non-admin sees branch only)
- No role-based access restriction

### lib/features/vehicles/providers/vehicles_provider.dart
**Purpose:** Vehicle state management  
**RBAC Logic:** Partial
- Filters vehicles by `currentUser?.branchId` (admin sees all, non-admin sees branch only)
- No role-based access restriction

### lib/app/app.dart
**Purpose:** Route definitions  
**RBAC Logic:** No
- Routes `/vehicles` and `/vehicles/edit` defined
- No route-level guards

---

## 5. User Management Entry Points

### lib/features/users/users_screen.dart
**Purpose:** User list and management screen  
**RBAC Logic:** Yes
- Access check: `isAdmin || isManager` (blocks Driver Manager, Driver)
- Role filtering UI
- Status filtering UI
- Status toggle: Restricted to `isAdmin` only (should be Super Admin)

### lib/features/users/user_detail_screen.dart
**Purpose:** User detail view (referenced in routes)  
**RBAC Logic:** Unknown (file not read)

### lib/features/users/widgets/user_form.dart
**Purpose:** User create/edit form  
**RBAC Logic:** Yes
- Role assignment: Only `isSuperAdmin`
- Status assignment: `isAdmin` (should be Super Admin)
- Branch assignment: `isAdmin`

### lib/features/users/providers/users_provider.dart
**Purpose:** User state management  
**RBAC Logic:** Yes
- Role change validation: Only `isSuperAdmin` can change roles
- Branch filtering: Admin sees all, non-admin sees branch only

### lib/features/users/data/users_repository.dart
**Purpose:** User data access layer  
**RBAC Logic:** Partial
- `fetchUsers()`: Filters by `branchId` if provided
- `updateUser()`: Updates user including `branch_id`
- `deactivateUser()`: Sets status to 'deactivated'
- `activateUser()`: Sets status to 'active'
- No role-based access restrictions

### lib/app/app.dart
**Purpose:** Route definitions  
**RBAC Logic:** No
- Routes `/users` and `/users/:id` defined
- No route-level guards

---

## Summary

### RBAC Implementation Status

**Router Guards:** Partial
- Basic authentication and unassigned role check
- Missing: Status checks (deactivated, suspended)
- Missing: Route-level role permissions

**Role Checks:** Yes (scattered across UI)
- Multiple files check roles using `isAdmin`, `isManager`, `isSuperAdmin`, etc.
- Inconsistent: Some use `isAdmin` (includes super_admin), some check `role == 'super_admin'`
- Missing: Centralized permission service

**Status Checks:** No
- No status checks during sign-in
- No status checks in router guards
- No suspended role handling

**Job Filtering:** Yes (in repository)
- Role-based filtering implemented
- Missing: Driver confirmation/start date rules (unconfirmed always, confirmed 1 day before)
- Missing: Jobs without start date handling
- Missing: Driver Manager duplicate prevention

**Vehicle Access:** Partial
- Branch filtering implemented
- Missing: Role-based access restriction (should be Admin/Super Admin only)
- Missing: Route-level guards

**User Management:** Yes (with inconsistencies)
- Role assignment: Super Admin only (correct)
- Status assignment: Admin only (should be Super Admin only)
- Access: Admin and Manager (should be Admin, Super Admin, Manager only)
- Missing: Branch assignment validation (Admin/Super Admin must have NULL)

---

**End of Audit**

