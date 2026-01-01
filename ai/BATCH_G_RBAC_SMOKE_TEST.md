# Batch G — RBAC Smoke Test

**Purpose:** Manual validation checklist for UI and routing per role  
**Date:** 2025-01-20  
**Status:** Ready for Testing

---

## Test Instructions

1. **Test each role independently** — Use separate test accounts for each role
2. **Verify both routing and UI** — Check router guards AND UI visibility
3. **Test edge cases** — Unassigned, suspended, deactivated users
4. **Document results** — Mark ✅ (pass), ❌ (fail), or ⚠️ (partial/needs review)

---

## 1. Authentication & Status Override Tests

| Test Case | Role/Status | Expected Behavior | Result | Notes |
|-----------|------------|-------------------|--------|-------|
| Deactivated user login | status='deactivated' | Redirect to /login, cannot access app | | |
| Suspended user login | role='suspended' | Redirect to /login, cannot access app | | |
| Unassigned user login | role=null or 'unassigned' | Redirect to /pending-approval, cannot access other routes | | |
| Unassigned user on /pending-approval | role=null or 'unassigned' | Can access /pending-approval only | | |
| Active user on auth routes | Any active role | Redirect to / (dashboard) | | |

---

## 2. Router Guard Tests

| Route | Super Admin | Admin | Manager | Driver Manager | Driver | Unassigned | Result | Notes |
|-------|-------------|-------|---------|----------------|--------|------------|--------|-------|
| `/` (dashboard) | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | | |
| `/users` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| `/users/:id` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| `/vehicles` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | | |
| `/vehicles/edit` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | | |
| `/clients` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | | |
| `/clients/add` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | | |
| `/clients/:id` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | | |
| `/clients/edit/:id` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | | |
| `/insights` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| `/notification-settings` | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | | |
| `/jobs` | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | | |
| `/jobs/create` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | | |
| `/jobs/:id/summary` | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | | |
| `/jobs/:id/edit` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | | |
| `/quotes` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | | |
| `/quotes/create` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | | |
| `/invoices` | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | | |
| `/vouchers` | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ | | |

---

## 3. Dashboard Cards Visibility

| Card | Super Admin | Admin | Manager | Driver Manager | Driver | Result | Notes |
|------|-------------|-------|---------|----------------|--------|--------|-------|
| Manage Users | ✅ | ✅ | ✅ | ❌ | ❌ | | |
| Clients | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Vehicles | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Quotes | ✅ | ✅ | ✅ | ✅ | ❌ | | |
| Jobs | ✅ | ✅ | ✅ | ✅ | ✅ | | |
| Insights | ✅ | ✅ | ✅ | ❌ | ❌ | | |

---

## 4. FAB Visibility Tests

| Screen | FAB Action | Super Admin | Admin | Manager | Driver Manager | Driver | Result | Notes |
|--------|------------|-------------|-------|---------|----------------|--------|--------|-------|
| Clients | Add Client | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Vehicles | Add Vehicle | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Quotes | Create Quote | ✅ | ✅ | ✅ | ✅ | ❌ | | |
| Jobs | Create Job | ✅ | ✅ | ✅ | ✅ | ❌ | | |
| Invoices | Create Invoice | ✅ | ✅ | ✅ | ✅ | ❌ | | |
| Vouchers | Create Voucher | ✅ | ✅ | ✅ | ✅ | ❌ | | |
| Trip Management | Add Trip | ✅ | ✅ | ✅ | ✅ | ❌ | | |

---

## 5. Drawer Menu Visibility

| Menu Item | Super Admin | Admin | Manager | Driver Manager | Driver | Result | Notes |
|-----------|-------------|-------|---------|----------------|--------|--------|-------|
| Administration section | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| User Management (in Admin section) | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| User Management (in Management section) | ❌ | ❌ | ✅ | ❌ | ❌ | | |
| System Settings | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Business Insights (in Admin section) | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Business Insights (in Management section) | ❌ | ❌ | ✅ | ❌ | ❌ | | |

---

## 6. Screen-Level Access Control

