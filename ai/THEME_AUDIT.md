# Theme Audit — Violations and Migration Plan

**Generated:** 2025-01-XX  
**Agent:** CLC-ARCH  
**Purpose:** Audit codebase for theme violations per THEME_RULES.md  
**Status:** AUDIT COMPLETE

**Enforcement Standard:** `/ai/THEME_RULES.md`  
**Theme Specification:** `/ai/THEME_SPEC.md`

---

## A) Audit Summary

### Total Violations (Approximate)

- **Hard-coded Color literals:** ~85 instances (excluding theme.dart and PDF theme)
- **Colors.* usage:** ~1,060 instances (excluding Colors.transparent and Colors.black in theme.dart)
- **Inline TextStyle colors:** ~103 instances
- **BoxDecoration/Container colors:** ~500 instances (many may be theme-compliant, needs review)
- **Legacy ChoiceLuxTheme constants:** ~200+ instances (deprecated but still used)

**Estimated Total Violations:** ~1,500+ instances across the codebase

### Top 10 Files by Violation Count

1. **`lib/features/jobs/screens/job_summary_screen.dart`** — ~150+ violations
   - Extensive Colors.* usage (white, grey, green, orange, red, blue, indigo, teal)
   - Hard-coded Color literals for gradients
   - Inline TextStyle colors
   - Manual button styling

2. **`lib/features/auth/login/login_screen.dart`** — ~50+ violations
   - Colors.* usage (white, black, red, grey)
   - Inline color definitions in InputDecoration
   - Manual styling

3. **`lib/features/invoices/widgets/invoice_action_buttons.dart`** — ~20+ violations
   - Colors.* usage (green, red, orange, white, grey)
   - Inline TextStyle colors
   - Manual button backgroundColor/foregroundColor

4. **`lib/features/jobs/screens/job_progress_screen.dart`** — ~30+ violations
   - Colors.* usage (white, black, grey)
   - ChoiceLuxTheme legacy constants
   - Manual button styling

5. **`lib/features/vehicles/vehicle_editor_screen.dart`** — ~40+ violations
   - Colors.* usage (green, red, orange, blue, white)
   - ChoiceLuxTheme legacy constants
   - Inline TextStyle colors (labelStyle, hintStyle)

6. **`lib/shared/services/pdf_viewer_service.dart`** — ~15+ violations
   - Hard-coded Color literals (0xFF1A1A1A, 0xFFE5E5E5, 0xFFD4AF37, 0xFF4CAF50)
   - Colors.* usage (red)
   - Inline TextStyle colors

7. **`lib/features/insights/screens/insights_screen.dart`** — ~10+ violations
   - Hard-coded Color literals (0xFF1a1a1a)
   - Colors.* usage (white)

8. **`lib/features/jobs/widgets/active_jobs_summary.dart`** — ~10+ violations
   - Colors.* usage (grey)
   - Inline TextStyle colors

9. **`lib/features/quotes/quotes_screen.dart`** — ~15+ violations
   - ChoiceLuxTheme legacy constants
   - Colors.* usage (transparent - allowed)

10. **`lib/features/clients/widgets/client_card.dart`** — ~15+ violations
    - ChoiceLuxTheme legacy constants
    - Colors.* usage (orange, red, green)

### Primary Drift Patterns Observed

1. **Legacy Constant Usage (Most Common)**
   - `ChoiceLuxTheme.richGold` → Should use `context.colorScheme.primary`
   - `ChoiceLuxTheme.softWhite` → Should use `context.tokens.textHeading`
   - `ChoiceLuxTheme.platinumSilver` → Should use `context.tokens.textBody`
   - `ChoiceLuxTheme.errorColor` → Should use `context.colorScheme.error` or `context.tokens.warningColor`
   - `ChoiceLuxTheme.successColor` → Should use `context.tokens.successColor`
   - `ChoiceLuxTheme.infoColor` → Should use `context.tokens.infoColor`

2. **Direct Colors.* Usage (Very Common)**
   - `Colors.white` → Should use `context.colorScheme.onSurface` or `context.tokens.textHeading`
   - `Colors.black` → Should use `context.colorScheme.background` or `context.colorScheme.surface`
   - `Colors.green` → Should use `context.tokens.successColor`
   - `Colors.red` → Should use `context.tokens.warningColor`
   - `Colors.blue` → Should use `context.tokens.infoColor`
   - `Colors.orange` → Should use `context.colorScheme.primary` (if amber) or appropriate token
   - `Colors.grey` → Should use `context.colorScheme.outline` or `context.tokens.textSubtle`

3. **Inline TextStyle Colors (Common)**
   - `TextStyle(color: Colors.white)` → Should use `context.textTheme.*.copyWith(color: context.tokens.textHeading)`
   - `TextStyle(color: ChoiceLuxTheme.platinumSilver)` → Should use theme tokens

4. **Manual Button Styling (Common)**
   - `backgroundColor: Colors.green` → Should use `ElevatedButtonTheme` or `context.colorScheme.primary`
   - `foregroundColor: Colors.white` → Should use `context.colorScheme.onPrimary`

5. **Hard-Coded Gradients (Less Common)**
   - `Color(0xFF1a1a1a)` and `Color(0xFF2d2d2d)` in insights screens
   - Should use theme surface tokens

---

## B) Findings by Severity

### A1: Must-Fix (Breaks Consistency, Readability, Accessibility, or Brand Mismatch)

**Priority:** HIGH — These must be fixed before any new feature work.

#### A1.1: Status Color Inconsistencies

**Files:**
- `lib/features/invoices/widgets/invoice_action_buttons.dart` — Uses `Colors.green` for success, `Colors.red` for errors
- `lib/features/jobs/screens/job_summary_screen.dart` — Uses `Colors.green`, `Colors.orange`, `Colors.indigo`, `Colors.teal` for status
- `lib/features/vehicles/vehicle_editor_screen.dart` — Uses `Colors.green`, `Colors.red`, `Colors.orange`, `Colors.blue`
- `lib/features/clients/widgets/client_card.dart` — Uses `Colors.orange`, `Colors.red`, `Colors.green` for status

