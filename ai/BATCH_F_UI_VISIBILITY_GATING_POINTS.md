# Batch F — UI Visibility Gating Points Audit

## 1. Dashboard Cards

| File Path | UI Element | Current Visibility Behavior | Expected Visibility (Role/Status) |
|-----------|------------|----------------------------|-----------------------------------|
| `lib/features/dashboard/dashboard_screen.dart` | Manage Users card | Conditional: `isAdmin \|\| isManager` | Admin, Manager |
| `lib/features/dashboard/dashboard_screen.dart` | Clients card | Always visible (except for drivers) | Admin, Super Admin, Manager, Driver Manager (NOT Driver) |
| `lib/features/dashboard/dashboard_screen.dart` | Vehicles card | Conditional: `PermissionService().canAccessVehicles(userRole)` | Admin, Super Admin |
| `lib/features/dashboard/dashboard_screen.dart` | Quotes card | Always visible (except for drivers) | Admin, Super Admin, Manager, Driver Manager (NOT Driver) |
| `lib/features/dashboard/dashboard_screen.dart` | Jobs card | Always visible | All roles |
| `lib/features/dashboard/dashboard_screen.dart` | Insights card | Conditional: `isAdmin \|\| isManager` | Admin, Manager |

## 2. FABs and Primary Action Buttons

| File Path | UI Element | Current Visibility Behavior | Expected Visibility (Role/Status) |
|-----------|------------|----------------------------|-----------------------------------|
| `lib/features/quotes/quotes_screen.dart` | Create Quote FAB | Conditional: `canCreateQuotes` | Admin, Super Admin, Manager, Driver Manager |
| `lib/features/clients/clients_screen.dart` | Add Client FAB | Always visible | Admin, Super Admin (per spec: Managers, Driver Managers, Drivers cannot see clients) |
| `lib/features/vehicles/vehicles_screen.dart` | Add Vehicle FAB | Conditional: `PermissionService().canAccessVehicles(userRole)` | Admin, Super Admin |
| `lib/features/jobs/jobs_screen.dart` | Create Job button (in search section) | Conditional: `canCreateJobs` | Admin, Super Admin, Manager, Driver Manager |
| `lib/features/invoices/invoices_screen.dart` | Create Invoice FAB | Always visible | Admin, Super Admin, Manager, Driver Manager |
| `lib/features/vouchers/vouchers_screen.dart` | Create Voucher FAB | Always visible | Admin, Super Admin, Manager, Driver Manager |
| `lib/features/jobs/screens/trip_management_screen.dart` | Add Trip FAB | Always visible | Admin, Super Admin, Manager, Driver Manager (when editing job) |

## 3. Menu / Drawer Items

| File Path | UI Element | Current Visibility Behavior | Expected Visibility (Role/Status) |
|-----------|------------|----------------------------|-----------------------------------|
| `lib/shared/widgets/luxury_drawer.dart` | Administration section | Conditional: `isAdmin` | Admin, Super Admin |
| `lib/shared/widgets/luxury_drawer.dart` | User Management menu item | Conditional: `isAdmin` | Admin, Super Admin, Manager |
| `lib/shared/widgets/luxury_drawer.dart` | System Settings menu item | Conditional: `isAdmin` | Admin, Super Admin |
| `lib/shared/widgets/luxury_drawer.dart` | Business Insights menu item | Conditional: `isAdmin` | Admin, Super Admin, Manager |

## 4. Admin-Only Actions Inside Screens

