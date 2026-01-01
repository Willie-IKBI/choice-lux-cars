# Batch D — Job Visibility Implementation Points

**Date:** 2025-01-XX  
**Purpose:** Identify repository/data-layer files responsible for fetching job lists for drivers and driver managers  
**No modifications made**

---

## Driver Job List Fetching

### lib/features/jobs/data/jobs_repository.dart

**Method:** `fetchJobs({String? userId, String? userRole, int? branchId})`  
**Role Support:** Driver, Driver Manager, Manager, Admin, Super Admin  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** Yes (applied if `branchId != null`)  
**Driver Logic:** `query.eq('driver_id', userId)` - filters by driver_id only  
**Notes:** No driver confirmation/start date filtering implemented

**Method:** `getJobsByStatus(String status, {String? userId, String? userRole})`  
**Role Support:** Driver, Driver Manager, Manager, Admin, Super Admin  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** No (not applied in this method)  
**Driver Logic:** `query.eq('driver_id', userId)` - filters by driver_id only  
**Notes:** No driver confirmation/start date filtering implemented

**Method:** `getJobsByClient(String clientId, {String? userId, String? userRole, int? branchId})`  
**Role Support:** Driver, Driver Manager, Manager, Admin, Super Admin  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** Yes (applied if `branchId != null`)  
**Driver Logic:** `query.eq('driver_id', userId)` - filters by driver_id only  
**Notes:** No driver confirmation/start date filtering implemented

**Method:** `getCompletedJobsByClient(String clientId, {String? userId, String? userRole, int? branchId})`  
**Role Support:** Driver, Driver Manager, Manager, Admin, Super Admin  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** Yes (applied if `branchId != null`)  
**Driver Logic:** `query.eq('driver_id', userId)` - filters by driver_id only  
**Notes:** No driver confirmation/start date filtering implemented

**Method:** `getCompletedJobsRevenueByClient(String clientId, {String? userId, String? userRole, int? branchId})`  
**Role Support:** Driver, Driver Manager, Manager, Admin, Super Admin  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** Yes (applied if `branchId != null`)  
**Driver Logic:** `query.eq('driver_id', userId)` - filters by driver_id only  
**Notes:** No driver confirmation/start date filtering implemented

**Method:** `getJobsByDriver(String driverId)`  
**Role Support:** Generic (any role can call)  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** No (not applied)  
**Driver Logic:** `query.eq('driver_id', driverId)` - filters by driver_id only  
**Notes:** Generic method, no role-based access control

---

## Driver Manager Job List Fetching

### lib/features/jobs/data/jobs_repository.dart

**Method:** `fetchJobs({String? userId, String? userRole, int? branchId})`  
**Role Support:** Driver, Driver Manager, Manager, Admin, Super Admin  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** Yes (applied if `branchId != null`)  
**Driver Manager Logic:** `query.or('manager_id.eq.$userId,driver_id.eq.$userId)` - combines manager and driver roles  
**Notes:** Driver Manager grouped with Manager in same condition. Uses `manager_id` OR `driver_id`. No `created_by` filter. Potential duplicate if Driver Manager is also driver.

**Method:** `getJobsByStatus(String status, {String? userId, String? userRole})`  
**Role Support:** Driver, Driver Manager, Manager, Admin, Super Admin  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** No (not applied in this method)  
**Driver Manager Logic:** `query.or('created_by.eq.$userId,driver_id.eq.$userId)` - uses created_by OR driver_id  
**Notes:** Different logic than `fetchJobs` - uses `created_by` instead of `manager_id`. Potential duplicate if Driver Manager is also driver.

**Method:** `getJobsByClient(String clientId, {String? userId, String? userRole, int? branchId})`  
**Role Support:** Driver, Driver Manager, Manager, Admin, Super Admin  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** Yes (applied if `branchId != null`)  
**Driver Manager Logic:** `query.or('created_by.eq.$userId,driver_id.eq.$userId)` - uses created_by OR driver_id  
**Notes:** Potential duplicate if Driver Manager is also driver.

**Method:** `getCompletedJobsByClient(String clientId, {String? userId, String? userRole, int? branchId})`  
**Role Support:** Driver, Driver Manager, Manager, Admin, Super Admin  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** Yes (applied if `branchId != null`)  
**Driver Manager Logic:** `query.or('created_by.eq.$userId,driver_id.eq.$userId)` - uses created_by OR driver_id  
**Notes:** Potential duplicate if Driver Manager is also driver.

**Method:** `getCompletedJobsRevenueByClient(String clientId, {String? userId, String? userRole, int? branchId})`  
**Role Support:** Driver, Driver Manager, Manager, Admin, Super Admin  
**Filtering:** SQL (PostgrestFilterBuilder)  
**Branch Filtering:** Yes (applied if `branchId != null`)  
**Driver Manager Logic:** `query.or('created_by.eq.$userId,driver_id.eq.$userId)` - uses created_by OR driver_id  
**Notes:** Potential duplicate if Driver Manager is also driver.

---

## Provider Layer

### lib/features/jobs/providers/jobs_provider.dart

**Method:** `_fetchJobs()`  
**Role Support:** All roles (delegates to repository)  
**Filtering:** Delegated to repository (SQL)  
**Branch Filtering:** Yes (passes `branchId` from `userProfile?.branchId`)  
**Notes:** Calls `jobsRepository.fetchJobs()` with userId, userRole, branchId

**Method:** `getJobsByStatus(String status)`  
**Role Support:** Generic (does not pass userId/userRole to repository)  
**Filtering:** Delegated to repository (SQL)  
**Branch Filtering:** No (not passed to repository)  
**Notes:** Calls `jobsRepository.getJobsByStatus()` without userId/userRole - potential gap

**Method:** `getJobsByClient(String clientId, {int? branchId})`  
**Role Support:** All roles (delegates to repository)  
**Filtering:** Delegated to repository (SQL)  
**Branch Filtering:** Yes (passes `effectiveBranchId` to repository)  
**Notes:** Calls `jobsRepository.getJobsByClient()` with userId, userRole, branchId

**Method:** `getJobsByDriver(String driverId)`  
**Role Support:** Generic (any role can call)  
**Filtering:** Delegated to repository (SQL)  
**Branch Filtering:** No (not applied)  
**Notes:** Calls `jobsRepository.getJobsByDriver()` - generic method

---

## Summary

**Primary Implementation File:** `lib/features/jobs/data/jobs_repository.dart`

**Driver Filtering:**
- All methods use: `query.eq('driver_id', userId)`
- Filtering: SQL
- Branch filtering: Applied in most methods (except `getJobsByStatus`, `getJobsByDriver`)
- Missing: Driver confirmation rules, start date filtering

**Driver Manager Filtering:**
- Inconsistent logic:
  - `fetchJobs()`: Uses `manager_id OR driver_id`
  - Other methods: Use `created_by OR driver_id`
- Filtering: SQL
- Branch filtering: Applied in most methods (except `getJobsByStatus`)
- Missing: Deduplication when Driver Manager is also driver, `manager_id` filter in some methods

**Provider Layer:**
- `jobs_provider.dart` delegates to repository
- Branch filtering passed from `userProfile?.branchId`
- Gap: `getJobsByStatus()` does not pass userId/userRole to repository

---

**End of Report**