**Issue:** Status colors are inconsistent across features, breaking brand consistency and accessibility (color-blind users).

**Required Fix:** All status colors must use `context.tokens.successColor`, `context.tokens.infoColor`, `context.tokens.warningColor`.

#### A1.2: Text Color Accessibility Issues

**Files:**
- `lib/features/jobs/screens/job_summary_screen.dart` — Uses `Colors.white` on various backgrounds without contrast checking
- `lib/features/insights/screens/*.dart` — Uses `Colors.white` on dark backgrounds
- Multiple files using `Colors.grey[600]`, `Colors.grey[500]` for text

**Issue:** Text colors may not meet accessibility contrast requirements. Should use semantic text tokens.

**Required Fix:** All text colors must use `context.tokens.textHeading`, `context.tokens.textBody`, or `context.tokens.textSubtle`.

#### A1.3: Button Styling Inconsistencies

**Files:**
- `lib/features/invoices/widgets/invoice_action_buttons.dart` — Manual `backgroundColor`/`foregroundColor` instead of theme
- `lib/features/jobs/screens/job_summary_screen.dart` — Extensive manual button styling
- `lib/features/vehicles/vehicle_editor_screen.dart` — Manual button colors

**Issue:** Buttons don't follow Material 3 theme, causing inconsistent appearance and missing hover/active states.

**Required Fix:** All buttons must use `ElevatedButtonTheme`, `OutlinedButtonTheme`, or `TextButtonTheme` from theme.

#### A1.4: Legacy Constant Usage in High-Traffic Areas

**Files:**
- `lib/features/jobs/screens/job_summary_screen.dart` — ~50+ instances of `ChoiceLuxTheme.*`
- `lib/features/jobs/screens/job_progress_screen.dart` — ~20+ instances
- `lib/features/quotes/quotes_screen.dart` — ~10+ instances

**Issue:** Deprecated constants still in use, preventing theme evolution and causing maintenance burden.

**Required Fix:** Replace all `ChoiceLuxTheme.*` with appropriate theme tokens.

---

### B1: Should-Fix (Cleanup, Minor Inconsistencies)

**Priority:** MEDIUM — These should be fixed during feature migrations.

#### B1.1: Inline TextStyle Colors

**Files:**
- `lib/features/vehicles/vehicle_editor_screen.dart` — Multiple `labelStyle`/`hintStyle` with `ChoiceLuxTheme.platinumSilver`
- `lib/features/jobs/widgets/active_jobs_summary.dart` — `TextStyle(color: Colors.grey[600])`
- `lib/features/jobs/screens/trip_management_screen.dart` — `TextStyle(color: Colors.grey[600])`

**Issue:** Text styles should use TextTheme, not inline colors.

**Required Fix:** Use `context.textTheme.*` with token-based color overrides.

#### B1.2: Hard-Coded Background Colors

**Files:**
- `lib/features/insights/screens/insights_screen.dart` — `backgroundColor: Color(0xFF1a1a1a)`
- `lib/features/insights/widgets/insights_card.dart` — Gradient colors `Color(0xFF1a1a1a)`, `Color(0xFF2d2d2d)`

**Issue:** Background colors should use theme surface tokens.

**Required Fix:** Use `context.colorScheme.surface` or `context.colorScheme.surfaceVariant`.

#### B1.3: Border/Divider Colors

**Files:**
- Multiple files using `Colors.grey` for borders
- `lib/features/jobs/screens/job_summary_screen.dart` — `Border.all(color: Colors.grey.shade600)`

**Issue:** Borders should use theme outline tokens.

**Required Fix:** Use `context.colorScheme.outline` or `context.colorScheme.outlineVariant`.

---

### C1: Allowed-Temp (Low Impact or Complex Areas; Can Defer)

**Priority:** LOW — These can be deferred or are explicitly allowed.

#### C1.1: PDF Theme (Explicitly Allowed)

**Files:**
- `lib/features/pdf/pdf_theme.dart` — Hard-coded `PdfColor` values

**Status:** ✅ **ALLOWED** per THEME_RULES.md Section 5 (PDF Generation exception)

**Action:** No migration required. PDF theme is separate from Flutter theme system.

#### C1.2: Theme Definition File (Authoritative Source)

**Files:**
- `lib/app/theme.dart` — Hard-coded `Color(0xFF...)` values

**Status:** ✅ **ALLOWED** — This is the authoritative theme source where colors are defined.

**Action:** No migration required. This file defines the theme.

#### C1.3: PDF Viewer Service (Complex UI)

**Files:**
- `lib/shared/services/pdf_viewer_service.dart` — Hard-coded colors in dialog builders

**Status:** ⚠️ **DEFER** — Complex service with many dialog builders. Low user impact.

**Action:** Document as legacy area, migrate in later batch.

#### C1.4: Debug/Development Code

**Files:**
- Any code wrapped in `kDebugMode` with hard-coded colors

**Status:** ✅ **ALLOWED** per THEME_RULES.md Section 5 (Debug-only exception)

**Action:** Verify code is properly wrapped in `kDebugMode`.

---

## C) Findings by Feature

### Auth Feature

**Files:**
- `lib/features/auth/login/login_screen.dart`
  - **Issues:** Colors.* usage (white, black, red, grey), inline InputDecoration colors, manual styling
  - **Violations:** ~50+ instances
  - **Severity:** A1 (text accessibility), B1 (styling cleanup)

- `lib/features/auth/signup/signup_screen.dart`
  - **Issues:** Similar to login screen, Colors.* usage, manual styling
  - **Violations:** ~30+ instances
  - **Severity:** A1, B1

### Jobs Feature

