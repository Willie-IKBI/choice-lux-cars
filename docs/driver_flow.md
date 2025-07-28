# Driver Management Flow – Technical Reference

## 1. User Lifecycle & Role Assignment
- **Signup:**
  - All new users are created in an “unassigned” state (`role = null` or `role = 'unassigned'`).
  - No access to main features until assigned a role.
- **Role Assignment:**
  - Admins (via Dashboard > Quick Actions > "Manage Users" or dashboard card) can assign roles:
    - Administrator, Manager, Driver Manager, Driver, Agent, Unassigned
  - Only administrators can assign/change roles.
  - Managers can view but not assign roles.
  - Update user status to active or deactivated.

## 2. Access Control & Permissions
- **User Management Access:**
  - Only users with `administrator` or `manager` roles can access the user management screens.
  - All management actions (edit, deactivate/reactivate) are restricted to these roles.
  - Only `administrator` can assign/change user roles.
- **Dashboard Quick Card:**
  - A "Manage Users" dashboard card is visible only to administrators and managers.
  - Provides direct access to the user/driver management flow from the dashboard.
  - Location: `DashboardScreen > _buildDashboardCards` (uses `DashboardItem` model)
- **RLS Enforcement:**
  - Deactivated users cannot log in.
  - Drivers with expired license/PDP cannot be assigned jobs.

## 3. Features & Screens
- **User List Screen (`UsersScreen`)**
  - Lists all users with:
    - Name, Role, Contact No., License Expiry, PDP Expiry, Email, Status
  - Actions:
    - Filter by role and status
    - Search by name or email
    - Click/tap row to edit
  - Access: Administrator, Manager only
- **User Detail/Edit Screen (`UserDetailScreen` + `UserForm`)**
  - **Modern Material 3 UI:**
    - Clean, sectioned layout with Cards and responsive design
    - Centered avatar+header section with camera icon for profile image change
    - Grouped fields:
      - **Basic Info:** Full Name, Email (readonly), Role, Status
      - **Contact Info:** Contact Number, Address, Emergency Contact Name/Number
      - **Driver Details:**
        - Driver Licence Expiry, PDP Expiry (date pickers with status badges)
        - **Driver License & PDP Image Upload:**
          - Upload and preview images for both fields
          - Uses `XFile` and `Uint8List` for cross-platform (web/mobile) compatibility
          - Images stored in Supabase Storage under `clc_images/driver_lic/{userId}/license.jpg` and `clc_images/pdp_lic/{userId}/pdp.jpg`
          - URLs saved in `driver_licence` and `pdp` fields in the `profiles` table
          - Preview updates immediately after upload
          - Error handling and feedback for failed uploads
    - Expiry status (Valid/Expiring Soon/Expired) shown inline with icons and color
    - Save and Deactivate actions in a sticky footer/button row (Material 3 FilledButton/OutlinedButton)
    - Responsive: two columns on wide screens, stacked on mobile
    - All fields and buttons use app theme and Material 3 components
    - Section headers with icons and bold text for clarity
    - Future-proof: placeholders for license/PDP image upload
  - **Access:** Administrator, Manager (role edit: administrator only)

## 4. Widgets, Style, and Theme
- **UserCard**: Material 3 Card with avatar, name, role, status badge, chevron, hover/ripple, and responsive layout
- **UserForm**: Modern, sectioned form for editing user details (see above)
- **Status Badge**: Color-coded badge for user status (active, deactivated, unassigned)
- **Profile Image Picker**: Uses image picker and uploads to `/profiles/{user_id}/profile.jpg` in Supabase Storage
- **Driver License & PDP Image Upload**:
  - Uploads use `XFile.readAsBytes()` for web/mobile
  - Provider and service accept `Uint8List` for upload
  - Preview uses `Image.network(url)`
  - Error handling with SnackBar and console logging
- **ExpiryFlag**: Widget to show "Expires Soon" or "Expired" for license/PDP
- **Dashboard Quick Card**: 'Manage Users' card in dashboard for administrator/manager only
- **Material 3 Components**: All fields use `FilledTextField`, `DropdownButtonFormField`, `FilledButton`, `OutlinedButton`, etc.
- **Theme**: All colors, fonts, and spacings use `ChoiceLuxTheme` and `Theme.of(context)` tokens for consistency

## 5. Files & Structure
- `lib/features/users/`
  - `users_screen.dart` – User list, search/filter, access control
  - `user_detail_screen.dart` – User detail/edit, deactivate/reactivate
  - `models/user.dart` – User model (matches Supabase `profiles` table)
  - `providers/users_provider.dart` – Riverpod provider for user CRUD, image upload
  - `widgets/user_card.dart` – UserCard widget
  - `widgets/user_form.dart` – UserForm, profile image picker, expiry flag, sectioned layout, image upload
- **Shared/Supporting:**
  - `lib/core/services/supabase_service.dart` – User CRUD, deactivate/reactivate, image upload
  - `lib/core/services/upload_service.dart` – File/image upload logic (now cross-platform)
  - `lib/features/auth/providers/auth_provider.dart` – Current user profile, role access
  - `lib/features/dashboard/dashboard_screen.dart` – Dashboard quick card logic

## 6. Business Rules & Logic
- **Deactivated users:** Cannot log in (RLS)
- **Drivers with expired license/PDP:** Cannot be assigned jobs
- **Role assignment:** Only administrators can assign/change roles
- **Profile image:** Uploaded to `/profiles/{user_id}/profile.jpg` in Supabase Storage
- **Driver License & PDP image:** Uploaded to `/driver_lic/{user_id}/license.jpg` and `/pdp_lic/{user_id}/pdp.jpg`
- **License/PDP expiry:**
  - If within 3 months: "Expires Soon" flag
  - If expired: "Expired – Driver access denied" flag
- **Access control:**
  - Only administrators/managers can access user management
  - Only administrators can assign roles
  - Only administrators/managers see the dashboard quick card for user management

## 7. Tasks & Implementation Steps
- [x] Scaffolded users feature module with models, providers, screens, widgets
- [x] Integrated user management into app router and drawer
- [x] Implemented user list with search, filter, and access control
- [x] Built user detail/edit screen with all required fields and logic
- [x] Added profile image upload and preview
- [x] Added deactivate/reactivate logic
- [x] Added expiry flag logic for license/PDP
- [x] Restricted role assignment to administrators only
- [x] Restricted user management access to administrators/managers only
- [x] Provided business logic for RLS and job assignment restrictions
- [x] Added dashboard quick card for user management (administrator/manager only)
- [x] Modernized Edit User screen and form: sectioned layout, Material 3, responsive, expiry status, sticky actions
- [x] Implemented cross-platform (web/mobile) image upload for driver license and PDP using XFile and Uint8List

## 8. Reference & Maintenance
- Use this document as a reference for:
  - User/driver management flows
  - File/component locations
  - Business rules and access control
  - Widget/component usage
  - Dashboard quick card access
  - Edit User screen structure and UI/UX
  - Image upload flow and cross-platform compatibility
  - Future enhancements and maintenance