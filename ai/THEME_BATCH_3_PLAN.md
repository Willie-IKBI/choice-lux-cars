# Theme Migration Batch 3 — Execution Plan

**Generated:** 2025-01-XX  
**Agent:** CLC-ARCH  
**Purpose:** Define strict execution plan for Theme Migration Batch 3  
**Status:** PLAN READY

**Source Documents:**
- `/ai/THEME_SPEC.md` — Theme specification
- `/ai/THEME_RULES.md` — Enforcement rules
- `/ai/THEME_AUDIT.md` — Violation audit (Batch 3: Vehicles Feature)

---

## A) Batch Objective

**Goal:** Migrate `lib/features/vehicles/vehicle_editor_screen.dart` to use theme tokens exclusively, removing all hard-coded colors, legacy constants, and inline TextStyle colors.

**Rationale:**
- High-visibility form screen used for vehicle management
- A1 severity violations (status color inconsistencies, text accessibility issues)
- Medium scope (single file, ~40+ violations)
- Clear patterns to replace (status colors, legacy constants, extensive InputDecoration styling)
- Low coupling (isolated screen, minimal dependencies)

**Expected Impact:**
- Consistent status colors across vehicle management
- Improved text accessibility (proper contrast ratios)
- Foundation for future vehicle feature migrations
- Removal of ~40+ theme violations

---

## B) In-Scope Files (Exact Paths)

**Single File:**
- `lib/features/vehicles/vehicle_editor_screen.dart`

**File Statistics:**
- Total lines: ~1,343
- Estimated violations: ~40+ instances
- Violation types: Colors.*, ChoiceLuxTheme.*, inline TextStyle colors, manual button styling

---

## C) Out-of-Scope Files (Explicit)

**Explicitly Excluded:**
- `lib/features/vehicles/vehicles_screen.dart` — Vehicles list screen (separate batch)
- `lib/features/vehicles/models/vehicle.dart` — Vehicle model (no UI code)
- `lib/features/vehicles/providers/vehicles_provider.dart` — State management (no UI code)
- `lib/features/vehicles/data/vehicles_repository.dart` — Data layer (no UI code)
- `lib/shared/widgets/luxury_app_bar.dart` — Shared widget (separate batch)
- `lib/shared/widgets/system_safe_scaffold.dart` — Shared widget (separate batch)
- `lib/app/theme.dart` — Theme definition (authoritative source, allowed)

**Boundaries:**
- Only `vehicle_editor_screen.dart` may be modified
- No changes to shared widgets or theme definition
- No changes to vehicle models or providers
- No changes to other vehicle feature files

---

## D) Patterns to Remove

### D1: Colors.* Usage

**Patterns to Remove:**
- `Colors.green` → Replace with `context.tokens.successColor`
- `Colors.red` → Replace with `context.tokens.warningColor`
- `Colors.orange` → Replace with `context.colorScheme.primary` (if amber) or appropriate token
- `Colors.blue` → Replace with `context.tokens.infoColor`
- `Colors.white` → Replace with `context.colorScheme.onPrimary` or `context.tokens.textHeading` (based on background)
- `Colors.grey[300]`, `Colors.grey[100]` → Replace with `context.colorScheme.surfaceVariant` or `context.tokens.textSubtle`
- `Colors.black` → Replace with `context.colorScheme.background` or `context.colorScheme.surface`

**Locations:**
- SnackBar backgrounds (lines 94, 102, 117, 134, 221, 235)
- License countdown indicator status colors (lines 246-247)
- Error border colors in InputDecoration (multiple lines)
- Placeholder widget backgrounds and text colors (lines 982, 1008, 1074, 1133)
- Icon colors in SnackBar (line 216)
- Button foreground colors (line 939)
- Shadow colors (line 869)

### D2: Legacy ChoiceLuxTheme.* Constants

**Patterns to Remove:**
- `ChoiceLuxTheme.platinumSilver` → Replace with `context.tokens.textBody` or `context.colorScheme.onSurfaceVariant`
- `ChoiceLuxTheme.charcoalGray` → Replace with `context.colorScheme.surface`