**Files:**
- `lib/features/jobs/screens/job_summary_screen.dart`
  - **Issues:** Extensive Colors.* usage (white, grey, green, orange, red, blue, indigo, teal), hard-coded gradients, manual button styling, legacy constants
  - **Violations:** ~150+ instances
  - **Severity:** A1 (status colors, button styling, legacy constants)

- `lib/features/jobs/screens/job_progress_screen.dart`
  - **Issues:** Colors.* usage, ChoiceLuxTheme legacy constants, manual button styling
  - **Violations:** ~30+ instances
  - **Severity:** A1, B1

- `lib/features/jobs/screens/create_job_screen.dart`
  - **Issues:** ChoiceLuxTheme legacy constants, inline TextStyle colors
  - **Violations:** ~10+ instances
  - **Severity:** B1

- `lib/features/jobs/screens/trip_management_screen.dart`
  - **Issues:** Colors.* usage, ChoiceLuxTheme legacy constants
  - **Violations:** ~15+ instances
  - **Severity:** B1

- `lib/features/jobs/screens/admin_monitoring_screen.dart`
  - **Issues:** Colors.* usage (green, red, grey), inline TextStyle colors
  - **Violations:** ~10+ instances
  - **Severity:** A1 (status colors)

- `lib/features/jobs/widgets/active_jobs_summary.dart`
  - **Issues:** Colors.* usage (grey), inline TextStyle colors
  - **Violations:** ~10+ instances
  - **Severity:** B1

- `lib/features/jobs/widgets/job_monitoring_card.dart`
  - **Issues:** Colors.* usage (grey), inline TextStyle colors
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/features/jobs/widgets/odometer_capture_widget.dart`
  - **Issues:** Colors.* usage (red), inline TextStyle colors
  - **Violations:** ~3+ instances
  - **Severity:** B1

- `lib/features/jobs/widgets/gps_capture_widget.dart`
  - **Issues:** Colors.* usage (red, green), inline TextStyle colors
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/features/jobs/widgets/driver_activity_card.dart`
  - **Issues:** Colors.* usage (grey), inline TextStyle colors
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/features/jobs/jobs_screen.dart`
  - **Issues:** ChoiceLuxTheme legacy constants
  - **Violations:** ~5+ instances
  - **Severity:** B1

### Invoices Feature

**Files:**
- `lib/features/invoices/widgets/invoice_action_buttons.dart`
  - **Issues:** Colors.* usage (green, red, orange, white, grey), inline TextStyle colors, manual button styling
  - **Violations:** ~20+ instances
  - **Severity:** A1 (status colors, button styling)

### Quotes Feature

**Files:**
- `lib/features/quotes/quotes_screen.dart`
  - **Issues:** ChoiceLuxTheme legacy constants
  - **Violations:** ~10+ instances
  - **Severity:** B1

- `lib/features/quotes/screens/quote_transport_details_screen.dart`
  - **Issues:** ChoiceLuxTheme legacy constants, inline TextStyle colors
  - **Violations:** ~10+ instances
  - **Severity:** B1

- `lib/features/quotes/screens/quote_details_screen.dart`
  - **Issues:** ChoiceLuxTheme legacy constants
  - **Violations:** ~5+ instances
  - **Severity:** B1

### Vehicles Feature

**Files:**
- `lib/features/vehicles/vehicle_editor_screen.dart`
  - **Issues:** Colors.* usage (green, red, orange, blue, white), ChoiceLuxTheme legacy constants, extensive inline TextStyle colors (labelStyle, hintStyle)
  - **Violations:** ~40+ instances
  - **Severity:** A1 (status colors), B1 (text styling)

### Clients Feature

**Files:**
- `lib/features/clients/widgets/client_card.dart`
  - **Issues:** ChoiceLuxTheme legacy constants, Colors.* usage (orange, red, green) for status
  - **Violations:** ~15+ instances
  - **Severity:** A1 (status colors)

- `lib/features/clients/widgets/branch_management_modal.dart`
  - **Issues:** ChoiceLuxTheme legacy constants, inline TextStyle colors
  - **Violations:** ~10+ instances
  - **Severity:** B1

- `lib/features/clients/screens/add_edit_client_screen.dart`
  - **Issues:** ChoiceLuxTheme legacy constants, inline TextStyle colors
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/features/clients/inactive_clients_screen.dart`
  - **Issues:** ChoiceLuxTheme legacy constants
  - **Violations:** ~3+ instances
  - **Severity:** B1

### Insights Feature

**Files:**
- `lib/features/insights/screens/insights_screen.dart`
  - **Issues:** Hard-coded Color literals (0xFF1a1a1a), Colors.* usage (white)
  - **Violations:** ~10+ instances
  - **Severity:** B1 (background colors)

- `lib/features/insights/widgets/insights_card.dart`
  - **Issues:** Hard-coded Color literals (0xFF1a1a1a, 0xFF2d2d2d) for gradients, Colors.* usage (white70)
  - **Violations:** ~5+ instances
  - **Severity:** B1 (gradient colors)

- `lib/features/insights/screens/jobs_insights_tab.dart`
  - **Issues:** Hard-coded Color literals (0xFF1a1a1a, 0xFF2d2d2d) for gradients, Colors.* usage (white, red)
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/features/insights/screens/client_insights_tab.dart`
  - **Issues:** Hard-coded Color literals for gradients, Colors.* usage (white)
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/features/insights/screens/driver_insights_tab.dart`
  - **Issues:** Hard-coded Color literals for gradients, Colors.* usage (white)
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/features/insights/screens/vehicle_insights_tab.dart`
  - **Issues:** Hard-coded Color literals for gradients, Colors.* usage (white)
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/features/insights/screens/financial_insights_tab.dart`
  - **Issues:** Hard-coded Color literals for gradients, Colors.* usage (white)
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/features/insights/screens/insights_jobs_list_screen.dart`
  - **Issues:** Colors.* usage (red)
  - **Violations:** ~2+ instances
  - **Severity:** B1

### Users Feature

**Files:**
- `lib/features/users/widgets/user_form.dart`
  - **Issues:** Colors.* usage (red, amber, green) for status indicators, inline TextStyle colors
  - **Violations:** ~5+ instances
  - **Severity:** A1 (status colors)

- `lib/features/users/users_screen.dart`
  - **Issues:** ChoiceLuxTheme legacy constants, inline TextStyle colors
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/features/users/user_profile_screen.dart`
  - **Issues:** Colors.* usage (white), inline TextStyle colors
  - **Violations:** ~3+ instances
  - **Severity:** B1

