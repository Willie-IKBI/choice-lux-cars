# Theme Migration Batch 2 Plan — Auth Feature

**Generated:** 2025-01-XX  
**Agent:** CLC-ARCH  
**Purpose:** Define strict execution plan for Batch 2 theme migration  
**Status:** PLAN READY

**Source:** `/ai/THEME_AUDIT.md` — Batch 2 (Auth Feature)  
**Enforcement:** `/ai/THEME_RULES.md` — All rules apply  
**Specification:** `/ai/THEME_SPEC.md` — Color values must match exactly

---

## A) Batch Objective

**Goal:** Remove all hard-coded colors and legacy constants from the login and signup screens, replacing them with theme tokens while maintaining exact visual appearance.

**Success Criteria:**
- Zero `Colors.*` usage (except `Colors.transparent` if any)
- Zero hard-coded `Color(0xFF...)` literals
- Zero legacy `ChoiceLuxTheme.*` constants
- All colors sourced from `ColorScheme` or `AppTokens`
- Visual appearance unchanged (token replacement only)
- App compiles without errors
- All interactive states work correctly
- Form validation states work correctly

**Impact:** High-traffic entry point screens. Fixing these establishes the pattern for form-based screens and improves accessibility.

---

## B) In-Scope Files (Exact Paths)

**Files:**
1. `lib/features/auth/login/login_screen.dart`
2. `lib/features/auth/signup/signup_screen.dart`

**Rationale:**
- High-traffic screens (entry point for all users)
- Clear violations (Colors.*, ChoiceLuxTheme.*, inline TextStyle)
- Accessibility issues (text colors may not meet contrast requirements)
- Similar patterns (can be migrated together)
- Medium scope (2 files, manageable complexity)

**File Statistics:**
- **login_screen.dart:** ~907 lines, ~30+ violations
- **signup_screen.dart:** ~690 lines, ~29+ violations
- **Total Violations:** ~59+ instances
- **Severity:** A1 (text accessibility), B1 (styling cleanup)

---

## C) Out-of-Scope Files (Explicit)

**Must NOT Be Modified:**

1. **Auth Providers:**
   - `lib/features/auth/providers/auth_provider.dart` — Out of scope
   - Any other auth provider files — Out of scope

2. **Auth Services:**
   - Any auth service files — Out of scope

3. **Auth Utilities:**
   - `lib/core/utils/auth_error_utils.dart` — Out of scope
   - `lib/shared/utils/background_pattern_utils.dart` — Out of scope (may contain colors, but separate concern)

4. **Other Auth Screens:**
   - `lib/features/auth/forgot_password/forgot_password_screen.dart` — Out of scope
   - `lib/features/auth/reset_password/reset_password_screen.dart` — Out of scope
   - `lib/features/auth/pending_approval_screen.dart` — Out of scope

5. **Theme Files:**
   - `lib/app/theme.dart` — Out of scope (authoritative source)
   - `lib/app/theme_tokens.dart` — Out of scope (token definitions)
   - `lib/app/theme_helpers.dart` — Out of scope (extensions)

6. **Core Constants:**
   - `lib/core/constants.dart` — Out of scope

7. **Any Other Files:**
   - No other files may be modified in this batch

**Enforcement:** REVIEW will reject the PR if any out-of-scope files are modified.

---

## D) What Must Be Replaced (Patterns to Remove)

### D1: Colors.* Usage (Must Remove)

**Pattern:** `Colors.{colorName}` or `Colors.{colorName}.withValues(alpha: ...)`

