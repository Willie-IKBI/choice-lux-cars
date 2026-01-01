# Theme Migration Batch 1 Plan — Invoices Feature

**Generated:** 2025-01-XX  
**Agent:** CLC-ARCH  
**Purpose:** Define strict execution plan for Batch 1 theme migration  
**Status:** PLAN READY

**Source:** `/ai/THEME_AUDIT.md` — Batch 1 (Invoices Feature)  
**Enforcement:** `/ai/THEME_RULES.md` — All rules apply  
**Specification:** `/ai/THEME_SPEC.md` — Color values must match exactly

---

## A) Batch Objective

**Goal:** Remove all hard-coded colors and legacy constants from the invoice action buttons widget, replacing them with theme tokens while maintaining exact visual appearance.

**Success Criteria:**
- Zero `Colors.*` usage (except `Colors.transparent` if any)
- Zero hard-coded `Color(0xFF...)` literals
- Zero legacy `ChoiceLuxTheme.*` constants
- All colors sourced from `ColorScheme` or `AppTokens`
- Visual appearance unchanged (token replacement only)
- App compiles without errors
- All interactive states work correctly

**Impact:** High visibility widget used in job summary screens. Fixing this establishes the pattern for subsequent batches.

---

## B) In-Scope Files (Exact Paths)

**Single File:**
- `lib/features/invoices/widgets/invoice_action_buttons.dart`

**Rationale:**
- Small, isolated widget (single file)
- High visibility (used in job summary screens)
- Clear violations (status colors, button styling)
- Easy to validate (single widget, limited states)
- Low risk (isolated, no dependencies on other invoice files)

**File Statistics:**
- **Total Lines:** ~674 lines
- **Violations:** ~20+ instances
- **Severity:** A1 (status colors, button styling)

---

## C) Out-of-Scope Files (Explicit)

**Must NOT Be Modified:**

1. **Invoice Screens:**
   - `lib/features/invoices/invoices_screen.dart` — Out of scope
   - Any other invoice screen files — Out of scope

2. **Invoice Services:**
   - `lib/features/invoices/services/invoice_repository.dart` — Out of scope
   - `lib/features/invoices/services/invoice_pdf_service.dart` — Out of scope (PDF exception)
   - `lib/features/invoices/services/invoice_sharing_service.dart` — Out of scope
   - `lib/features/invoices/services/invoice_config_service.dart` — Out of scope

3. **Invoice Providers:**
   - `lib/features/invoices/providers/invoice_controller.dart` — Out of scope
   - `lib/features/invoices/providers/can_create_invoice_provider.dart` — Out of scope

4. **Invoice Models:**
   - `lib/features/invoices/models/invoice_data.dart` — Out of scope

5. **Other Invoice Widgets:**
   - Any other invoice widget files — Out of scope

6. **Shared Services:**
   - `lib/shared/services/pdf_viewer_service.dart` — Out of scope (deferred per C1.3)

7. **Theme Files:**
   - `lib/app/theme.dart` — Out of scope (authoritative source)
   - `lib/app/theme_tokens.dart` — Out of scope (token definitions)
   - `lib/app/theme_helpers.dart` — Out of scope (extensions)

8. **Any Other Files:**
   - No other files may be modified in this batch

**Enforcement:** REVIEW will reject the PR if any out-of-scope files are modified.

---

## D) What Must Be Replaced (Patterns to Remove)

### D1: Colors.* Usage (Must Remove)

**Pattern:** `Colors.{colorName}` or `Colors.{colorName}[shade]`

