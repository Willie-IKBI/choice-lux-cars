# Theme Migration Batch 4 Plan — SnackBar Utilities

**Generated:** 2025-01-XX  
**Agent:** CLC-ARCH  
**Purpose:** Define strict execution plan for Theme Migration Batch 4  
**Status:** PLAN READY

**Source Documents:**
- `/ai/THEME_SPEC.md` — Theme specification
- `/ai/THEME_RULES.md` — Enforcement rules
- `/ai/THEME_AUDIT.md` — Violation audit (Batch 4: Shared Utilities)

---

## A) Batch Objective

**Goal:** Migrate `lib/shared/utils/snackbar_utils.dart` to use theme tokens exclusively, removing all legacy `ChoiceLuxTheme.*` constants. This utility is used across multiple features, so fixing it will improve theme compliance app-wide.

**Rationale:**
- **High reusability:** Used in 5+ files across jobs, notifications, and other features
- **Small scope:** Single file, ~8 violations
- **Low coupling:** Utility class with no complex dependencies
- **High impact:** All SnackBar messages across the app will benefit
- **Easy validation:** Simple to test SnackBar appearance
- **Clear violations:** All violations are `ChoiceLuxTheme.*` constants

**Expected Impact:**
- Consistent SnackBar colors across all features
- Foundation for future feature migrations (they'll automatically use theme-compliant SnackBars)
- Removal of ~8 theme violations
- Improved accessibility (theme tokens ensure proper contrast)

---

## B) In-Scope Files (Exact Paths)

**Single File:**
- `lib/shared/utils/snackbar_utils.dart`

**File Statistics:**
- Total lines: ~110
- Estimated violations: ~8 instances
- Violation types: `ChoiceLuxTheme.*` constants (successColor, errorColor, orange, infoColor)
- Severity: A1 (status colors), B1 (styling cleanup)

---

## C) Out-of-Scope Files (Explicit)

**Explicitly Excluded:**

1. **SnackBar Call Sites:**
   - All files that call `SnackBarUtils.showSuccess()`, `SnackBarUtils.showError()`, etc. — Out of scope
   - These will automatically benefit from the utility migration

2. **Direct SnackBar Usage:**
   - Files that create SnackBar directly (not via SnackBarUtils) — Out of scope
   - These will be migrated in their respective feature batches

3. **Theme Files:**
   - `lib/app/theme.dart` — Out of scope (authoritative source)
   - `lib/app/theme_tokens.dart` — Out of scope (token definitions)
   - `lib/app/theme_helpers.dart` — Out of scope (extensions)

4. **Other Shared Utilities:**
   - `lib/shared/utils/status_color_utils.dart` — Out of scope (already migrated in Batch 0)
   - Any other shared utilities — Out of scope

5. **Any Other Files:**
   - No other files may be modified in this batch

**Enforcement:** REVIEW will reject the PR if any out-of-scope files are modified.

---

## D) Patterns to Remove

### D1: Legacy ChoiceLuxTheme.* Constants (Must Remove)

**Patterns to Remove:**
- `ChoiceLuxTheme.successColor` → Replace with `context.tokens.successColor`
- `ChoiceLuxTheme.errorColor` → Replace with `context.tokens.warningColor` (per THEME_SPEC.md, errors use warning token)
- `ChoiceLuxTheme.orange` → Replace with `context.colorScheme.primary` (if amber) or `context.tokens.warningColor` (if warning)
- `ChoiceLuxTheme.infoColor` → Replace with `context.tokens.infoColor`

**Locations:**
- Line 12: `backgroundColor: ChoiceLuxTheme.successColor` (showSuccess)
- Line 25: `backgroundColor: ChoiceLuxTheme.errorColor` (showError)
- Line 38: `backgroundColor: ChoiceLuxTheme.orange` (showWarning)
- Line 51: `backgroundColor: ChoiceLuxTheme.infoColor` (showInfo)
- Line 70: `backgroundColor: ChoiceLuxTheme.successColor` (showSuccessSafe)
- Line 96: `backgroundColor: ChoiceLuxTheme.errorColor` (showErrorSafe)

**Total:** ~6-8 instances (some methods may have duplicates)

---

## E) Token Replacement Mapping (Brief)

### SnackBar Background Colors

| Old Pattern | New Pattern | Token Used | Hex Value | Rationale |
|-------------|-------------|------------|-----------|-----------|
| `ChoiceLuxTheme.successColor` | `context.tokens.successColor` | `successColor` | `#10b981` | Success states per THEME_SPEC.md |
| `ChoiceLuxTheme.errorColor` | `context.tokens.warningColor` | `warningColor` | `#f43f5e` | Error states use warning token per THEME_SPEC.md |
| `ChoiceLuxTheme.orange` | `context.colorScheme.primary` | `primary` | `#f59e0b` | Orange/amber maps to primary token |
| `ChoiceLuxTheme.infoColor` | `context.tokens.infoColor` | `infoColor` | `#3b82f6` | Info states per THEME_SPEC.md |

### SnackBar Text Colors (If Needed)

**Note:** SnackBar text color should use Material's default `onSurface` or appropriate on-color tokens:
- Success SnackBar: Text should use `context.tokens.onSuccess` or `context.colorScheme.onSurface`
- Error SnackBar: Text should use `context.tokens.onWarning` or `context.colorScheme.onSurface`
- Warning SnackBar: Text should use `context.colorScheme.onPrimary` (if using primary background)
- Info SnackBar: Text should use `context.tokens.onInfo` or `context.colorScheme.onSurface`

**Current Implementation:** SnackBar uses default text color (Material handles this). If text color needs to be explicit, use appropriate on-color tokens.

---

## F) Acceptance Criteria

### F1: Zero Violations In-Scope

**Verification:**
- [ ] No `ChoiceLuxTheme.*` constants remain in `snackbar_utils.dart`
- [ ] All colors accessed via `context.tokens.*` or `context.colorScheme.*`
- [ ] All methods require `BuildContext` parameter (if not already present)

**Verification Command:**
```bash
# Check for ChoiceLuxTheme.* usage (should return 0 matches)
grep -n "ChoiceLuxTheme\." lib/shared/utils/snackbar_utils.dart

# Check for Colors.* usage (should return 0 matches, or only Colors.transparent if any)
grep -n "Colors\." lib/shared/utils/snackbar_utils.dart | grep -v "Colors.transparent"

# Check for Color(0x...) literals (should return 0 matches)
grep -n "Color(0x" lib/shared/utils/snackbar_utils.dart
```

### F2: Compilation

**Verification:**
- [ ] `flutter analyze lib/shared/utils/snackbar_utils.dart` passes with no errors
- [ ] App compiles successfully
- [ ] All call sites continue to work (no breaking changes)
- [ ] No new linter warnings introduced

**Verification Command:**
```bash
flutter analyze lib/shared/utils/snackbar_utils.dart
```

### F3: No Layout Changes

**Verification:**
- [ ] SnackBar appearance matches pre-migration (token replacement only)
- [ ] SnackBar sizes unchanged (height, padding, border radius)
- [ ] SnackBar behavior unchanged (floating, duration)
- [ ] SnackBar positioning unchanged

**Verification Method:**
- Visual comparison (screenshot before/after)
- Code review of SnackBar properties (only color properties changed)

### F4: Functional Correctness

**Verification:**
- [ ] Success SnackBar displays with correct green background
- [ ] Error SnackBar displays with correct red/pink background
- [ ] Warning SnackBar displays with correct amber/orange background
- [ ] Info SnackBar displays with correct blue background
- [ ] All SnackBar methods work correctly (showSuccess, showError, showWarning, showInfo, showSuccessSafe, showErrorSafe)
- [ ] Safe methods handle mounted check correctly

---

## G) Manual Validation Checklist (Specific Screens/States)

### G1: Success SnackBar

**Test Locations:**
- Any screen that calls `SnackBarUtils.showSuccess()` or `SnackBarUtils.showSuccessSafe()`

**Test Flow:**
1. Trigger a success action (e.g., save vehicle, create job, upload image)
2. Verify SnackBar appears with:
   - Background: `context.tokens.successColor` (#10b981 - green)
   - Text: Default Material text color (should be readable on green background)
   - Behavior: Floating
   - Duration: 3 seconds
   - Shape: RoundedRectangleBorder with 8px border radius

**Expected Appearance:**
- Green background (#10b981)
- White or dark text (Material default, should meet contrast requirements)
- Floating above content
- Rounded corners

### G2: Error SnackBar

**Test Locations:**
- Any screen that calls `SnackBarUtils.showError()` or `SnackBarUtils.showErrorSafe()`

**Test Flow:**
1. Trigger an error action (e.g., failed save, network error, validation error)
2. Verify SnackBar appears with:
   - Background: `context.tokens.warningColor` (#f43f5e - red/pink)
   - Text: Default Material text color (should be readable on red background)
   - Behavior: Floating
   - Duration: 4 seconds (longer than success for errors)
   - Shape: RoundedRectangleBorder with 8px border radius

**Expected Appearance:**
- Red/pink background (#f43f5e)
- White or light text (Material default, should meet contrast requirements)
- Floating above content
- Rounded corners

### G3: Warning SnackBar

**Test Locations:**
- Any screen that calls `SnackBarUtils.showWarning()`

**Test Flow:**
1. Trigger a warning action (if any exists in the app)
2. Verify SnackBar appears with:
   - Background: `context.colorScheme.primary` (#f59e0b - amber/orange)
   - Text: Default Material text color (should be readable on amber background)
   - Behavior: Floating
   - Duration: 3 seconds
   - Shape: RoundedRectangleBorder with 8px border radius

**Expected Appearance:**
- Amber/orange background (#f59e0b)
- Dark text (Material default, should meet contrast requirements)
- Floating above content
- Rounded corners

### G4: Info SnackBar

**Test Locations:**
- Any screen that calls `SnackBarUtils.showInfo()`

**Test Flow:**
1. Trigger an info action (if any exists in the app)
2. Verify SnackBar appears with:
   - Background: `context.tokens.infoColor` (#3b82f6 - blue)
   - Text: Default Material text color (should be readable on blue background)
   - Behavior: Floating
   - Duration: 3 seconds
   - Shape: RoundedRectangleBorder with 8px border radius

**Expected Appearance:**
- Blue background (#3b82f6)
   - White or light text (Material default, should meet contrast requirements)
   - Floating above content
   - Rounded corners

### G5: Safe Methods (Mounted Check)

**Test Locations:**
- Any screen that calls `SnackBarUtils.showSuccessSafe()` or `SnackBarUtils.showErrorSafe()`

**Test Flow:**
1. Trigger a success/error action that uses safe method
2. Verify SnackBar appears correctly (same as G1/G2)
3. Verify no errors occur if widget is unmounted
4. Verify mounted check works correctly

**Expected Behavior:**
- SnackBar displays correctly when widget is mounted
- No errors when widget is unmounted
- Error logging works correctly (if widget is deactivated)

### G6: Multiple SnackBars (Stacking)

**Test Flow:**
1. Trigger multiple SnackBars in quick succession
2. Verify SnackBars stack correctly
3. Verify each SnackBar uses correct theme colors
4. Verify SnackBars dismiss in correct order

**Expected Behavior:**
- SnackBars stack vertically
- Each SnackBar maintains correct theme colors
- SnackBars dismiss in LIFO order

### G7: Accessibility (Contrast)

**Test Flow:**
1. Display each SnackBar type (success, error, warning, info)
2. Verify text is readable on background
3. Verify contrast ratio meets WCAG AA (4.5:1 minimum)

**Expected Contrast:**
- Success: Text on #10b981 background should meet 4.5:1
- Error: Text on #f43f5e background should meet 4.5:1
- Warning: Text on #f59e0b background should meet 4.5:1
- Info: Text on #3b82f6 background should meet 4.5:1

**Verification Method:**
- Use contrast checker tool (e.g., WebAIM Contrast Checker)
- Manual verification using WCAG contrast calculator
- Visual inspection (text should be clearly readable)

### G8: Call Sites (Automatic Benefit)

**Test Locations:**
- `lib/features/jobs/screens/job_summary_screen.dart` (if uses SnackBarUtils)
- `lib/features/jobs/screens/job_progress_screen.dart` (if uses SnackBarUtils)
- `lib/features/notifications/screens/notification_list_screen.dart` (if uses SnackBarUtils)
- `lib/features/jobs/screens/create_job_screen.dart` (if uses SnackBarUtils)
- Any other files that use SnackBarUtils

**Test Flow:**
1. Navigate to each screen that uses SnackBarUtils
2. Trigger actions that show SnackBars
3. Verify SnackBars use theme tokens (automatic benefit)
4. Verify no visual regressions

**Expected Behavior:**
- All SnackBars across the app use theme tokens
- No breaking changes to call sites
- Visual appearance unchanged (colors may be slightly different if tokens differ from legacy constants)

---

## H) Implementation Notes

### H1: Required Imports

**Current Imports:**
- `package:flutter/material.dart` ✅
- `package:choice_lux_cars/app/theme.dart` ❌ (will be removed)
- `package:choice_lux_cars/core/logging/log.dart` ✅

**Required Addition:**
- `package:choice_lux_cars/app/theme_helpers.dart` (for `context.tokens` and `context.colorScheme` extensions)

**Required Removal:**
- `package:choice_lux_cars/app/theme.dart` (if only used for ChoiceLuxTheme constants)

### H2: Method Signature Changes

**Current Methods:**
- `showSuccess(BuildContext context, String message)` — Already has BuildContext ✅
- `showError(BuildContext context, String message)` — Already has BuildContext ✅
- `showWarning(BuildContext context, String message)` — Already has BuildContext ✅
- `showInfo(BuildContext context, String message)` — Already has BuildContext ✅
- `showSuccessSafe(BuildContext context, String message, {bool mounted = true})` — Already has BuildContext ✅
- `showErrorSafe(BuildContext context, String message, {bool mounted = true})` — Already has BuildContext ✅

**No Signature Changes Required:** All methods already accept `BuildContext`, so no breaking changes needed.

### H3: Token Access Pattern

**Preferred Pattern:**
```dart
// Use extension methods (if theme_helpers.dart is imported)
context.tokens.successColor
context.tokens.warningColor
context.tokens.infoColor
context.colorScheme.primary
```

**Fallback Pattern:**
```dart
// Use Theme.of(context) directly
Theme.of(context).extension<AppTokens>()!.successColor
Theme.of(context).colorScheme.primary
```

### H4: SnackBar Text Color (If Needed)

**Current Implementation:** SnackBar uses Material's default text color, which should be appropriate for the background.

**If Text Color Needs to Be Explicit:**
```dart
SnackBar(
  content: Text(
    message,
    style: TextStyle(
      color: context.tokens.onSuccess, // or context.colorScheme.onSurface
    ),
  ),
  backgroundColor: context.tokens.successColor,
  // ... other properties
)
```

**Decision:** Keep default Material text color unless contrast issues are found. Material should handle text color automatically based on background.

### H5: Error Color Mapping

**Important:** Per THEME_SPEC.md, error states use the `warningColor` token (#f43f5e), not a separate error token.

**Mapping:**
- `ChoiceLuxTheme.errorColor` → `context.tokens.warningColor` (#f43f5e)

**Rationale:** THEME_SPEC.md Section 2 (Status Tokens) defines `warning` as "Warning states, urgent alerts, error conditions". Errors are a type of warning state.

---

## I) Risks & Mitigation

### I1: Text Color Contrast

**Risk:** SnackBar text color may not meet contrast requirements if Material default doesn't work well with theme tokens.

**Mitigation:**
- Test all SnackBar types for contrast
- If contrast issues found, explicitly set text color using appropriate on-color tokens
- Verify WCAG AA compliance (4.5:1 minimum)

### I2: Call Site Compatibility

**Risk:** Changing SnackBar colors may cause visual regressions if call sites expect specific colors.

**Mitigation:**
- Token values should match legacy constants (verify against THEME_SPEC.md)
- Test all call sites to ensure SnackBars display correctly
- Visual comparison before/after migration

### I3: Safe Methods Behavior

**Risk:** Safe methods may have edge cases with mounted check that need preservation.

**Mitigation:**
- Preserve all existing logic (mounted check, error handling)
- Only change color properties
- Test safe methods with unmounted widgets

---

## J) Definition of Done

**Batch 4 is complete when:**
1. ✅ All `ChoiceLuxTheme.*` constants removed from `snackbar_utils.dart`
2. ✅ All colors use theme tokens (`context.tokens.*` or `context.colorScheme.*`)
3. ✅ App compiles successfully
4. ✅ All call sites continue to work (no breaking changes)
5. ✅ All manual validation checklist items pass
6. ✅ SnackBar appearance unchanged (token replacement only)
7. ✅ All functional tests pass
8. ✅ `/ai/THEME_MIGRATION_BATCH_4_REPORT.md` created with change summary

---

**Status:** PLAN READY  
**Next Step:** CLC-BUILD implements Batch 4 per this plan  
**Approval Required:** Yes — Before implementation begins