**Instances Found in login_screen.dart:**
1. **Line 178:** `fillColor: Colors.white.withValues(alpha: 0.05)` (InputDecoration fill)
2. **Line 181:** `borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))` (InputDecoration border)
3. **Line 185:** `borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))` (InputDecoration enabledBorder)
4. **Line 193:** `borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5))` (InputDecoration errorBorder)
5. **Line 197:** `borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.8))` (InputDecoration focusedErrorBorder)
6. **Line 259:** `color: Colors.black.withValues(alpha: 0.4)` (Container/decoration)
7. **Line 262:** `color: Colors.white.withValues(alpha: 0.2)` (Container/decoration)
8. **Line 267:** `color: Colors.black.withValues(alpha: 0.3)` (Container/decoration)
9. **Line 308:** `color: Colors.black.withValues(alpha: ...)` (Container/decoration - truncated in grep)
10. **Line 575:** `Colors.grey` (likely in a conditional or widget)
11. **Line 666:** `Colors.grey` (likely in a conditional or widget)
12. **Line 751:** `foregroundColor: Colors.black` (Button styling)
13. **Line 794:** `Colors.black` (likely in a widget)
14. **Line 805:** `color: Colors.black` (likely in a widget)
15. **Line 891:** `backgroundColor: Colors.red` (SnackBar or error indicator)

**Instances Found in signup_screen.dart:**
1. **Line 109:** `color: Colors.black.withValues(alpha: 0.4)` (Container/decoration)
2. **Line 112:** `color: Colors.white.withValues(alpha: 0.2)` (Container/decoration)
3. **Line 117:** `color: Colors.black.withValues(alpha: 0.3)` (Container/decoration)
4. **Line 158:** `color: Colors.black.withValues(alpha: ...)` (Container/decoration - truncated in grep)
5. **Line 492:** `foregroundColor: Colors.black` (Button styling)
6. **Line 535:** `Colors.black` (likely in a widget)
7. **Line 546:** `color: Colors.black` (likely in a widget)
8. **Line 656:** `fillColor: Colors.white.withValues(alpha: 0.05)` (InputDecoration fill)
9. **Line 659:** `borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))` (InputDecoration border)
10. **Line 663:** `borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))` (InputDecoration enabledBorder)
11. **Line 671:** `borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.5))` (InputDecoration errorBorder)
12. **Line 675:** `borderSide: BorderSide(color: Colors.red.withValues(alpha: 0.8))` (InputDecoration focusedErrorBorder)

**Total:** ~27 instances across both files

### D2: Hard-Coded Color Literals (Must Remove)

**Pattern:** `Color(0xFF...)` or `Color.fromARGB(...)`

**Instances Found:**
- None found in these files (all violations are `Colors.*` or `ChoiceLuxTheme.*` usage)

**Total:** 0 instances

### D3: Legacy ChoiceLuxTheme Constants (Must Remove)

**Pattern:** `ChoiceLuxTheme.{constantName}`

**Instances Found in login_screen.dart:**
1. **Line 172:** `TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16)` (InputDecoration style)
2. **Line 175:** `Icon(icon, color: ChoiceLuxTheme.platinumSilver)` (InputDecoration prefixIcon)
3. **Line 189:** `BorderSide(color: ChoiceLuxTheme.richGold, width: 2)` (InputDecoration focusedBorder)
4. **Line 200:** `color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.8)` (InputDecoration labelStyle)
5. **Line 240:** `decoration: const BoxDecoration(gradient: ChoiceLuxTheme.backgroundGradient)` (Scaffold background)
6. **Line 312:** `color: ChoiceLuxTheme.richGold` (likely in a widget)
7. **Line 317:** `color: ChoiceLuxTheme.richGold` (likely in a widget)
8. **Line 358:** `ChoiceLuxTheme.richGold` (likely in a widget)
9. **Line 420:** `ChoiceLuxTheme.platinumSilver` (likely in a widget)
10. **Line 461:** `color: ChoiceLuxTheme.errorColor` (error indicator)
11. **Line 467:** `color: ChoiceLuxTheme.errorColor` (error indicator)
12. **Line 488:** `ChoiceLuxTheme.errorColor` (error indicator)
13. **Line 750:** `ChoiceLuxTheme.richGold` (likely in a widget)
14. **Line 850-851:** `ChoiceLuxTheme.richGold` (conditional, likely in a widget)