**Instances Found:**
1. **Line 82:** `backgroundColor: Colors.green` (SnackBar — success message)
2. **Line 94:** `backgroundColor: Colors.red` (SnackBar — error message)
3. **Line 135:** `backgroundColor: Colors.green` (SnackBar — success message)
4. **Line 144:** `backgroundColor: Colors.red` (SnackBar — error message)
5. **Line 173:** `backgroundColor: Colors.red` (SnackBar — error message)
6. **Line 201:** `backgroundColor: Colors.red` (SnackBar — error message)
7. **Line 408:** `valueColor: AlwaysStoppedAnimation<Color>(Colors.white)` (CircularProgressIndicator)
8. **Line 413:** `backgroundColor: Colors.orange` (ElevatedButton — creating state)
9. **Line 414:** `foregroundColor: Colors.white` (ElevatedButton — creating state)
10. **Line 451:** `backgroundColor: Colors.green` (ElevatedButton — invoice created state)
11. **Line 452:** `foregroundColor: Colors.white` (ElevatedButton — invoice created state)
12. **Line 579:** `color: Colors.grey` (Icon — disabled state)
13. **Line 651:** `color: Colors.red.withValues(alpha: 0.1)` (BoxDecoration — error container)
14. **Line 653:** `border: Border.all(color: Colors.red.withValues(alpha: 0.3))` (BoxDecoration — error border)
15. **Line 658:** `color: Colors.red[700]` (Icon — error icon)
16. **Line 663:** `style: TextStyle(fontSize: 10, color: Colors.red[700])` (TextStyle — error text)

**Total:** 16 instances

### D2: Hard-Coded Color Literals (Must Remove)

**Pattern:** `Color(0xFF...)` or `Color.fromARGB(...)`

**Instances Found:**
- None found in this file (all violations are `Colors.*` usage)

**Total:** 0 instances

### D3: Legacy ChoiceLuxTheme Constants (Must Remove)

**Pattern:** `ChoiceLuxTheme.{constantName}`