| File Path | UI Element | Current Visibility Behavior | Expected Visibility (Role/Status) |
|-----------|------------|----------------------------|-----------------------------------|
| `lib/features/users/widgets/user_form.dart` | Role dropdown | Conditional: `isSuperAdmin` | Super Admin only |
| `lib/features/users/widgets/user_form.dart` | Status dropdown | Conditional: `isAdmin` | Admin, Super Admin |
| `lib/features/users/widgets/user_form.dart` | Branch dropdown | Conditional: `isAdmin` | Admin, Super Admin |
| `lib/features/users/widgets/user_form.dart` | Deactivate button | Conditional: `canDeactivate` prop | Admin, Super Admin (when editing existing user) |
| `lib/features/jobs/screens/job_summary_screen.dart` | Edit Job button | Conditional: `canEdit = (isAdmin \|\| isManager) && !isCancelled` | Admin, Manager (when job not cancelled) |
| `lib/features/jobs/screens/job_summary_screen.dart` | Cancel Job button | Conditional: `canCancel = isAdmin && !isCancelled` | Admin only (when job not cancelled) |
| `lib/features/jobs/screens/job_summary_screen.dart` | Trip Management buttons (View All Trips, Add Another Trip) | Conditional: `canEdit = (isAdmin \|\| isManager) && !isCancelled` | Admin, Manager (when job not cancelled) |
| `lib/features/jobs/screens/job_summary_screen.dart` | Confirm Job button | Conditional: `needsConfirmation = isAssignedDriver && !isConfirmed && !isCancelled` | Driver only (when assigned and not confirmed) |
| `lib/features/clients/widgets/client_card.dart` | Edit Client button | Always visible | Admin, Super Admin (per spec: Managers, Driver Managers, Drivers cannot see clients) |
| `lib/features/clients/widgets/client_card.dart` | Manage Agents button | Always visible | Admin, Super Admin (per spec: Managers, Driver Managers, Drivers cannot see clients) |
| `lib/features/clients/widgets/client_card.dart` | Deactivate Client button | Always visible | Admin, Super Admin (per spec: Managers, Driver Managers, Drivers cannot see clients) |
| `lib/features/clients/widgets/agent_card.dart` | Edit Agent button | Always visible | Admin, Super Admin (per spec: Managers, Driver Managers, Drivers cannot see clients) |
| `lib/features/clients/widgets/agent_card.dart` | Delete Agent button | Always visible | Admin, Super Admin (per spec: Managers, Driver Managers, Drivers cannot see clients) |
| `lib/features/quotes/screens/quote_details_screen.dart` | Edit Quote button | Conditional: `_canEdit` getter | Admin, Super Admin, Manager, Driver Manager |
| `lib/features/jobs/widgets/job_list_card.dart` | Create Voucher button | Conditional: `canCreateVoucher` prop | Admin, Super Admin, Manager, Driver Manager |
| `lib/features/jobs/widgets/job_list_card.dart` | Create Invoice button | Conditional: `canCreateInvoice` prop | Admin, Super Admin, Manager, Driver Manager |

## 5. Status-Based UI

| File Path | UI Element | Current Visibility Behavior | Expected Visibility (Role/Status) |
|-----------|------------|----------------------------|-----------------------------------|
| `lib/features/users/users_screen.dart` | Hide Deactivated toggle | Always visible | Admin, Manager (for filtering) |
| `lib/features/users/widgets/user_form.dart` | Status field (read-only) | Conditional: `!isAdmin` | Non-admin users see read-only status |
| `lib/features/users/widgets/user_form.dart` | Status field (editable) | Conditional: `isAdmin` | Admin, Super Admin can edit status |
| `lib/features/jobs/screens/job_summary_screen.dart` | Job Confirmed button (disabled state) | Conditional: `isAssignedDriver && isConfirmed` | Driver only (when job is confirmed) |
| `lib/features/jobs/screens/job_summary_screen.dart` | Job action buttons (when cancelled) | Conditional: `!isCancelled` | All action buttons hidden when job is cancelled |

## 6. Screen-Level Access Control

| File Path | UI Element | Current Visibility Behavior | Expected Visibility (Role/Status) |
|-----------|------------|----------------------------|-----------------------------------|
| `lib/features/users/users_screen.dart` | Entire screen | Conditional: `isAdmin \|\| isManager` | Admin, Manager |
| `lib/features/vehicles/vehicles_screen.dart` | Entire screen | Conditional: `PermissionService().canAccessVehicles(userRole)` | Admin, Super Admin |
| `lib/features/vehicles/vehicle_editor_screen.dart` | Entire screen | Conditional: `PermissionService().canAccessVehicles(userRole)` | Admin, Super Admin |
| `lib/features/clients/clients_screen.dart` | Entire screen | No gating | Admin, Super Admin (per spec: Managers, Driver Managers, Drivers cannot see clients) |
| `lib/features/insights/screens/insights_screen.dart` | Entire screen | Conditional: `isAdmin \|\| isManager` | Admin, Manager |
| `lib/features/insights/screens/insights_screen.dart` | Tab count (5 for admin, 1 for manager) | Conditional: `isAdmin ? 5 : 1` | Admin sees all tabs, Manager sees limited tabs |
| `lib/features/notifications/screens/notification_preferences_screen.dart` | Entire screen | Conditional: `isSuperAdmin` | Super Admin only |

## Summary

### Missing Gating:
1. **Clients screen FAB** - Should be gated to Admin, Super Admin only
2. **Client card actions** (Edit, Manage Agents, Deactivate) - Should be gated to Admin, Super Admin only
3. **Agent card actions** (Edit, Delete) - Should be gated to Admin, Super Admin only
4. **Invoices FAB** - Should check `canCreateInvoice` permission
5. **Vouchers FAB** - Should check `canCreateVoucher` permission
6. **Trip Management FAB** - Should check edit permissions for the job

### Inconsistent Gating:
1. **Clients screen** - Screen is accessible but per spec should be Admin/Super Admin only
2. **Drawer menu items** - Some use `isAdmin` which may not include Manager for User Management

### Correctly Gated:
1. Vehicles (screen, FAB, editor) - Using PermissionService
2. Users screen - Admin, Manager check
3. Insights screen - Admin, Manager check with tab differentiation
4. Notification preferences - Super Admin only
5. Job summary actions - Role-based with status checks
6. User form fields - Role/status-based visibility