**Instances Found in signup_screen.dart:**
1. **Line 90:** `decoration: const BoxDecoration(gradient: ChoiceLuxTheme.backgroundGradient)` (Scaffold background)
2. **Line 162:** `color: ChoiceLuxTheme.richGold` (likely in a widget)
3. **Line 167:** `color: ChoiceLuxTheme.richGold` (likely in a widget)
4. **Line 185:** `// color: ChoiceLuxTheme.richGold,` (commented out, but should be removed if cleaning)
5. **Line 211:** `ChoiceLuxTheme.richGold` (likely in a widget)
6. **Line 300:** `ChoiceLuxTheme.platinumSilver` (likely in a widget)
7. **Line 342:** `ChoiceLuxTheme.platinumSilver` (likely in a widget)
8. **Line 380:** `color: ChoiceLuxTheme.errorColor` (error indicator)
9. **Line 386:** `color: ChoiceLuxTheme.errorColor` (error indicator)
10. **Line 407:** `ChoiceLuxTheme.errorColor` (error indicator)
11. **Line 491:** `ChoiceLuxTheme.richGold` (likely in a widget)
12. **Line 600-601:** `ChoiceLuxTheme.richGold` (conditional, likely in a widget)
13. **Line 650:** `TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16)` (InputDecoration style)
14. **Line 653:** `Icon(icon, color: ChoiceLuxTheme.platinumSilver)` (InputDecoration prefixIcon)
15. **Line 667:** `BorderSide(color: ChoiceLuxTheme.richGold, width: 2)` (InputDecoration focusedBorder)
16. **Line 678:** `color: ChoiceLuxTheme.platinumSilver.withValues(alpha: 0.8)` (InputDecoration labelStyle)

**Total:** ~30 instances across both files

**Note:** `ChoiceLuxTheme.backgroundGradient` is a special case — see Implementation Notes (Section H).

### D4: Inline TextStyle Colors (Must Remove)

**Pattern:** `TextStyle(color: Colors.*)` or `TextStyle(color: ChoiceLuxTheme.*)`

**Instances Found:**
1. **login_screen.dart Line 172:** `style: const TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16)`
2. **signup_screen.dart Line 650:** `style: const TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16)`

**Total:** 2 instances

### D5: Manual InputDecoration Styling (Must Use Theme)

**Pattern:** `InputDecoration` with hard-coded colors in `fillColor`, `borderSide`, `labelStyle`, etc.

**Instances Found:**
- Both files have `_buildInputField` methods with extensive manual InputDecoration styling
- Uses `Colors.white.withValues(alpha: ...)` for fill and borders
- Uses `Colors.red.withValues(alpha: ...)` for error borders
- Uses `ChoiceLuxTheme.*` for focused borders, labels, icons

**Total:** 2 methods (one per file) with multiple color violations each

---

## E) What Tokens to Use Instead (ColorScheme/AppTokens/TextTheme)

### E1: InputDecoration Colors (Use ColorScheme and AppTokens)

**Replacements:**
- `Colors.white.withValues(alpha: 0.05)` (fill) → `context.colorScheme.surfaceVariant` (or `context.colorScheme.surface` with opacity if needed)
- `Colors.white.withValues(alpha: 0.2)` (border) → `context.colorScheme.outline` (or `context.colorScheme.outline.withValues(alpha: 0.2)` if opacity needed)
- `Colors.red.withValues(alpha: 0.5)` (error border) → `context.tokens.warningColor.withValues(alpha: 0.5)`
- `Colors.red.withValues(alpha: 0.8)` (focused error border) → `context.tokens.warningColor.withValues(alpha: 0.8)`
- `ChoiceLuxTheme.richGold` (focused border) → `context.colorScheme.primary` or `context.tokens.focusBorder`
- `ChoiceLuxTheme.platinumSilver` (label/icon) → `context.tokens.textBody`
- `ChoiceLuxTheme.softWhite` (text) → `context.tokens.textHeading` or `context.colorScheme.onSurface`