### Notifications Feature

**Files:**
- `lib/features/notifications/screens/notification_list_screen.dart`
  - **Issues:** ChoiceLuxTheme legacy constants, inline TextStyle colors
  - **Violations:** ~10+ instances
  - **Severity:** B1

- `lib/features/notifications/screens/notification_preferences_screen.dart`
  - **Issues:** ChoiceLuxTheme legacy constants, inline TextStyle colors
  - **Violations:** ~3+ instances
  - **Severity:** B1

- `lib/shared/widgets/notification_bell.dart`
  - **Issues:** Hard-coded Color literal (0xFFD32F2F)
  - **Violations:** ~1 instance
  - **Severity:** B1

### Shared/Common

**Files:**
- `lib/shared/services/pdf_viewer_service.dart`
  - **Issues:** Hard-coded Color literals, Colors.* usage (red), inline TextStyle colors
  - **Violations:** ~15+ instances
  - **Severity:** C1 (defer - complex service)

- `lib/shared/screens/pdf_viewer_screen.dart`
  - **Issues:** Colors.* usage (black, white), ChoiceLuxTheme legacy constants
  - **Violations:** ~5+ instances
  - **Severity:** B1

- `lib/shared/widgets/status_pill.dart`
  - **Issues:** BoxDecoration color (may be theme-compliant, needs review)
  - **Violations:** ~1 instance
  - **Severity:** B1 (needs review)

- `lib/app/app.dart`
  - **Issues:** Colors.* usage (black), ChoiceLuxTheme legacy constants
  - **Violations:** ~3+ instances
  - **Severity:** B1

---

## D) Migration Plan (No Implementation)

### Migration Principles

1. **No Visual Redesign:** Token replacement only — maintain exact visual appearance
2. **Feature-by-Feature:** Migrate one feature at a time to reduce risk
3. **Incremental:** Small batches (2-3 screens per PR) for easier review
4. **Test-Driven:** Visual regression testing after each batch
5. **Documentation:** Update code comments to reference theme tokens

### Recommended Batch Order

#### Batch 1: Invoices Feature (High Priority, Small Scope)

**Scope:**
- `lib/features/invoices/widgets/invoice_action_buttons.dart`

**Rationale:** Small scope, high visibility, clear violations (status colors, button styling).

**Boundaries:**
- Only invoice action buttons widget
- No changes to invoice screens or services
- No changes to PDF generation

**Validation Checklist:**
- [ ] All `Colors.green` → `context.tokens.successColor`
- [ ] All `Colors.red` → `context.tokens.warningColor`
- [ ] All `Colors.orange` → `context.colorScheme.primary`
- [ ] All `Colors.white` → `context.colorScheme.onPrimary` or `context.tokens.textHeading`
- [ ] All `Colors.grey` → `context.colorScheme.outline` or `context.tokens.textSubtle`
- [ ] All button styling uses theme (ElevatedButtonTheme, etc.)
- [ ] All TextStyle colors use theme tokens
- [ ] Visual appearance unchanged (screenshot comparison)
- [ ] All interactive states work (hover, active, disabled)

**Estimated Effort:** 2-3 hours

---

#### Batch 2: Auth Feature (High Priority, Medium Scope)

**Scope:**
- `lib/features/auth/login/login_screen.dart`
- `lib/features/auth/signup/signup_screen.dart`

**Rationale:** High-traffic screens, accessibility issues, clear violations.

**Boundaries:**
- Only login and signup screens
- No changes to auth provider or services
- No changes to password reset/forgot password screens (separate batch)

**Validation Checklist:**
- [ ] All `Colors.white` → `context.colorScheme.onSurface` or `context.tokens.textHeading`
- [ ] All `Colors.black` → `context.colorScheme.background` or `context.colorScheme.surface`
- [ ] All `Colors.red` → `context.tokens.warningColor`
- [ ] All `Colors.grey` → `context.colorScheme.outline` or `context.tokens.textSubtle`
- [ ] InputDecoration uses theme (InputDecorationTheme)
- [ ] All TextStyle colors use theme tokens
- [ ] Visual appearance unchanged
- [ ] All form validation states work correctly
- [ ] Accessibility contrast ratios verified

**Estimated Effort:** 4-6 hours

---

#### Batch 3: Vehicles Feature (Medium Priority, Medium Scope)

**Scope:**
- `lib/features/vehicles/vehicle_editor_screen.dart`

**Rationale:** Medium traffic, clear violations (status colors, extensive TextStyle usage).

**Boundaries:**
- Only vehicle editor screen
- No changes to vehicles list screen or models

**Validation Checklist:**
- [ ] All `Colors.green` → `context.tokens.successColor`
- [ ] All `Colors.red` → `context.tokens.warningColor`
- [ ] All `Colors.orange` → `context.colorScheme.primary`
- [ ] All `Colors.blue` → `context.tokens.infoColor`
- [ ] All `Colors.white` → appropriate theme token
- [ ] All `ChoiceLuxTheme.platinumSilver` → `context.tokens.textBody`
- [ ] All `labelStyle`/`hintStyle` use TextTheme with token colors
- [ ] Visual appearance unchanged
- [ ] All form fields work correctly

**Estimated Effort:** 4-6 hours

---

#### Batch 4: Clients Feature (Medium Priority, Small Scope)