| Screen | Super Admin | Admin | Manager | Driver Manager | Driver | Result | Notes |
|--------|-------------|-------|---------|----------------|--------|--------|-------|
| Users Screen | ✅ | ✅ | ✅ | ❌ | ❌ | | |
| Vehicles Screen | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Vehicle Editor Screen | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Clients Screen | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Insights Screen | ✅ | ✅ | ✅ | ❌ | ❌ | | |
| Notification Preferences Screen | ✅ | ❌ | ❌ | ❌ | ❌ | | |

---

## 7. Action Button Visibility (Inside Screens)

| Screen/Widget | Action | Super Admin | Admin | Manager | Driver Manager | Driver | Result | Notes |
|---------------|--------|-------------|-------|---------|----------------|--------|--------|-------|
| Client Card | Edit Client | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Client Card | Manage Agents | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Client Card | Deactivate Client | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Agent Card | Edit Agent | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Agent Card | Delete Agent | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Job Summary | Edit Job | ✅ | ✅ | ✅ | ❌ | ❌ | | |
| Job Summary | Cancel Job | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| Job Summary | Confirm Job | ❌ | ❌ | ❌ | ❌ | ✅ (if assigned) | | |
| Job Summary | Trip Management | ✅ | ✅ | ✅ | ❌ | ❌ | | |
| User Form | Role dropdown | ✅ | ❌ | ❌ | ❌ | ❌ | | |
| User Form | Status dropdown | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| User Form | Branch dropdown | ✅ | ✅ | ❌ | ❌ | ❌ | | |
| User Form | Deactivate button | ✅ | ✅ | ❌ | ❌ | ❌ | | |

---

## 8. Job Visibility Rules (Driver)

| Test Case | Expected Behavior | Result | Notes |
|-----------|-------------------|--------|-------|
| Unconfirmed job (assigned to driver) | ✅ Visible | | |
| Confirmed job (assigned to driver, start date today) | ✅ Visible | | |
| Confirmed job (assigned to driver, start date tomorrow) | ✅ Visible | | |
| Confirmed job (assigned to driver, start date 2+ days away) | ❌ Not visible | | |
| Job with no start date (assigned to driver) | ✅ Visible (with indicator) | | |
| Job not assigned to driver | ❌ Not visible | | |

---

## 9. Job Visibility Rules (Driver Manager)

| Test Case | Expected Behavior | Result | Notes |
|-----------|-------------------|--------|-------|
| Job created by driver manager | ✅ Visible | | |
| Job with manager_id = driver manager | ✅ Visible | | |
| Job where driver manager is also driver | ✅ Visible once (no duplicate) | | |
| Job not created/allocated by driver manager | ❌ Not visible | | |

---

## 10. Branch Scoping Tests

| Test Case | Role | Branch ID | Expected Behavior | Result | Notes |
|-----------|------|-----------|-------------------|--------|-------|
| Admin viewing jobs | Admin | NULL | See all jobs (national) | | |
| Manager viewing jobs | Manager | 1 (Durban) | See only Durban jobs | | |
| Driver Manager viewing jobs | Driver Manager | 2 (Cape Town) | See only Cape Town jobs | | |
| Driver viewing jobs | Driver | 3 (Johannesburg) | See only Johannesburg jobs | | |
| Admin assigning vehicle | Admin | NULL | Can assign any branch vehicle | | |
| Manager assigning vehicle | Manager | 1 (Durban) | Can only assign Durban vehicles | | |

---

## 11. Edge Cases

| Test Case | Expected Behavior | Result | Notes |
|-----------|-------------------|--------|-------|
| User with role='agent' (legacy) | Treated as unassigned? | | |
| User with null branch_id (non-admin) | Should be set by Admin | | |
| Job with null branch_id | Should be updatable by Admin | | |
| Vehicle with null branch_id | Should be updatable by Admin | | |
| Manager trying to access /vehicles directly | Redirect to / | | |
| Driver trying to access /clients directly | Redirect to / | | |
| Driver Manager trying to access /insights directly | Redirect to / | | |

---

## Test Results Summary

**Total Test Cases:** ___  
**Passed:** ___  
**Failed:** ___  
**Needs Review:** ___

**Critical Issues Found:**
1. 
2. 
3. 

**Minor Issues Found:**
1. 
2. 
3. 

**Tested By:** _______________  
**Date:** _______________  
**Sign-off:** _______________