**Usage Pattern:**
```dart
// InputDecoration fill
fillColor: context.colorScheme.surfaceVariant

// InputDecoration border
border: OutlineInputBorder(
  borderSide: BorderSide(color: context.colorScheme.outline),
)

// InputDecoration focused border
focusedBorder: OutlineInputBorder(
  borderSide: BorderSide(
    color: context.tokens.focusBorder, // or context.colorScheme.primary
    width: 2,
  ),
)

// InputDecoration error border
errorBorder: OutlineInputBorder(
  borderSide: BorderSide(
    color: context.tokens.warningColor.withValues(alpha: 0.5),
  ),
)

// InputDecoration label style
labelStyle: context.textTheme.bodyMedium?.copyWith(
  color: context.tokens.textBody,
)

// InputDecoration prefix icon
prefixIcon: Icon(icon, color: context.tokens.textBody)
```

**Note:** Per THEME_SPEC.md Section 5, InputDecoration should use:
- Background: `surfaceVariant` token (`#27272a`)
- Border: `outline` token (`#27272a`)
- Focused border: `focusBorder` token (`#f59e0b`) with 2px width
- Error border: `warningColor` token (`#f43f5e`)
- Text: `textBody` token (`#a1a1aa`)
- Label: `textBody` token when unfocused, `primary` when focused

### E2: Text Colors (Use AppTokens or TextTheme)

**Replacements:**
- `ChoiceLuxTheme.softWhite` → `context.tokens.textHeading` (for headings) or `context.colorScheme.onSurface` (for body text)
- `Colors.black.withValues(alpha: ...)` → `context.colorScheme.background.withValues(alpha: ...)` or `context.colorScheme.surface.withValues(alpha: ...)`
- `Colors.white.withValues(alpha: ...)` → `context.tokens.textHeading.withValues(alpha: ...)` or `context.colorScheme.onSurface.withValues(alpha: ...)`

**Usage Pattern:**
```dart
// Text style in input field
style: context.textTheme.bodyLarge?.copyWith(
  color: context.tokens.textHeading, // or context.colorScheme.onSurface
)

// Text in containers with opacity
Text(
  'Text',
  style: TextStyle(
    color: context.colorScheme.onSurface.withValues(alpha: 0.8),
  ),
)
```

### E3: Button Colors (Use ColorScheme)

**Replacements:**
- `Colors.black` (foreground) → `context.colorScheme.onPrimary` (if on primary background) or `context.colorScheme.onSurface` (if on neutral background)
- `Colors.red` (background) → `context.tokens.warningColor` (for error states)

**Usage Pattern:**
```dart
// Button foreground
foregroundColor: context.colorScheme.onPrimary

// Error button background
backgroundColor: context.tokens.warningColor
```

### E4: Background Gradient (Special Case)

**Replacements:**
- `ChoiceLuxTheme.backgroundGradient` → Must check if this is defined in theme.dart
- If gradient is not in theme, may need to create using theme tokens:
  - Start: `context.colorScheme.background` (`#09090b`)
  - End: `context.colorScheme.surface` (`#18181b`) or similar

**Usage Pattern:**
```dart
// If gradient exists in theme
decoration: BoxDecoration(
  gradient: Theme.of(context).extension<AppTokens>()?.backgroundGradient,
)

// Or create from tokens
decoration: BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      context.colorScheme.background,
      context.colorScheme.surface,
    ],
  ),
)
```

**Note:** Per THEME_SPEC.md, background should be `#09090b` (background token). If gradient is required for visual effect, it should use theme tokens.

### E5: Error Indicator Colors (Use AppTokens)

**Replacements:**
- `ChoiceLuxTheme.errorColor` → `context.tokens.warningColor` (per THEME_SPEC.md, errors use warning token)
- `Colors.red` → `context.tokens.warningColor`

**Usage Pattern:**
```dart
// Error icon
Icon(Icons.error, color: context.tokens.warningColor)

// Error container background
color: context.tokens.warningColor.withValues(alpha: 0.2)
```

### E6: Grey Colors (Use ColorScheme or AppTokens)

**Replacements:**
- `Colors.grey` → `context.colorScheme.outline` (for borders) or `context.tokens.textSubtle` (for disabled text)