**Scope:**
- `lib/features/clients/widgets/client_card.dart`
- `lib/features/clients/widgets/branch_management_modal.dart`
- `lib/features/clients/screens/add_edit_client_screen.dart`
- `lib/features/clients/inactive_clients_screen.dart`

**Rationale:** Medium traffic, status color inconsistencies.

**Boundaries:**
- Only client-related widgets and screens listed
- No changes to client repository or models

**Validation Checklist:**
- [ ] All `ChoiceLuxTheme.*` → appropriate theme tokens
- [ ] All status colors use `context.tokens.successColor`, `context.tokens.warningColor`
- [ ] All `Colors.orange`/`Colors.red`/`Colors.green` → theme tokens
- [ ] All TextStyle colors use theme tokens
- [ ] Visual appearance unchanged
- [ ] Status indicators display correctly

**Estimated Effort:** 3-4 hours

---

#### Batch 5: Users Feature (Medium Priority, Small Scope)

**Scope:**
- `lib/features/users/widgets/user_form.dart`
- `lib/features/users/users_screen.dart`
- `lib/features/users/user_profile_screen.dart`

**Rationale:** Medium traffic, status color inconsistencies.

**Boundaries:**
- Only user-related widgets and screens listed
- No changes to user repository or models

**Validation Checklist:**
- [ ] All `Colors.red`/`Colors.amber`/`Colors.green` → theme tokens
- [ ] All `ChoiceLuxTheme.*` → appropriate theme tokens
- [ ] All TextStyle colors use theme tokens
- [ ] Visual appearance unchanged
- [ ] Status indicators display correctly

**Estimated Effort:** 3-4 hours

---

#### Batch 6: Quotes Feature (Low Priority, Small Scope)

**Scope:**
- `lib/features/quotes/quotes_screen.dart`
- `lib/features/quotes/screens/quote_transport_details_screen.dart`
- `lib/features/quotes/screens/quote_details_screen.dart`

**Rationale:** Low traffic, mostly legacy constants.

**Boundaries:**
- Only quote screens listed
- No changes to quote repository or PDF generation

**Validation Checklist:**
- [ ] All `ChoiceLuxTheme.*` → appropriate theme tokens
- [ ] All TextStyle colors use theme tokens
- [ ] Visual appearance unchanged

**Estimated Effort:** 2-3 hours

---

#### Batch 7: Notifications Feature (Low Priority, Small Scope)

**Scope:**
- `lib/features/notifications/screens/notification_list_screen.dart`
- `lib/features/notifications/screens/notification_preferences_screen.dart`
- `lib/shared/widgets/notification_bell.dart`

**Rationale:** Low traffic, mostly legacy constants.

**Boundaries:**
- Only notification screens and bell widget
- No changes to notification service or provider

**Validation Checklist:**
- [ ] All `ChoiceLuxTheme.*` → appropriate theme tokens
- [ ] All TextStyle colors use theme tokens
- [ ] Hard-coded Color literal in notification_bell.dart → theme token
- [ ] Visual appearance unchanged

**Estimated Effort:** 2-3 hours

---

#### Batch 8: Insights Feature (Low Priority, Medium Scope)

**Scope:**
- `lib/features/insights/screens/insights_screen.dart`
- `lib/features/insights/widgets/insights_card.dart`
- All insight tab screens (jobs, client, driver, vehicle, financial)

**Rationale:** Low traffic, hard-coded gradient colors.

**Boundaries:**
- Only insights screens and widgets
- No changes to insights repository or data models

**Validation Checklist:**
- [ ] All hard-coded Color literals (0xFF1a1a1a, 0xFF2d2d2d) → theme surface tokens
- [ ] All `Colors.white` → `context.tokens.textHeading`
- [ ] All `Colors.red` → `context.tokens.warningColor`
- [ ] Gradients use theme surface tokens
- [ ] Visual appearance unchanged (gradients may need adjustment)

**Estimated Effort:** 4-5 hours

---

#### Batch 9: Jobs Feature — Part 1 (High Priority, Large Scope)

**Scope:**
- `lib/features/jobs/screens/create_job_screen.dart`
- `lib/features/jobs/screens/trip_management_screen.dart`
- `lib/features/jobs/screens/admin_monitoring_screen.dart`
- `lib/features/jobs/widgets/active_jobs_summary.dart`
- `lib/features/jobs/widgets/job_monitoring_card.dart`
- `lib/features/jobs/widgets/odometer_capture_widget.dart`
- `lib/features/jobs/widgets/gps_capture_widget.dart`
- `lib/features/jobs/widgets/driver_activity_card.dart`
- `lib/features/jobs/jobs_screen.dart`

**Rationale:** High traffic, but split into parts to reduce risk. Part 1 covers smaller files.

**Boundaries:**
- Only listed files
- No changes to job_summary_screen or job_progress_screen (separate batches)

**Validation Checklist:**
- [ ] All `Colors.*` → appropriate theme tokens
- [ ] All `ChoiceLuxTheme.*` → appropriate theme tokens
- [ ] All TextStyle colors use theme tokens
- [ ] All status colors use theme tokens
- [ ] Visual appearance unchanged
- [ ] All interactive states work

**Estimated Effort:** 6-8 hours

---

#### Batch 10: Jobs Feature — Part 2 (High Priority, Large Scope)

**Scope:**
- `lib/features/jobs/screens/job_progress_screen.dart`

**Rationale:** High traffic, many violations, but isolated screen.

**Boundaries:**
- Only job_progress_screen.dart
- No changes to other job screens or widgets

**Validation Checklist:**
- [ ] All `Colors.*` → appropriate theme tokens
- [ ] All `ChoiceLuxTheme.*` → appropriate theme tokens
- [ ] All TextStyle colors use theme tokens
- [ ] All button styling uses theme
- [ ] Visual appearance unchanged
- [ ] All interactive states work

**Estimated Effort:** 4-6 hours

---

#### Batch 11: Jobs Feature — Part 3 (High Priority, Very Large Scope)