**Instances Found:**
- None found in this file (file doesn't import ChoiceLuxTheme)

**Total:** 0 instances

### D4: Inline TextStyle Colors (Must Remove)

**Pattern:** `TextStyle(color: Colors.*)` or `TextStyle(color: Color(0xFF...))`

**Instances Found:**
1. **Line 663:** `style: TextStyle(fontSize: 10, color: Colors.red[700])` (error message text)

**Total:** 1 instance

### D5: Manual Button Styling (Must Use Theme)

**Pattern:** `ElevatedButton.styleFrom(backgroundColor: Colors.*, foregroundColor: Colors.*)`

**Instances Found:**
1. **Line 413-414:** `backgroundColor: Colors.orange, foregroundColor: Colors.white` (creating button)
2. **Line 451-452:** `backgroundColor: Colors.green, foregroundColor: Colors.white` (created button)

**Total:** 2 instances

**Note:** Lines 368-369 and 491-492 already use theme tokens correctly — these should remain as-is.

---

## E) What Tokens to Use Instead (ColorScheme/AppTokens/TextTheme)

### E1: Status Colors (Use AppTokens)

**Replacements:**
- `Colors.green` → `context.tokens.successColor` (for success states)
- `Colors.red` → `context.tokens.warningColor` (for error/warning states)
- `Colors.red[700]` → `context.tokens.warningColor` (for error icons/text)
- `Colors.red.withValues(alpha: 0.1)` → `context.tokens.warningColor.withOpacity(0.1)` (for error container background)
- `Colors.red.withValues(alpha: 0.3)` → `context.tokens.warningColor.withOpacity(0.3)` (for error borders)

**Usage Pattern:**
```dart
// SnackBar success
backgroundColor: context.tokens.successColor

// SnackBar error
backgroundColor: context.tokens.warningColor

// Error container background
color: context.tokens.warningColor.withOpacity(0.1)

// Error border
border: Border.all(color: context.tokens.warningColor.withOpacity(0.3))

// Error icon/text
color: context.tokens.warningColor
```

### E2: Primary Action Colors (Use ColorScheme)

**Replacements:**
- `Colors.orange` → `context.colorScheme.primary` (for primary actions like "creating" state)
- `Colors.white` (on primary background) → `context.colorScheme.onPrimary` (for text/icons on primary)

**Usage Pattern:**
```dart
// Primary button background
backgroundColor: context.colorScheme.primary

// Primary button text/icon
foregroundColor: context.colorScheme.onPrimary
```

### E3: Text Colors (Use AppTokens or TextTheme)

**Replacements:**
- `Colors.white` (for text) → `context.tokens.textHeading` or `context.colorScheme.onSurface`
- `Colors.red[700]` (for error text) → `context.tokens.warningColor`
- Inline `TextStyle(color: Colors.red[700])` → Use `context.textTheme.bodySmall?.copyWith(color: context.tokens.warningColor)`

**Usage Pattern:**
```dart
// Error text
style: context.textTheme.bodySmall?.copyWith(
  color: context.tokens.warningColor,
  fontSize: 10,
)
```

### E4: Disabled State Colors (Use ColorScheme)

**Replacements:**
- `Colors.grey` (for disabled icons) → `context.colorScheme.outline` or `context.tokens.textSubtle`

**Usage Pattern:**
```dart
// Disabled icon
color: context.tokens.textSubtle
```

### E5: CircularProgressIndicator Colors (Use ColorScheme)

**Replacements:**
- `Colors.white` (for progress indicator) → `context.colorScheme.onPrimary` (if on primary background) or `context.colorScheme.primary` (if on transparent background)

**Usage Pattern:**
```dart
// Progress indicator on primary button
valueColor: AlwaysStoppedAnimation<Color>(
  context.colorScheme.onPrimary,
)
```

### E6: Button Styling (Use Theme Defaults Where Possible)

**Current State:**
- Lines 368-369: Already uses `context.colorScheme.primary` and `context.colorScheme.onPrimary` ✅
- Lines 491-492: Already uses `context.colorScheme.primary` and `context.colorScheme.onPrimary` ✅
- Lines 413-414: Uses `Colors.orange` and `Colors.white` ❌
- Lines 451-452: Uses `Colors.green` and `Colors.white` ❌

**Required Changes:**
- Lines 413-414: Replace with `context.colorScheme.primary` and `context.colorScheme.onPrimary` (creating state should use primary color)
- Lines 451-452: Replace with `context.tokens.successColor` and `context.tokens.onSuccess` (success state should use success color)

**Note:** If `onSuccess` token doesn't exist in AppTokens, use `context.colorScheme.onSurface` or appropriate contrast color.

---

## F) Acceptance Criteria

### F1: No Violations Remaining In-Scope

**Verification:**
- [ ] Zero instances of `Colors.*` (except `Colors.transparent` if any)
- [ ] Zero instances of `Color(0xFF...)` or `Color.fromARGB(...)`
- [ ] Zero instances of `ChoiceLuxTheme.*` constants
- [ ] Zero inline `TextStyle(color: Colors.*)` or `TextStyle(color: Color(0xFF...))`

**Verification Command:**
```bash
# Check for Colors.* usage (should return 0 matches, or only Colors.transparent)
grep -n "Colors\." lib/features/invoices/widgets/invoice_action_buttons.dart | grep -v "Colors.transparent"

# Check for Color(0x...) literals (should return 0 matches)
grep -n "Color(0x" lib/features/invoices/widgets/invoice_action_buttons.dart

# Check for ChoiceLuxTheme.* (should return 0 matches)
grep -n "ChoiceLuxTheme\." lib/features/invoices/widgets/invoice_action_buttons.dart
```

### F2: Compilation Success

**Verification:**
- [ ] `flutter analyze` passes with no errors
- [ ] `flutter build web` (or target platform) succeeds
- [ ] No import errors
- [ ] No type errors
- [ ] No undefined token errors

**Verification Command:**
```bash
flutter analyze lib/features/invoices/widgets/invoice_action_buttons.dart
```

### F3: No Layout Changes

**Verification:**
- [ ] Button sizes unchanged (width, height, padding)
- [ ] Button positions unchanged (spacing, alignment)
- [ ] Text sizes unchanged (fontSize values remain the same)
- [ ] Border radius unchanged (8px, 6px, 999px values remain)
- [ ] Icon sizes unchanged (16px, 14px, 12px values remain)
- [ ] Container dimensions unchanged (32x32 for icon action)

**Verification Method:**
- Visual comparison (screenshot before/after)
- Code review of spacing/sizing values
- No changes to layout-related properties (only color properties changed)

### F4: Visual Appearance Unchanged

**Verification:**
- [ ] Success SnackBar appears green (using `context.tokens.successColor`)
- [ ] Error SnackBar appears red (using `context.tokens.warningColor`)
- [ ] "Creating Invoice" button appears orange/amber (using `context.colorScheme.primary`)
- [ ] "Invoice Created" button appears green (using `context.tokens.successColor`)
- [ ] Error message container has red background with transparency (using `context.tokens.warningColor.withOpacity(0.1)`)
- [ ] Error message border is red (using `context.tokens.warningColor.withOpacity(0.3)`)
- [ ] Error icon/text is red (using `context.tokens.warningColor`)
- [ ] Disabled icon is grey/subtle (using `context.tokens.textSubtle`)

**Verification Method:**
- Manual visual inspection
- Screenshot comparison (if available)
- Side-by-side comparison with original

### F5: Interactive States Work

**Verification:**
- [ ] "Create Invoice" button works (creates invoice, shows success SnackBar)
- [ ] "Creating Invoice" button shows loading state correctly
- [ ] "Invoice Created" button displays correctly (non-clickable status)
- [ ] "View Invoice" button works (opens PDF viewer)
- [ ] "Reload Invoice" button works (regenerates invoice, shows success/error SnackBar)
- [ ] Share icon works (opens share options)
- [ ] Error message displays when invoice creation fails
- [ ] Loading indicator displays during invoice creation
- [ ] Disabled states work correctly (icon shows grey when disabled)

**Verification Method:**
- Manual testing of all button actions
- Test success and error flows
- Test loading states
- Test disabled states

---

## G) Manual Validation Checklist (Exact Screens/Flows)

### G1: Job Summary Screen — Invoice Section

**Screen:** `lib/features/jobs/screens/job_summary_screen.dart` (where widget is used)

**Test Flow 1: Create Invoice (Success)**
1. Navigate to job summary screen for a job without an invoice
2. Locate invoice action buttons widget
3. Verify "Create Invoice" button is visible (primary color/amber)
4. Click "Create Invoice" button
5. Verify button changes to "Creating Invoice..." (primary color/amber, disabled)
6. Verify loading indicator appears below button
7. Wait for invoice creation to complete
8. Verify success SnackBar appears (green background, white text)
9. Verify button changes to "Invoice Created" (green background, white text)
10. Verify "View Invoice", "Reload Invoice", and share icon buttons appear
11. Verify all buttons are correctly colored (primary for View, secondary for Reload, theme-compliant for share icon)

**Test Flow 2: Create Invoice (Error)**
1. Navigate to job summary screen
2. Click "Create Invoice" button
3. Simulate error (if possible) or wait for actual error
4. Verify error SnackBar appears (red background, white text)
5. Verify error message container appears below buttons (red background with transparency, red border)
6. Verify error icon is red
7. Verify error text is red and readable

**Test Flow 3: Regenerate Invoice (Success)**
1. Navigate to job summary screen for a job with an existing invoice
2. Verify "Invoice Created" button is visible (green)
3. Click "Reload Invoice" button
4. Verify confirmation dialog appears (uses theme colors)
5. Click "Regenerate" in dialog
6. Verify success SnackBar appears (green background)
7. Verify invoice PDF URL updates

**Test Flow 4: Regenerate Invoice (Error)**
1. Navigate to job summary screen for a job with an existing invoice
2. Click "Reload Invoice" button
3. Click "Regenerate" in dialog
4. Simulate error (if possible)
5. Verify error SnackBar appears (red background)
6. Verify error message container appears (if applicable)

**Test Flow 5: View Invoice**
1. Navigate to job summary screen for a job with an existing invoice
2. Click "View Invoice" button
3. Verify PDF viewer opens (uses theme colors)
4. Verify no color-related errors in console

**Test Flow 6: Share Invoice**
1. Navigate to job summary screen for a job with an existing invoice
2. Click share icon button
3. Verify share options appear (uses theme colors)
4. Verify no color-related errors in console

**Test Flow 7: No Permission State**
1. Navigate to job summary screen with user that cannot create invoices
2. Verify "Insufficient permissions" message appears (uses theme colors)
3. Verify message text and icon use theme tokens

**Test Flow 8: Disabled States**
1. Navigate to job summary screen
2. Trigger loading state (create invoice)
3. Verify share icon is disabled (grey/subtle color)
4. Verify disabled icon uses `context.tokens.textSubtle`

### G2: Visual Regression Testing

**Screenshots Required:**
1. **Before Migration:** Capture screenshots of all invoice button states
   - No invoice state (Create Invoice button)
   - Creating invoice state (Creating Invoice... button with loading)
   - Invoice created state (Invoice Created button + action buttons)
   - Error state (error message container)
   - No permission state (permission message)

2. **After Migration:** Capture same screenshots
   - Compare side-by-side
   - Verify colors match (may be slightly different if theme tokens differ from hard-coded values, but should be close)
   - Verify layout is identical

**Comparison Points:**
- Button colors (background, text, icons)
- SnackBar colors (background, text)
- Error message colors (background, border, icon, text)
- Loading indicator colors
- Disabled state colors
- Layout spacing and sizing

### G3: Accessibility Verification

**Contrast Ratios:**
- [ ] Success SnackBar: Green background (`context.tokens.successColor`) with white text meets WCAG AA (4.5:1)
- [ ] Error SnackBar: Red background (`context.tokens.warningColor`) with white text meets WCAG AA (4.5:1)
- [ ] Primary buttons: Amber background (`context.colorScheme.primary`) with dark text meets WCAG AA (4.5:1)
- [ ] Success button: Green background (`context.tokens.successColor`) with white text meets WCAG AA (4.5:1)
- [ ] Error text: Red text (`context.tokens.warningColor`) on transparent/error container background meets WCAG AA (4.5:1)

**Verification Method:**
- Use contrast checker tool (if available)
- Manual verification using WCAG contrast calculator
- Visual inspection (text should be clearly readable)

---

## H) Implementation Notes

### H1: Required Imports

**Current Imports:**
- `package:flutter/material.dart` ✅
- `package:flutter_riverpod/flutter_riverpod.dart` ✅
- Invoice feature imports ✅

**Required Addition:**
- `package:choice_lux_cars/app/theme_helpers.dart` (for `context.tokens` and `context.colorScheme` extensions)

**Or Use Direct Access:**
- `Theme.of(context).extension<AppTokens>()!` (if extension not available)
- `Theme.of(context).colorScheme` (if extension not available)

### H2: Token Access Pattern

**Preferred Pattern:**
```dart
// Use extension methods (if theme_helpers.dart is imported)
context.tokens.successColor
context.tokens.warningColor
context.colorScheme.primary
context.colorScheme.onPrimary
```

**Fallback Pattern:**
```dart
// Use Theme.of(context) directly
Theme.of(context).extension<AppTokens>()!.successColor
Theme.of(context).extension<AppTokens>()!.warningColor
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.onPrimary
```

### H3: SnackBar Theme Compliance

**Current Issue:** SnackBars use hard-coded `backgroundColor` which overrides theme.

**Required Fix:**
- Remove `backgroundColor` from SnackBar constructors
- Use `SnackBarTheme` from theme (defined in `lib/app/theme.dart`)
- For success/error variants, may need to use `SnackBarTheme` with conditional styling or create custom SnackBar widget

**Alternative Approach:**
- Keep `backgroundColor` but use theme tokens instead of `Colors.*`
- This maintains visual appearance while using tokens

**Decision:** Use theme tokens in `backgroundColor` (maintains current behavior, uses tokens).

### H4: Button Theme Compliance

**Current Issue:** Some buttons override theme with manual `backgroundColor`/`foregroundColor`.

**Required Fix:**
- Replace `Colors.orange` with `context.colorScheme.primary`
- Replace `Colors.green` with `context.tokens.successColor`
- Replace `Colors.white` with appropriate `onPrimary` or `onSuccess` token

**Note:** Buttons already use `ElevatedButton.styleFrom()` which is correct. Only need to replace color values with tokens.

### H5: Error Message Container

**Current Issue:** Uses `Colors.red` with opacity for background and border.

**Required Fix:**
- Replace `Colors.red.withValues(alpha: 0.1)` with `context.tokens.warningColor.withOpacity(0.1)`
- Replace `Colors.red.withValues(alpha: 0.3)` with `context.tokens.warningColor.withOpacity(0.3)`
- Replace `Colors.red[700]` with `context.tokens.warningColor`

**Note:** `.withValues(alpha:)` is Flutter 3.27+ syntax. Use `.withOpacity()` for compatibility.

### H6: TextStyle Migration

**Current Issue:** Inline `TextStyle(color: Colors.red[700])` for error text.

**Required Fix:**
- Use `context.textTheme.bodySmall?.copyWith(color: context.tokens.warningColor, fontSize: 10)`
- Maintains fontSize: 10 (as per current code)
- Uses theme token for color

---

## I) Risk Mitigation

### I1: Visual Appearance Changes

**Risk:** Theme tokens may have slightly different hex values than hard-coded colors, causing visual changes.

**Mitigation:**
- Verify token values match THEME_SPEC.md exactly
- If tokens differ, document the difference and get approval
- Use screenshot comparison to verify visual appearance

### I2: SnackBar Theme Override

**Risk:** Removing `backgroundColor` from SnackBar may cause it to use theme default, changing appearance.

**Mitigation:**
- Keep `backgroundColor` but use theme tokens
- This maintains current behavior while using tokens
- Verify SnackBar appearance matches original

### I3: Button State Colors

**Risk:** Replacing `Colors.orange` with `context.colorScheme.primary` may change button color if primary is not orange/amber.

**Mitigation:**
- Verify `context.colorScheme.primary` is `#f59e0b` (amber) per THEME_SPEC.md
- If different, document and get approval
- Use screenshot comparison

### I4: Error Message Contrast

**Risk:** Error message container with `warningColor.withOpacity(0.1)` may not have sufficient contrast.

**Mitigation:**
- Test error message readability
- Verify text is clearly visible on background
- Adjust opacity if needed (but maintain visual appearance)

### I5: Disabled State Visibility

**Risk:** Replacing `Colors.grey` with `context.tokens.textSubtle` may make disabled icon less visible.

**Mitigation:**
- Verify `textSubtle` token is `#52525b` per THEME_SPEC.md
- Test disabled icon visibility
- Adjust if needed (but maintain visual appearance)

---

## J) Rollback Plan

**If Issues Arise:**
1. Revert changes to `lib/features/invoices/widgets/invoice_action_buttons.dart`
2. Restore original hard-coded colors
3. Document issues encountered
4. Request ARCH review before retry

**Git Commands:**
```bash
# Revert file to previous commit
git checkout HEAD -- lib/features/invoices/widgets/invoice_action_buttons.dart

# Or restore from backup
git restore lib/features/invoices/widgets/invoice_action_buttons.dart
```

---

**Status:** PLAN READY  
**Next Step:** CLC-BUILD implements Batch 1 following this plan  
**Approval Required:** Yes — Before implementation begins