**Usage Pattern:**
```dart
// Disabled text/icon
color: context.tokens.textSubtle

// Border/divider
color: context.colorScheme.outline
```

---

## F) Acceptance Criteria

### F1: No Violations Remaining In-Scope

**Verification:**
- [ ] Zero instances of `Colors.*` (except `Colors.transparent` if any)
- [ ] Zero instances of `Color(0xFF...)` or `Color.fromARGB(...)`
- [ ] Zero instances of `ChoiceLuxTheme.*` constants
- [ ] Zero inline `TextStyle(color: Colors.*)` or `TextStyle(color: ChoiceLuxTheme.*)`

**Verification Command:**
```bash
# Check for Colors.* usage (should return 0 matches, or only Colors.transparent)
grep -n "Colors\." lib/features/auth/login/login_screen.dart | grep -v "Colors.transparent"
grep -n "Colors\." lib/features/auth/signup/signup_screen.dart | grep -v "Colors.transparent"

# Check for Color(0x...) literals (should return 0 matches)
grep -n "Color(0x" lib/features/auth/login/login_screen.dart
grep -n "Color(0x" lib/features/auth/signup/signup_screen.dart

# Check for ChoiceLuxTheme.* (should return 0 matches)
grep -n "ChoiceLuxTheme\." lib/features/auth/login/login_screen.dart
grep -n "ChoiceLuxTheme\." lib/features/auth/signup/signup_screen.dart
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
flutter analyze lib/features/auth/login/login_screen.dart lib/features/auth/signup/signup_screen.dart
```

### F3: No Layout Changes

**Verification:**
- [ ] Input field sizes unchanged (padding, border radius)
- [ ] Button sizes unchanged (width, height, padding)
- [ ] Text sizes unchanged (fontSize values remain the same)
- [ ] Border radius unchanged (12px for inputs, etc.)
- [ ] Container dimensions unchanged
- [ ] Spacing unchanged (padding, margins)

**Verification Method:**
- Visual comparison (screenshot before/after)
- Code review of spacing/sizing values
- No changes to layout-related properties (only color properties changed)

### F4: Visual Appearance Unchanged

**Verification:**
- [ ] Input fields appear with correct background and border colors
- [ ] Input fields show correct focus state (amber border)
- [ ] Input fields show correct error state (red border)
- [ ] Buttons appear with correct colors
- [ ] Error messages appear with correct colors
- [ ] Background gradient (if any) uses theme tokens

**Verification Method:**
- Manual visual inspection
- Screenshot comparison (if available)
- Side-by-side comparison with original

### F5: Interactive States Work

**Verification:**
- [ ] Input fields respond to focus (border changes to amber)
- [ ] Input fields show error state correctly (red border)
- [ ] Form validation works correctly
- [ ] Buttons respond to hover/active states
- [ ] Login flow works (email/password validation, submission)
- [ ] Signup flow works (all field validation, submission)
- [ ] Error messages display correctly
- [ ] Loading states work correctly

**Verification Method:**
- Manual testing of all form interactions
- Test validation states
- Test error states
- Test success states

---

## G) Manual Validation Checklist (Exact Screens/Flows)

### G1: Login Screen

**Screen:** `lib/features/auth/login/login_screen.dart`

**Test Flow 1: Login Form — Default State**
1. Navigate to login screen
2. Verify background uses theme tokens (background or gradient from tokens)
3. Verify email input field:
   - Background uses `context.colorScheme.surfaceVariant`
   - Border uses `context.colorScheme.outline`
   - Label text uses `context.tokens.textBody`
   - Input text uses `context.tokens.textHeading` or `context.colorScheme.onSurface`
   - Prefix icon uses `context.tokens.textBody`
4. Verify password input field (same as email)
5. Verify "Remember Me" checkbox uses theme colors
6. Verify "Login" button uses `context.colorScheme.primary` background and `context.colorScheme.onPrimary` text
7. Verify "Sign Up" link uses theme colors
8. Verify "Forgot Password" link uses theme colors