**Locations:**
- Section header icons and text (line 288, 295)
- InputDecoration labelStyle/hintStyle (extensive, ~24 instances)
- InputDecoration border colors (extensive, multiple lines)
- Button backgroundColor/foregroundColor (lines 901-902, 921-922, 1203-1204, 1242-1243)
- Card background (line 1296)
- Divider color (line 1327)
- Icon colors (lines 753, 806, 866, 989, 996)

### D3: Inline TextStyle Colors

**Patterns to Remove:**
- `TextStyle(color: ChoiceLuxTheme.platinumSilver.withValues(alpha: ...))` → Replace with `context.textTheme.*.copyWith(color: context.tokens.textBody.withValues(alpha: ...))`
- `TextStyle(color: statusColor)` → Replace with `context.textTheme.bodySmall?.copyWith(color: context.tokens.*)`
- `TextStyle(color: Colors.*)` → Replace with theme token-based colors

**Locations:**
- InputDecoration labelStyle/hintStyle (extensive, ~24 instances)
- License countdown indicator text (line 270-274)
- Placeholder widget text styles (multiple locations)
- Section header text (line 292-296)

### D4: Manual Button Styling

**Patterns to Remove:**
- `ElevatedButton.styleFrom(backgroundColor: ChoiceLuxTheme.platinumSilver.withValues(alpha: ...), foregroundColor: ChoiceLuxTheme.platinumSilver)` → Use theme button styles
- `OutlinedButton.styleFrom(foregroundColor: Colors.red)` → Use theme button styles
- Manual button colors in placeholders → Use theme button styles

**Locations:**
- Upload/Replace/Remove buttons (lines 899-907, 919-927, 937-945)
- Action buttons (lines 1201-1209, 1238-1248)
- Placeholder retry buttons (lines 1039-1056, 1105-1122)

---

## E) Token Replacement Mapping (Brief)

### Status Colors
- `Colors.green` → `context.tokens.successColor` (success states, license countdown "good")
- `Colors.red` → `context.tokens.warningColor` (error states, license countdown "overdue", error borders)
- `Colors.orange` → `context.colorScheme.primary` (if amber) or `context.tokens.warningColor` (if warning) (license countdown "soon", invalid URL placeholder)
- `Colors.blue` → `context.tokens.infoColor` (info states, loading placeholder)

### Text Colors
- `ChoiceLuxTheme.platinumSilver` → `context.tokens.textBody` (body text, labels, hints)
- `Colors.white` → `context.colorScheme.onPrimary` (on primary backgrounds) or `context.tokens.textHeading` (on dark backgrounds)
- `Colors.grey[300]`, `Colors.grey[100]` → `context.colorScheme.surfaceVariant` (placeholder backgrounds)

### Surface Colors
- `ChoiceLuxTheme.charcoalGray` → `context.colorScheme.surface` (card background)
- `Colors.black` → `context.colorScheme.background` or `context.colorScheme.surface` (shadows)

### Border Colors
- `ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.3)` → `context.colorScheme.outline.withValues(alpha: 0.3)` (enabled borders)
- `ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7)` → `context.colorScheme.primary` (focused borders)
- `Colors.red.withValues(alpha: 0.5)` → `context.tokens.warningColor.withValues(alpha: 0.5)` (error borders)

### Button Colors
- `ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.2)` → `context.colorScheme.surfaceVariant` (button backgrounds)
- `ChoiceLuxTheme.platinumSilver` → `context.tokens.textBody` (button foreground)
- `Colors.red` → `context.tokens.warningColor` (delete button foreground)

### Typography
- Inline `TextStyle(color: ...)` → `context.textTheme.bodyLarge?.copyWith(color: context.tokens.textBody)` (or appropriate text theme style)

---

## F) Acceptance Criteria

### F1: Zero Violations in Scope
- [ ] No `Colors.*` usage remains (except `Colors.transparent` if present)
- [ ] No `Color(0xFF...)` literals remain
- [ ] No `ChoiceLuxTheme.*` legacy constants remain
- [ ] No inline `TextStyle(color: ...)` with hard-coded colors remains
- [ ] All colors accessed via `context.colorScheme.*` or `context.tokens.*`
- [ ] All text styles accessed via `context.textTheme.*` with token color overrides

### F2: Compilation
- [ ] `flutter analyze lib/features/vehicles/vehicle_editor_screen.dart` passes with no errors
- [ ] App compiles successfully
- [ ] No new linter warnings introduced