**Scope:**
- `lib/features/jobs/screens/job_summary_screen.dart`

**Rationale:** Highest violation count, but isolated screen. Requires careful migration.

**Boundaries:**
- Only job_summary_screen.dart
- No changes to other job screens or widgets

**Validation Checklist:**
- [ ] All `Colors.*` → appropriate theme tokens (white, grey, green, orange, red, blue, indigo, teal)
- [ ] All `ChoiceLuxTheme.*` → appropriate theme tokens
- [ ] All hard-coded Color literals → theme tokens
- [ ] All TextStyle colors use theme tokens
- [ ] All button styling uses theme
- [ ] All gradient colors use theme tokens
- [ ] Visual appearance unchanged (extensive visual testing required)
- [ ] All interactive states work
- [ ] All status indicators use theme tokens

**Estimated Effort:** 8-12 hours (largest file, most violations)

---

#### Batch 12: Shared/Common (Low Priority, Medium Scope)

**Scope:**
- `lib/shared/screens/pdf_viewer_screen.dart`
- `lib/shared/widgets/status_pill.dart`
- `lib/app/app.dart`

**Rationale:** Low traffic, cleanup of shared components.

**Boundaries:**
- Only listed files
- No changes to pdf_viewer_service.dart (deferred per C1.3)

**Validation Checklist:**
- [ ] All `Colors.*` → appropriate theme tokens
- [ ] All `ChoiceLuxTheme.*` → appropriate theme tokens
- [ ] All TextStyle colors use theme tokens
- [ ] Visual appearance unchanged

**Estimated Effort:** 2-3 hours

---

### Migration Validation Rules

**Per Batch:**
1. **Visual Regression:** Screenshot comparison before/after (if available)
2. **Compilation:** `flutter analyze` passes with no errors
3. **Runtime:** All screens load without crashes
4. **Interactive States:** Hover, active, focus, disabled states work
5. **Accessibility:** Contrast ratios meet WCAG AA (if tools available)

**No Visual Redesign Rule:**
- Token replacement must maintain exact visual appearance
- If visual change is needed, it must be approved separately
- Color values must match THEME_SPEC.md exactly

---

## E) Risks & Notes

### Areas Likely to Cause Regressions

#### E1: Custom Painters and Charts

**Risk:** High — Custom painters may use hard-coded colors that are difficult to migrate.

**Files to Review:**
- Any custom `CustomPainter` implementations
- Chart libraries (if any) with hard-coded colors
- Custom shape/decoration builders

**Mitigation:**
- Identify all custom painters before migration
- Test visual appearance carefully
- May require custom theme-aware painter implementations

#### E2: PDF Generation (Explicitly Excluded)

**Risk:** Low — PDF generation is explicitly allowed to use hard-coded colors per THEME_RULES.md.

**Files:**
- `lib/features/pdf/pdf_theme.dart` — ✅ Allowed
- `lib/features/quotes/services/quote_pdf_service.dart` — ✅ Allowed
- `lib/features/invoices/services/invoice_pdf_service.dart` — ✅ Allowed
- `lib/features/vouchers/services/voucher_pdf_service.dart` — ✅ Allowed

**Action:** No migration required. These files are excluded from theme compliance.

#### E3: Complex Gradients

**Risk:** Medium — Gradients using hard-coded colors may need adjustment to match theme tokens.

**Files:**
- `lib/features/insights/widgets/insights_card.dart` — Gradient with `Color(0xFF1a1a1a)`, `Color(0xFF2d2d2d)`
- `lib/features/insights/screens/*.dart` — Multiple gradient definitions

**Mitigation:**
- Map gradient colors to theme surface tokens
- May need to adjust gradient stops to maintain visual appearance
- Test gradient appearance carefully

#### E4: Status Color Logic

**Risk:** Medium — Status color determination logic may be scattered.

**Files:**
- `lib/shared/utils/status_color_utils.dart` — May already centralize status colors (needs review)
- Multiple files with status color logic

**Mitigation:**
- Review `status_color_utils.dart` to ensure it uses theme tokens
- Centralize all status color logic in one utility
- Update all callers to use centralized utility

#### E5: Legacy Constant Migration

**Risk:** Low — Legacy constants are deprecated but still widely used.

**Files:**
- All files using `ChoiceLuxTheme.richGold`, `ChoiceLuxTheme.softWhite`, etc.

**Mitigation:**
- Use IDE refactoring tools for find/replace
- Verify each replacement is correct (not all constants map 1:1 to tokens)
- Remove deprecated constants after all migrations complete

#### E6: Button Styling Complexity

**Risk:** Medium — Manual button styling may have custom logic that needs preservation.

**Files:**
- `lib/features/jobs/screens/job_summary_screen.dart` — Complex button styling with conditional colors
- `lib/features/invoices/widgets/invoice_action_buttons.dart` — Progressive button states

**Mitigation:**
- Preserve all conditional logic
- Use ButtonStyle with conditional colors via theme tokens
- Test all button states carefully

#### E7: Input Field Styling

**Risk:** Low — Input fields should use InputDecorationTheme, but custom styling may exist.

**Files:**
- `lib/features/vehicles/vehicle_editor_screen.dart` — Extensive labelStyle/hintStyle usage
- `lib/features/auth/login/login_screen.dart` — Custom InputDecoration styling

**Mitigation:**
- Migrate to InputDecorationTheme where possible
- Use TextTheme with token color overrides for custom cases
- Test all input states (enabled, focused, error, disabled)

#### E8: Visual Regression Testing

**Risk:** High — Without automated visual regression testing, manual review is required.

**Mitigation:**
- Capture baseline screenshots before migration
- Manual visual review after each batch
- Use side-by-side comparison tools
- Get stakeholder sign-off for high-traffic screens

### Notes

1. **Theme Definition File:** `lib/app/theme.dart` contains hard-coded colors, but this is the authoritative source and is allowed.