**Test Flow 2: Login Form — Focus State**
1. Navigate to login screen
2. Tap email input field
3. Verify focused border appears (amber - `context.tokens.focusBorder` or `context.colorScheme.primary`, 2px width)
4. Verify label color changes (if applicable, should use `context.colorScheme.primary`)
5. Tap password input field
6. Verify same focus behavior

**Test Flow 3: Login Form — Error State**
1. Navigate to login screen
2. Submit form with invalid credentials (or trigger validation error)
3. Verify error border appears (red - `context.tokens.warningColor.withValues(alpha: 0.5)`)
4. Verify focused error border appears (red - `context.tokens.warningColor.withValues(alpha: 0.8)`)
5. Verify error message displays (if any) with `context.tokens.warningColor` text
6. Verify error icon (if any) uses `context.tokens.warningColor`
7. Start typing in field
8. Verify error state clears correctly

**Test Flow 4: Login Form — Success State**
1. Navigate to login screen
2. Enter valid credentials
3. Click "Login" button
4. Verify loading state (if any) uses theme colors
5. Verify success navigation (redirects to dashboard)
6. Verify no color-related errors in console

**Test Flow 5: Login Form — Disabled State**
1. Navigate to login screen
2. Trigger loading state (submit form)
3. Verify input fields are disabled (if applicable)
4. Verify disabled state uses `context.tokens.textSubtle` for text/icons
5. Verify button is disabled (if applicable)
6. Verify disabled button uses appropriate theme colors

### G2: Signup Screen

**Screen:** `lib/features/auth/signup/signup_screen.dart`

**Test Flow 1: Signup Form — Default State**
1. Navigate to signup screen
2. Verify background uses theme tokens (background or gradient from tokens)
3. Verify all input fields (email, password, confirm password, display name):
   - Background uses `context.colorScheme.surfaceVariant`
   - Border uses `context.colorScheme.outline`
   - Label text uses `context.tokens.textBody`
   - Input text uses `context.tokens.textHeading` or `context.colorScheme.onSurface`
   - Prefix icon uses `context.tokens.textBody`
4. Verify "Sign Up" button uses `context.colorScheme.primary` background and `context.colorScheme.onPrimary` text
5. Verify "Sign In" link uses theme colors

**Test Flow 2: Signup Form — Focus State**
1. Navigate to signup screen
2. Tap each input field in sequence
3. Verify focused border appears (amber - `context.tokens.focusBorder` or `context.colorScheme.primary`, 2px width)
4. Verify label color changes (if applicable)

**Test Flow 3: Signup Form — Error State**
1. Navigate to signup screen
2. Submit form with invalid data (or trigger validation error)
3. Verify error borders appear on invalid fields (red - `context.tokens.warningColor.withValues(alpha: 0.5)`)
4. Verify focused error borders appear (red - `context.tokens.warningColor.withValues(alpha: 0.8)`)
5. Verify error messages display with `context.tokens.warningColor` text
6. Verify error icons use `context.tokens.warningColor`
7. Start typing in field
8. Verify error state clears correctly

**Test Flow 4: Signup Form — Success State**
1. Navigate to signup screen
2. Enter valid data for all fields
3. Click "Sign Up" button
4. Verify loading state (if any) uses theme colors
5. Verify success navigation or message
6. Verify no color-related errors in console

**Test Flow 5: Signup Form — Password Validation**
1. Navigate to signup screen
2. Enter password in password field
3. Verify password strength indicator (if any) uses theme colors
4. Enter mismatched password in confirm password field
5. Verify error state appears with theme colors
6. Enter matching password
7. Verify error state clears

### G3: Visual Regression Testing

**Screenshots Required:**
1. **Before Migration:** Capture screenshots of:
   - Login screen (default state)
   - Login screen (focused input)
   - Login screen (error state)
   - Signup screen (default state)
   - Signup screen (focused input)
   - Signup screen (error state)

