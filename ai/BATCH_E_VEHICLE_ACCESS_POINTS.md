# Batch E — Vehicle Access Points Audit

**Date:** 2025-01-XX  
**Purpose:** Identify all vehicle-related access points in the codebase  
**No modifications made**

---

## 1. Vehicle List Screens

### lib/features/vehicles/vehicles_screen.dart
**Purpose:** Main vehicle list screen displaying all vehicles in a grid layout  
**Access Control:** None - screen is accessible to all authenticated users  
**Notes:** No role-based access check. FAB allows adding vehicles without permission check.

---

## 2. Vehicle Detail/Edit Screens

### lib/features/vehicles/vehicle_editor_screen.dart
**Purpose:** Screen for creating new vehicles or editing existing vehicles  
**Access Control:** Partial - branch dropdown only visible to admin (`isAdmin` check at line 784)  
**Notes:** No role check to prevent non-admin access to the screen itself. Branch assignment restricted to admin only.

---

## 3. Vehicle Repositories/Queries

### lib/features/vehicles/data/vehicles_repository.dart
**Purpose:** Data access layer for vehicle operations (CRUD)  
**Access Control:** Branch filtering only - `fetchVehicles({int? branchId})` filters by branch if provided  
**Methods:**
- `fetchVehicles({int? branchId})` - Filters by branch if branchId provided, otherwise returns all
- `fetchVehicleById(String vehicleId)` - No access control
- `createVehicle(Vehicle vehicle)` - No access control
- `updateVehicle(Vehicle vehicle)` - No access control
- `deleteVehicle(String vehicleId)` - No access control
- `getVehiclesByMake(String make)` - No access control
- `getAvailableVehicles()` - No access control
- `searchVehicles(String query)` - No access control
- `updateVehicleStatus(String vehicleId, String status)` - No access control

**Notes:** Repository methods have no role-based access control. Branch filtering is applied at provider level.

### lib/features/vehicles/providers/vehicles_provider.dart
**Purpose:** State management for vehicles using Riverpod  
**Access Control:** Branch filtering - automatically filters by `currentUser?.branchId` in `build()` method  
**Notes:** Admin users (branchId == null) see all vehicles. Non-admin users see only vehicles from their branch.

---

## 4. Navigation Menu Items

### lib/shared/widgets/luxury_drawer.dart
**Purpose:** Navigation drawer with menu items  
**Access Control:** None - no vehicle menu item found in drawer  
**Notes:** Vehicles are not listed in the navigation drawer menu. Access is via dashboard card or direct route navigation.

---

## 5. Dashboard Cards

### lib/features/dashboard/dashboard_screen.dart
**Purpose:** Main dashboard displaying navigation cards for different features  
**Access Control:** None - vehicle card is always visible (lines 326-332)  
**Notes:** Dashboard card for vehicles is displayed to all users without role check. Card routes to `/vehicles`.

---

## 6. Job Creation Vehicle Selectors

### lib/features/jobs/screens/create_job_screen.dart
**Purpose:** Job creation/edit form with vehicle selection dropdown  
**Access Control:** Branch filtering - `_buildVehicleDropdown()` filters vehicles by user's branch (lines 1791-1798)  
**Logic:**
- Non-admin users (branchId != null): Only see vehicles from their branch
- Admin users (branchId == null): See all vehicles
**Notes:** Filtering is applied in UI layer, not at repository level. No role check to restrict vehicle selection capability.

---

## 7. Route Definitions

### lib/app/app.dart
**Purpose:** GoRouter configuration with route definitions  
**Access Control:** Router guard - `/vehicles` route protected by `RouterGuards.guardRoute()` (line 70)  
**Routes:**
- `/vehicles` (line 290) - VehicleListScreen
- `/vehicles/edit` (line 295) - VehicleEditorScreen
**Notes:** Routes are protected by router guard which checks authentication and role. Vehicle route access is enforced at router level (Batch B implementation).

---

## 8. Vehicle Display in Other Contexts

### lib/features/jobs/jobs_screen.dart
**Purpose:** Jobs list screen that displays vehicle information  
**Access Control:** None - vehicles are displayed as part of job information  
**Notes:** Vehicles are shown in job cards for informational purposes only. No direct vehicle access control.

### lib/features/insights/screens/vehicle_insights_tab.dart
**Purpose:** Insights tab showing vehicle-related analytics  
**Access Control:** Unknown - file not fully examined  
**Notes:** Vehicle insights may have role-based access restrictions (insights screen has role checks).

---

## Summary

**Access Control Status:**
- **Router Level:** Protected by router guards (Batch B implementation)
- **Screen Level:** No role checks on vehicle list or editor screens
- **Repository Level:** No role checks, only branch filtering
- **Provider Level:** Branch filtering applied automatically
- **UI Level:** Branch filtering in job creation dropdown
- **Navigation:** No vehicle menu item in drawer
- **Dashboard:** Vehicle card visible to all users

**Gaps Identified:**
1. Vehicle list screen (`vehicles_screen.dart`) has no role check
2. Vehicle editor screen (`vehicle_editor_screen.dart`) has no role check to prevent access
3. Repository methods have no role-based access control
4. Dashboard card for vehicles is visible to all users
5. FAB in vehicle list screen allows adding vehicles without permission check

---

**End of Report**