2. **PDF Theme:** PDF generation uses separate theme system and is explicitly excluded from migration.

3. **Legacy Constants:** `ChoiceLuxTheme.*` constants are deprecated but still widely used. Migration should replace these with theme tokens.

4. **Status Colors:** Status color logic should be centralized in `lib/shared/utils/status_color_utils.dart` (if it exists) or created if missing.

5. **Gradient Colors:** Gradients using hard-coded colors may need careful mapping to theme surface tokens to maintain visual appearance.

6. **Button Themes:** Material 3 button themes are defined in `lib/app/theme.dart`, but many widgets override them manually. Migration should use theme defaults where possible.

7. **TextTheme:** TextTheme is defined in `lib/app/theme.dart`, but many widgets use inline TextStyle with hard-coded colors. Migration should use TextTheme with token color overrides.

8. **Accessibility:** Some hard-coded colors may not meet accessibility contrast requirements. Migration to theme tokens should improve accessibility.

---

**Status:** AUDIT COMPLETE  
**Next Step:** CLC-BUILD begins migration following batch order  
**Approval Required:** Yes — Before migration begins

---

## REVIEW DECISION

**Date:** 2025-01-XX  
**Reviewer:** CLC-REVIEW  
**Decision:** ✅ **APPROVE** (With Minor Documentation Improvement)

### Audit Quality Assessment

#### ✅ 1. Audit Completeness — PASS

**Coverage Verified:**
- ✅ **Color(0xFF...)** — Documented (~85 instances, excluding theme.dart and PDF)
- ✅ **Colors.*** — Documented (~1,060 instances, excluding transparent/black in theme.dart)
- ✅ **Inline TextStyle colors** — Documented (~103 instances)
- ✅ **Legacy constants** — Documented (~200+ ChoiceLuxTheme instances)
- ✅ **Non-token styling drift** — Documented (BoxDecoration, manual button styling, gradients)

**Assessment:** Audit comprehensively covers all violation types per THEME_RULES.md Section 4 (Forbidden Patterns).

---

#### ✅ 2. Severity Classification — PASS

**A1 Must-Fix Items:**
- ✅ **Status color inconsistencies** — Correctly identified as breaking brand consistency and accessibility
- ✅ **Text color accessibility issues** — Correctly identified as potential WCAG violations
- ✅ **Button styling inconsistencies** — Correctly identified as breaking Material 3 theme compliance
- ✅ **Legacy constants in high-traffic areas** — Correctly identified as blocking theme evolution

**B1 Should-Fix Items:**
- ✅ **Inline TextStyle colors** — Reasonable cleanup priority
- ✅ **Hard-coded backgrounds** — Reasonable cleanup priority
- ✅ **Border/divider colors** — Reasonable cleanup priority

**C1 Allowed-Temp Exceptions:**
- ✅ **PDF theme** — Correctly matches THEME_RULES.md Section 5 (PDF Generation exception)
- ✅ **Theme definition file** — Correctly identified as authoritative source
- ✅ **PDF viewer service** — Reasonable deferral (complex, low impact)
- ✅ **Debug code** — Correctly matches THEME_RULES.md Section 5 (Debug-only exception)

**Assessment:** Severity classification is sensible and aligns with THEME_RULES.md enforcement rules.

---

#### ✅ 3. Top Offenders — PASS

**Top 10 Files Assessment:**
1. ✅ `job_summary_screen.dart` (150+ violations) — Largest, most complex screen — **CORRECT**
2. ✅ `login_screen.dart` (50+ violations) — High-traffic entry point — **CORRECT**
3. ✅ `invoice_action_buttons.dart` (20+ violations) — High-visibility widget — **CORRECT**
4. ✅ `job_progress_screen.dart` (30+ violations) — High-traffic screen — **CORRECT**
5. ✅ `vehicle_editor_screen.dart` (40+ violations) — Complex form screen — **CORRECT**
6. ✅ `pdf_viewer_service.dart` (15+ violations) — Correctly deferred to C1 — **CORRECT**
7. ✅ `insights_screen.dart` (10+ violations) — Low-traffic analytics — **CORRECT**
8. ✅ `active_jobs_summary.dart` (10+ violations) — Widget with violations — **CORRECT**
9. ✅ `quotes_screen.dart` (15+ violations) — Medium-traffic screen — **CORRECT**
10. ✅ `client_card.dart` (15+ violations) — Reusable widget — **CORRECT**

**Assessment:** Top offenders list is accurate and represents high-impact migration targets.

**⚠️ Additional Finding (Documentation Improvement):**
- `lib/shared/utils/status_color_utils.dart` — **NOT LISTED** but contains critical violations:
  - Uses `Colors.blue`, `Colors.orange`, `Colors.purple`, `Colors.indigo`, `Colors.amber`, `Colors.green`, `Colors.red` directly
  - Uses `ChoiceLuxTheme.*` legacy constants
  - **Impact:** This is a central utility used by multiple features — should be migrated early
  - **Recommendation:** Add to Batch 1 or create Batch 0 (pre-migration utility fix)

---

#### ✅ 4. Migration Plan Quality — PASS

**Batch Scope Assessment:**
- ✅ **Small batches** — Most batches are 1-3 files, largest is single file (job_summary_screen)
- ✅ **Reversible** — Each batch is isolated and can be rolled back independently
- ✅ **Clear boundaries** — Each batch explicitly defines in-scope and out-of-scope files

**Order Assessment:**
- ✅ **Risk reduction** — Starts with small, high-priority features (invoices, auth)
- ✅ **Progressive complexity** — Builds from simple to complex (small widgets → large screens)
- ✅ **High-traffic first** — Auth and invoices prioritized appropriately

**Validation Checklist Assessment:**
- ✅ **Per-batch checklists** — Each batch has comprehensive validation checklist
- ✅ **Visual regression** — Screenshot comparison required
- ✅ **Interactive states** — Hover, active, focus, disabled testing required
- ✅ **Accessibility** — Contrast ratio verification mentioned