2. **After Migration:** Capture same screenshots
   - Compare side-by-side
   - Verify colors match theme tokens (may be slightly different if tokens differ from hard-coded values)
   - Verify layout is identical

**Comparison Points:**
- Input field colors (background, border, text, icons)
- Button colors (background, text)
- Error message colors (border, text, icons)
- Background gradient/color
- Link colors
- Loading state colors

### G4: Accessibility Verification

**Contrast Ratios:**
- [ ] Input field text: Text color (`context.tokens.textHeading` or `context.colorScheme.onSurface`) on input background (`context.colorScheme.surfaceVariant`) meets WCAG AA (4.5:1)
- [ ] Input field label: Label color (`context.tokens.textBody`) on input background meets WCAG AA (4.5:1)
- [ ] Button text: Button text (`context.colorScheme.onPrimary`) on button background (`context.colorScheme.primary`) meets WCAG AA (4.5:1)
- [ ] Error text: Error text (`context.tokens.warningColor`) on error container background meets WCAG AA (4.5:1)
- [ ] Link text: Link text on background meets WCAG AA (4.5:1)

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
- `package:choice_lux_cars/app/theme.dart` ✅ (for ChoiceLuxTheme - will be removed)

**Required Addition:**
- `package:choice_lux_cars/app/theme_helpers.dart` (for `context.tokens` and `context.colorScheme` extensions)

**Required Removal:**
- `package:choice_lux_cars/app/theme.dart` (if only used for ChoiceLuxTheme constants)

**Or Keep Import:**
- Keep `package:choice_lux_cars/app/theme.dart` if used for other purposes (check usage)

### H2: Token Access Pattern

**Preferred Pattern:**
```dart
// Use extension methods (if theme_helpers.dart is imported)
context.tokens.textHeading
context.tokens.textBody
context.tokens.warningColor
context.colorScheme.primary
context.colorScheme.onPrimary
context.colorScheme.surfaceVariant
context.colorScheme.outline
context.tokens.focusBorder
```

**Fallback Pattern:**
```dart
// Use Theme.of(context) directly
Theme.of(context).extension<AppTokens>()!.textHeading
Theme.of(context).colorScheme.primary
```

### H3: InputDecoration Theme Compliance

**Current Issue:** InputDecoration uses hard-coded colors for fill, borders, labels, icons.

**Required Fix:**
- Replace `fillColor: Colors.white.withValues(alpha: 0.05)` with `context.colorScheme.surfaceVariant`
- Replace `borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))` with `context.colorScheme.outline`
- Replace `focusedBorder` with `context.tokens.focusBorder` or `context.colorScheme.primary` (2px width)
- Replace `errorBorder` with `context.tokens.warningColor.withValues(alpha: 0.5)`
- Replace `focusedErrorBorder` with `context.tokens.warningColor.withValues(alpha: 0.8)`
- Replace `labelStyle` with `context.textTheme.bodyMedium?.copyWith(color: context.tokens.textBody)`
- Replace prefix icon color with `context.tokens.textBody`
- Replace input text style with `context.textTheme.bodyLarge?.copyWith(color: context.tokens.textHeading)`

**Note:** Per THEME_SPEC.md Section 5, InputDecoration should use InputDecorationTheme from theme. However, if custom styling is required, use theme tokens.

### H4: Background Gradient Handling

**Current Issue:** Uses `ChoiceLuxTheme.backgroundGradient` which may not exist in theme tokens.

**Required Fix:**
1. Check if `backgroundGradient` exists in `lib/app/theme.dart` or `lib/app/theme_tokens.dart`
2. If exists, use it via theme extension
3. If not exists, create gradient using theme tokens:
   ```dart
   LinearGradient(
     begin: Alignment.topLeft,
     end: Alignment.bottomRight,
     colors: [
       context.colorScheme.background, // #09090b
       context.colorScheme.surface,    // #18181b
     ],
   )
   ```

**Decision:** If gradient is required for visual effect, create from theme tokens. If not required, use solid `context.colorScheme.background`.

### H5: Error Message Display