### F3: No Layout Changes
- [ ] Visual appearance matches pre-migration (token replacement only)
- [ ] All form fields render correctly
- [ ] All buttons render correctly
- [ ] All placeholders render correctly
- [ ] Responsive breakpoints unchanged
- [ ] Spacing and sizing unchanged

### F4: Functional Correctness
- [ ] Form validation works correctly
- [ ] Date pickers work correctly
- [ ] Image upload/remove functionality works
- [ ] License countdown indicator displays correctly
- [ ] SnackBar messages display correctly
- [ ] Navigation works correctly

---

## G) Manual Validation Checklist

### G1: Form Fields
- [ ] **Make field:** Label, hint, border colors use theme tokens
- [ ] **Model field:** Label, hint, border colors use theme tokens
- [ ] **Registration Plate field:** Label, hint, border colors use theme tokens
- [ ] **Fuel Type dropdown:** Label, hint, border colors use theme tokens
- [ ] **Status dropdown:** Label, hint, border colors use theme tokens
- [ ] **Branch dropdown (admin only):** Label, hint, border colors use theme tokens
- [ ] **Registration Date field:** Label, hint, border, icon colors use theme tokens
- [ ] **License Expiry Date field:** Label, hint, border, icon colors use theme tokens
- [ ] **Error states:** Error borders use `context.tokens.warningColor`
- [ ] **Focused states:** Focused borders use `context.colorScheme.primary`

### G2: License Countdown Indicator
- [ ] **Overdue state:** Red color uses `context.tokens.warningColor`
- [ ] **Soon state (<30 days):** Orange color uses `context.colorScheme.primary` or appropriate token
- [ ] **Good state (>=30 days):** Green color uses `context.tokens.successColor`
- [ ] **Text color:** Uses theme token (not hard-coded)
- [ ] **Icon color:** Uses theme token (not hard-coded)
- [ ] **Background/border:** Uses theme token with appropriate opacity

### G3: Image Section
- [ ] **Upload button:** Background and foreground use theme tokens
- [ ] **Replace button:** Background and foreground use theme tokens
- [ ] **Remove button:** Foreground uses `context.tokens.warningColor`
- [ ] **Image border:** Uses theme token
- [ ] **Placeholder background:** Uses `context.colorScheme.surfaceVariant`
- [ ] **Placeholder icon/text:** Uses theme tokens
- [ ] **Invalid URL placeholder:** Orange colors use appropriate tokens
- [ ] **Error placeholder:** Red colors use `context.tokens.warningColor`
- [ ] **Loading placeholder:** Blue colors use `context.tokens.infoColor`

### G4: SnackBar Messages
- [ ] **Success message:** Green background uses `context.tokens.successColor`, text uses `context.tokens.onSuccess` or `context.colorScheme.onSurface`
- [ ] **Error message:** Red background uses `context.tokens.warningColor`, text uses `context.tokens.onWarning` or `context.colorScheme.onSurface`
- [ ] **Info message (orange):** Orange background uses `context.colorScheme.primary`, text uses `context.colorScheme.onPrimary`
- [ ] **Info message (blue):** Blue background uses `context.tokens.infoColor`, text uses `context.tokens.onInfo` or `context.colorScheme.onSurface`
- [ ] **Icon colors:** Use appropriate on-color tokens

### G5: Action Buttons
- [ ] **Save/Update button:** Background and foreground use theme tokens
- [ ] **Cancel button:** Foreground uses theme token
- [ ] **Button states:** Hover, active, disabled states work correctly

### G6: Section Headers
- [ ] **Icon color:** Uses theme token (not `ChoiceLuxTheme.platinumSilver`)
- [ ] **Text color:** Uses theme token (not `ChoiceLuxTheme.platinumSilver`)
- [ ] **Text style:** Uses `context.textTheme.titleLarge` with token color override

### G7: Card and Layout
- [ ] **Card background:** Uses `context.colorScheme.surface` (not `ChoiceLuxTheme.charcoalGray`)
- [ ] **Card border:** Uses theme token
- [ ] **Divider:** Uses theme token
- [ ] **Shadow:** Uses theme token (if applicable)