**No Redesign Rule:**
- ✅ **Explicitly stated** — "Token replacement only — maintain exact visual appearance"
- ✅ **Enforced** — Color values must match THEME_SPEC.md exactly
- ✅ **Approval required** — Visual changes must be approved separately

**Assessment:** Migration plan is well-structured, low-risk, and follows best practices.

---

#### ✅ 5. Risk Identification — PASS

**Risks Documented:**
- ✅ **Custom painters** — Noted in E1, with mitigation strategy
- ✅ **Gradients** — Noted in E3, with mapping guidance
- ✅ **Status color logic** — Noted in E4, with centralization recommendation
- ✅ **PDF exceptions** — Correctly noted as allowed per THEME_RULES.md
- ✅ **Button styling complexity** — Noted in E6, with preservation guidance
- ✅ **Input field styling** — Noted in E7, with migration approach
- ✅ **Visual regression** — Noted in E8, with testing strategy

**Assessment:** All major risks are identified with appropriate mitigation strategies.

---

### Required Improvements (Documentation Only)

#### Improvement 1: Add Status Color Utility to Migration Plan

**Issue:** `lib/shared/utils/status_color_utils.dart` is a central utility used by multiple features but is not listed in the audit or migration plan.

**Required Addition:**
- Add to Section C (Findings by Feature) under "Shared/Common"
- Create **Batch 0** (pre-migration utility fix) or add to **Batch 1** (invoices)
- Rationale: This utility should be migrated early since it's used by multiple features

**Recommended Addition:**
```markdown
#### Batch 0: Status Color Utility (Pre-Migration Foundation)

**Scope:**
- `lib/shared/utils/status_color_utils.dart`

**Rationale:** Central utility used by multiple features. Migrating this first ensures all dependent features benefit from theme-compliant status colors.

**Boundaries:**
- Only status_color_utils.dart
- No changes to callers (they will automatically benefit)

**Validation Checklist:**
- [ ] All `Colors.*` → appropriate theme tokens
- [ ] All `ChoiceLuxTheme.*` → appropriate theme tokens
- [ ] All status color methods return theme tokens
- [ ] Visual appearance unchanged (status indicators still work)
- [ ] All callers continue to work (no breaking changes)

**Estimated Effort:** 1-2 hours
```

---

### Approved Batch Order (With Modification)

**Decision:** Approve migration plan with the following modification:

1. **Batch 0 (NEW):** Status Color Utility — `lib/shared/utils/status_color_utils.dart`
2. **Batch 1:** Invoices Feature — `lib/features/invoices/widgets/invoice_action_buttons.dart`
3. **Batch 2:** Auth Feature — Login and signup screens
4. **Batch 3:** Vehicles Feature — Vehicle editor screen
5. **Batch 4:** Clients Feature — Client widgets and screens
6. **Batch 5:** Users Feature — User widgets and screens
7. **Batch 6:** Quotes Feature — Quote screens
8. **Batch 7:** Notifications Feature — Notification screens and bell widget
9. **Batch 8:** Insights Feature — Insights screens and widgets
10. **Batch 9:** Jobs Feature — Part 1 (smaller files)
11. **Batch 10:** Jobs Feature — Part 2 (job_progress_screen)
12. **Batch 11:** Jobs Feature — Part 3 (job_summary_screen)
13. **Batch 12:** Shared/Common — PDF viewer screen, status pill, app.dart

**Rationale for Batch 0 Addition:**
- Central utility affects multiple features
- Early migration provides foundation for dependent features
- Small scope (1 file) reduces risk
- Low effort (1-2 hours) provides high value

---

### Strict Enforcement Note

**⚠️ CRITICAL: BUILD MUST NOT TOUCH ITEMS OUTSIDE APPROVED BATCH SCOPE**

**Enforcement Rules:**

1. **Batch Boundaries Are Absolute:**
   - BUILD must only modify files explicitly listed in the batch scope
   - BUILD must not modify files listed as "out of scope" or "boundaries"
   - BUILD must not expand scope to "related" files not explicitly listed

2. **No Drive-By Refactors:**
   - BUILD must not fix violations in files outside the batch scope
   - BUILD must not "clean up" related files "while we're here"
   - BUILD must not add new features or improvements beyond token replacement

3. **Token Replacement Only:**
   - BUILD must replace hard-coded colors with theme tokens
   - BUILD must NOT change visual appearance (unless explicitly approved)
   - BUILD must NOT redesign layouts, spacing, or component structure

4. **Validation Before Proceeding:**
   - Each batch must pass its validation checklist before next batch begins
   - Visual regression testing must pass (if available)
   - All interactive states must be verified

5. **Escalation Required:**
   - If BUILD discovers violations in files not listed in batch scope, they must:
     - Document the finding
     - Complete the current batch as-scoped
     - Request ARCH approval for scope expansion before proceeding

**Violation Consequences:**
- REVIEW will reject any PR that modifies files outside approved batch scope
- REVIEW will block migration progress until scope violations are corrected
- BUILD must rollback unauthorized changes before proceeding

---

### Final Approval

**Status:** ✅ **APPROVED FOR MIGRATION**

**Conditions:**
1. ✅ Audit is comprehensive and accurate
2. ✅ Severity classification is appropriate
3. ✅ Migration plan is well-structured and low-risk
4. ✅ Batch order reduces risk appropriately
5. ⚠️ **REQUIRED:** Add Batch 0 (Status Color Utility) to migration plan before BUILD begins

**Next Steps:**
1. ARCH updates THEME_AUDIT.md to include Batch 0 (status_color_utils.dart)
2. BUILD begins migration with Batch 0
3. BUILD follows approved batch order strictly
4. REVIEW validates each batch before next batch begins

**Approval Date:** 2025-01-XX  
**Reviewer:** CLC-REVIEW  
**Status:** APPROVED — Ready for BUILD implementation