**Current Issue:** Error messages may use `ChoiceLuxTheme.errorColor` or `Colors.red`.

**Required Fix:**
- Replace `ChoiceLuxTheme.errorColor` with `context.tokens.warningColor`
- Replace `Colors.red` with `context.tokens.warningColor`
- Error container background: `context.tokens.warningColor.withValues(alpha: 0.2)`
- Error icon/text: `context.tokens.warningColor`

### H6: Button Styling

**Current Issue:** Buttons may use `Colors.black` for foreground or `Colors.red` for error states.

**Required Fix:**
- Replace `foregroundColor: Colors.black` with `context.colorScheme.onPrimary` (if on primary background) or `context.colorScheme.onSurface` (if on neutral background)
- Replace `backgroundColor: Colors.red` with `context.tokens.warningColor` (for error buttons)

**Note:** Buttons should use theme defaults where possible. Only override if custom styling is required.

### H7: Container/Decoration Colors

**Current Issue:** Containers may use `Colors.black.withValues(alpha: ...)` or `Colors.white.withValues(alpha: ...)` for overlays/backdrops.

**Required Fix:**
- Replace `Colors.black.withValues(alpha: ...)` with `context.colorScheme.background.withValues(alpha: ...)` or `context.colorScheme.surface.withValues(alpha: ...)`
- Replace `Colors.white.withValues(alpha: ...)` with `context.tokens.textHeading.withValues(alpha: ...)` or `context.colorScheme.onSurface.withValues(alpha: ...)`

**Decision:** Choose appropriate token based on semantic meaning:
- Background overlay → `context.colorScheme.background` or `context.colorScheme.surface`
- Text overlay → `context.tokens.textHeading` or `context.colorScheme.onSurface`

---

## I) Risk Mitigation

### I1: InputDecoration Theme Override

**Risk:** Replacing InputDecoration colors may cause it to use theme defaults, changing appearance.

**Mitigation:**
- Keep custom InputDecoration but use theme tokens
- Verify InputDecoration appearance matches original
- Test all states (enabled, focused, error, disabled)

### I2: Background Gradient

**Risk:** `ChoiceLuxTheme.backgroundGradient` may not exist in theme tokens, requiring gradient creation.

**Mitigation:**
- Check theme.dart for gradient definition
- If not exists, create from theme tokens
- Verify gradient appearance matches original
- Test gradient on different screen sizes

### I3: Form Validation States

**Risk:** Changing error border colors may affect form validation visibility.

**Mitigation:**
- Test all validation states
- Verify error messages are clearly visible
- Test error state clearing on input

### I4: Text Contrast

**Risk:** Replacing `ChoiceLuxTheme.softWhite` with `context.tokens.textHeading` may change text color if tokens differ.

**Mitigation:**
- Verify `textHeading` token is `#fafafa` per THEME_SPEC.md
- Test text readability on all backgrounds
- Verify contrast ratios meet WCAG AA

### I5: Button State Colors

**Risk:** Replacing `Colors.black` with `context.colorScheme.onPrimary` may change button text color if onPrimary differs.

**Mitigation:**
- Verify `onPrimary` token is `#09090b` per THEME_SPEC.md
- Test button text readability
- Verify contrast ratios meet WCAG AA

---

## J) Rollback Plan

**If Issues Arise:**
1. Revert changes to `lib/features/auth/login/login_screen.dart`
2. Revert changes to `lib/features/auth/signup/signup_screen.dart`
3. Restore original hard-coded colors
4. Document issues encountered
5. Request ARCH review before retry

**Git Commands:**
```bash
# Revert files to previous commit
git checkout HEAD -- lib/features/auth/login/login_screen.dart
git checkout HEAD -- lib/features/auth/signup/signup_screen.dart

# Or restore from backup
git restore lib/features/auth/login/login_screen.dart
git restore lib/features/auth/signup/signup_screen.dart
```

---

**Status:** PLAN READY  
**Next Step:** CLC-BUILD implements Batch 2 following this plan  
**Approval Required:** Yes — Before implementation begins