### G8: Responsive States
- [ ] **Mobile layout:** All theme tokens work correctly
- [ ] **Small mobile layout:** All theme tokens work correctly
- [ ] **Desktop layout:** All theme tokens work correctly

### G9: Accessibility
- [ ] **Text contrast:** All text meets minimum contrast ratios (if tools available)
- [ ] **Focus indicators:** Focus borders use `context.colorScheme.primary`
- [ ] **Error indicators:** Error states are clearly visible

### G10: Edge Cases
- [ ] **Empty form:** All fields display correctly
- [ ] **Form with errors:** Error states display correctly
- [ ] **Image upload in progress:** Loading states display correctly
- [ ] **Image upload failure:** Error states display correctly
- [ ] **License expiry overdue:** Countdown indicator displays correctly
- [ ] **License expiry soon:** Countdown indicator displays correctly
- [ ] **License expiry good:** Countdown indicator displays correctly

---

## H) Implementation Notes

### H1: Theme Access
- Add `import 'package:choice_lux_cars/app/theme_helpers.dart';` if not already present
- Use `context.colorScheme.*` for Material 3 colors
- Use `context.tokens.*` for semantic colors (status, text, interactive states)

### H2: InputDecoration Migration
- Replace `labelStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.7))` with `labelStyle: context.textTheme.bodyMedium?.copyWith(color: context.tokens.textBody.withValues(alpha: 0.7))`
- Replace `hintStyle: TextStyle(color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.5))` with `hintStyle: context.textTheme.bodyMedium?.copyWith(color: context.tokens.textSubtle)`
- Replace border colors with `context.colorScheme.outline` (enabled), `context.colorScheme.primary` (focused), `context.tokens.warningColor` (error)

### H3: Status Color Logic
- License countdown indicator: Use conditional logic with theme tokens:
  - Overdue: `context.tokens.warningColor`
  - Soon (<30 days): `context.colorScheme.primary` (if amber) or `context.tokens.warningColor` (if warning)
  - Good (>=30 days): `context.tokens.successColor`

### H4: Button Styling
- Prefer using `ElevatedButtonTheme` and `OutlinedButtonTheme` from theme
- If local style override is necessary, use theme tokens only (no hard-coded colors)
- Delete button: Use `context.tokens.warningColor` for foreground

### H5: Placeholder Widgets
- Replace hard-coded colors with theme tokens
- Use `context.colorScheme.surfaceVariant` for backgrounds
- Use `context.tokens.*` for status colors (error, warning, info)
- Use `context.tokens.textBody` or `context.tokens.textHeading` for text

---

## I) Risks & Mitigation

### I1: InputDecoration Complexity
**Risk:** Extensive InputDecoration styling may cause visual regressions if not carefully migrated.

**Mitigation:**
- Test each form field individually
- Verify all border states (enabled, focused, error, disabled)
- Compare visual appearance before/after migration

### I2: Status Color Logic
**Risk:** License countdown indicator uses conditional logic that must preserve behavior.

**Mitigation:**
- Preserve all conditional logic
- Map status colors to appropriate theme tokens
- Test all three states (overdue, soon, good)

### I3: Placeholder Widgets
**Risk:** Multiple placeholder widgets with hard-coded colors may cause visual regressions.

**Mitigation:**
- Test each placeholder state (empty, invalid URL, error, loading)
- Verify colors match theme specification
- Ensure contrast ratios are maintained

### I4: Button Styling
**Risk:** Manual button styling may have custom logic that needs preservation.

**Mitigation:**
- Preserve all button states and actions
- Use theme tokens for colors only
- Test all button interactions

---

## J) Definition of Done

**Batch 3 is complete when:**
1. ✅ All violations removed (Colors.*, ChoiceLuxTheme.*, inline TextStyle colors)
2. ✅ App compiles successfully
3. ✅ All manual validation checklist items pass
4. ✅ Visual appearance unchanged (token replacement only)
5. ✅ All functional tests pass
6. ✅ `/ai/THEME_MIGRATION_BATCH_3_REPORT.md` created with change summary

---

**Status:** PLAN READY  
**Next Step:** CLC-BUILD implements Batch 3 per this plan  
**Approval Required:** Yes — Before implementation begins



