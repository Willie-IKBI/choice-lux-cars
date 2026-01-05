# Auth Screens Baseline Report
## Pre-Migration Styling Audit

**Date:** 2025-01-XX  
**Scope:** Authentication screens only (Login, Signup, Reset Password, Forgot Password, Pending Approval)  
**Purpose:** Document current styling patterns, hardcoded debt, and risks before Obsidian theme migration

---

## 1. AUTH SCREEN INVENTORY

| Screen | File Path | Route | Purpose |
|--------|-----------|-------|---------|
| **Login** | `lib/features/auth/login/login_screen.dart` | `/login` | User authentication |
| **Signup** | `lib/features/auth/signup/signup_screen.dart` | `/signup` | New user registration |
| **Forgot Password** | `lib/features/auth/forgot_password/forgot_password_screen.dart` | `/forgot-password` | Password recovery initiation |
| **Reset Password** | `lib/features/auth/reset_password/reset_password_screen.dart` | `/reset-password` | Password reset after email link |
| **Pending Approval** | `lib/features/auth/pending_approval_screen.dart` | `/pending-approval` | Account pending admin approval |

**Total:** 5 auth screens

---

## 2. CURRENT STYLING PATTERNS

### 2.1 Login Screen (`login_screen.dart`)

**Theme References:**
- ✅ `ChoiceLuxTheme.backgroundGradient` (background)
- ✅ `ChoiceLuxTheme.richGold` (buttons, logo border, title text, focus borders)
- ✅ `ChoiceLuxTheme.platinumSilver` (icons, labels, subtitle text)
- ✅ `ChoiceLuxTheme.softWhite` (input text, title)
- ✅ `ChoiceLuxTheme.errorColor` (error containers)
- ✅ `GoogleFonts.outfit()` (title: "Choice Lux Cars")
- ✅ `GoogleFonts.inter()` (subtitle: "SIGN IN TO YOUR ACCOUNT")

**Hardcoded Colors:**
- ❌ `Colors.black.withOpacity(0.4)` - BackdropFilter container background (line 264)
- ❌ `Colors.white.withOpacity(0.2)` - BackdropFilter border (line 267)
- ❌ `Colors.black.withOpacity(0.3)` - BackdropFilter shadow (line 272)
- ❌ `Colors.black.withOpacity(0.7)` - Logo container background (line 313)
- ❌ `Colors.white.withOpacity(0.05)` - Input field fillColor (line 183)
- ❌ `Colors.white.withOpacity(0.2)` - Input field borders (lines 186, 190)
- ❌ `Colors.red.withOpacity(0.5)` - Input error border (line 198)
- ❌ `Colors.red.withOpacity(0.8)` - Input focused error border (line 202)
- ❌ `Colors.grey.withOpacity(0.3)` - Switch inactive track (line 580)
- ❌ `Colors.black` - Button text, loading spinner (lines 756, 784, 800)
- ❌ `Colors.red` - Error snackbar background (line 896)

**Typography:**
- ✅ Uses `GoogleFonts.outfit()` for title (line 359)
- ✅ Uses `GoogleFonts.inter()` for subtitle (line 370)
- ❌ Hardcoded `fontSize: 16` for input text (line 177)
- ❌ Hardcoded `fontSize: 24/28` for title (responsive, line 348-350)
- ❌ Hardcoded `fontSize: 10/12` for subtitle (responsive, line 351-353)
- ❌ Hardcoded `fontSize: 14` for labels/text (multiple lines)

**Effects:**
- ✅ `BackdropFilter` with `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` (line 260-261)
- ✅ `BackgroundPatterns.signin` (line 250)
- ✅ BoxShadow on BackdropFilter container (line 270-275)
- ✅ Logo hover glow effect (gold shadow, line 321-331)
- ✅ Button scale animation (line 741-817)
- ✅ Shake animation for errors (line 138-155)

**Buttons:**
- ✅ `ElevatedButton` with `ChoiceLuxTheme.richGold` background (line 749)
- ✅ `TextButton` for links (Forgot Password, Sign Up)
- ✅ Custom scale animation on primary button

**Layout:**
- ✅ Responsive padding (24px mobile, 40px desktop)
- ✅ Max-width constraint (400px)
- ✅ Responsive font sizes (mobile vs desktop)

---

### 2.2 Signup Screen (`signup_screen.dart`)

**Theme References:**
- ✅ `ChoiceLuxTheme.backgroundGradient` (background)
- ✅ `ChoiceLuxTheme.richGold` (buttons, logo border, title text, focus borders)
- ✅ `ChoiceLuxTheme.platinumSilver` (icons, labels, subtitle text)
- ✅ `ChoiceLuxTheme.softWhite` (input text, title)
- ✅ `ChoiceLuxTheme.errorColor` (error containers)
- ✅ `GoogleFonts.outfit()` (title: "Choice Lux Cars")
- ✅ `GoogleFonts.inter()` (subtitle: "CREATE YOUR ACCOUNT")

**Hardcoded Colors:**
- ❌ `Colors.black.withOpacity(0.4)` - BackdropFilter container background (line 108)
- ❌ `Colors.white.withOpacity(0.2)` - BackdropFilter border (line 111)
- ❌ `Colors.black.withOpacity(0.3)` - BackdropFilter shadow (line 116)
- ❌ `Colors.black.withOpacity(0.7)` - Logo container background (line 157)
- ❌ `Colors.white.withOpacity(0.05)` - Input field fillColor (line 655)
- ❌ `Colors.white.withOpacity(0.2)` - Input field borders (lines 658, 662)
- ❌ `Colors.red.withOpacity(0.5)` - Input error border (line 670)
- ❌ `Colors.red.withOpacity(0.8)` - Input focused error border (line 674)
- ❌ `Colors.grey.withOpacity(0.3)` - Switch inactive track (not present, but pattern exists)
- ❌ `Colors.black` - Button text, loading spinner (lines 491, 519, 545)

**Typography:**
- ✅ Uses `GoogleFonts.outfit()` for title (line 206)
- ✅ Uses `GoogleFonts.inter()` for subtitle (line 217)
- ❌ Hardcoded `fontSize: 16` for input text (line 649)
- ❌ Hardcoded `fontSize: 24/28` for title (responsive, line 195-197)
- ❌ Hardcoded `fontSize: 10/12` for subtitle (responsive, line 198-200)
- ❌ Hardcoded `fontSize: 14` for labels/text (multiple lines)

**Effects:**
- ✅ `BackdropFilter` with `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` (line 104-105)
- ✅ `BackgroundPatterns.signin` (line 94)
- ✅ BoxShadow on BackdropFilter container (line 114-120)
- ✅ Logo hover glow effect (gold shadow, line 164-176)
- ✅ Button scale animation (line 476-552)

**Buttons:**
- ✅ `ElevatedButton` with `ChoiceLuxTheme.richGold` background (line 484)
- ✅ `TextButton` for links (Sign In)
- ✅ Custom scale animation on primary button

**Layout:**
- ✅ Responsive padding (24px mobile, 40px desktop)
- ✅ Max-width constraint (400px)
- ✅ Responsive font sizes (mobile vs desktop)

**Note:** Very similar to Login screen (duplicated input field styling)

---

### 2.3 Forgot Password Screen (`forgot_password_screen.dart`)

**Theme References:**
- ✅ `ChoiceLuxTheme.backgroundGradient` (background)
- ✅ `ChoiceLuxTheme.richGold` (buttons, focus borders, email highlight)
- ✅ `ChoiceLuxTheme.platinumSilver` (icons, labels, text)
- ✅ `ChoiceLuxTheme.softWhite` (title, text)
- ✅ `ChoiceLuxTheme.errorColor` (error snackbar)
- ✅ `ChoiceLuxTheme.successColor` (success icon, container)
- ✅ `ChoiceLuxTheme.charcoalGray` (input fillColor)
- ❌ No GoogleFonts usage (uses default TextStyle)

**Hardcoded Colors:**
- ❌ `Colors.black.withOpacity(0.4)` - BackdropFilter container background (lines 149, 329)
- ❌ `Colors.white.withOpacity(0.2)` - BackdropFilter border (lines 152, 332)
- ❌ `Colors.black.withOpacity(0.3)` - BackdropFilter shadow (lines 157, 337)

**Typography:**
- ❌ No GoogleFonts (uses default `TextStyle`)
- ❌ Hardcoded `fontSize: 28` for title (line 193)
- ❌ Hardcoded `fontSize: 16` for body text (lines 205, 382)
- ❌ Hardcoded `fontSize: 14` for labels (line 309)

**Effects:**
- ✅ `BackdropFilter` with `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` (lines 145-146, 325-326)
- ✅ `BackgroundPatterns.signin` (line 98)
- ✅ BoxShadow on BackdropFilter containers (lines 155-161, 335-341)
- ✅ Fade/slide animations (lines 117-130)

**Buttons:**
- ✅ `ElevatedButton` with `ChoiceLuxTheme.richGold` background (line 268, 461)
- ✅ `OutlinedButton` for secondary actions (line 439)
- ✅ `TextButton` for links (line 303)

**Layout:**
- ✅ Responsive padding (24px mobile, 64px tablet, 120px desktop)
- ✅ Max-width constraint (400px, full-width on mobile)
- ✅ Two states: Reset form + Success view

---

### 2.4 Reset Password Screen (`reset_password_screen.dart`)

**Theme References:**
- ✅ `ChoiceLuxTheme.backgroundGradient` (background)
- ✅ `ChoiceLuxTheme.richGold` (buttons, focus borders, prefix icons)
- ✅ `ChoiceLuxTheme.platinumSilver` (icons, labels, text)
- ✅ `ChoiceLuxTheme.softWhite` (title, input text)
- ✅ `ChoiceLuxTheme.errorColor` (error snackbar, borders)
- ✅ `ChoiceLuxTheme.successColor` (success snackbar)
- ✅ `ChoiceLuxTheme.charcoalGray` (input fillColor)
- ❌ No GoogleFonts usage (uses default TextStyle)

**Hardcoded Colors:**
- ❌ `Colors.black.withOpacity(0.4)` - BackdropFilter container background (line 187)
- ❌ `Colors.white.withOpacity(0.2)` - BackdropFilter border (line 190)
- ❌ `Colors.black.withOpacity(0.3)` - BackdropFilter shadow (line 195)
- ❌ `Colors.black` - Button text, loading spinner (lines 385, 404)

**Typography:**
- ❌ No GoogleFonts (uses default `TextStyle`)
- ❌ Hardcoded `fontSize: 28` for title (line 212)
- ❌ Hardcoded `fontSize: 16` for body text (lines 224, 310)
- ❌ Hardcoded `fontSize: 14` for labels (lines 425)

**Effects:**
- ✅ `BackdropFilter` with `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` (line 183-184)
- ✅ `BackgroundPatterns.signin` (line 158)
- ✅ BoxShadow on BackdropFilter container (lines 193-199)

**Buttons:**
- ✅ `ElevatedButton` with `ChoiceLuxTheme.richGold` background (line 381)
- ✅ `TextButton` for links (line 420)

**Layout:**
- ✅ Responsive padding (24px mobile, 64px tablet, 120px desktop)
- ✅ Max-width constraint (400px, full-width on mobile)

---

### 2.5 Pending Approval Screen (`pending_approval_screen.dart`)

**Theme References:**
- ✅ `ChoiceLuxTheme.jetBlack` (gradient)
- ✅ `ChoiceLuxTheme.charcoalGray` (gradient, info box)
- ✅ `ChoiceLuxTheme.richGold` (icon, borders, text highlights)
- ✅ `ChoiceLuxTheme.softWhite` (title, text)
- ✅ `Theme.of(context).textTheme` (headlineMedium, titleLarge, bodyLarge, bodyMedium)
- ❌ No GoogleFonts usage (uses Theme textTheme)
- ❌ No BackdropFilter (different pattern from other auth screens)

**Hardcoded Colors:**
- ❌ `Colors.black.withOpacity(0.3)` - Card shadow (line 35)
- ❌ `Colors.red.withOpacity(0.8)` - Sign out button background (line 157)
- ❌ `Colors.white` - Sign out button text (line 158)

**Typography:**
- ✅ Uses `Theme.of(context).textTheme` (good pattern)
- ❌ No GoogleFonts (relies on theme default)

**Effects:**
- ❌ No BackdropFilter (uses standard Card widget)
- ✅ BoxShadow on Card (line 35)
- ✅ Gradient background (custom LinearGradient, lines 18-26)

**Buttons:**
- ✅ `FilledButton.icon` for sign out (line 150)
- ❌ Hardcoded `Colors.red.withOpacity(0.8)` background (line 157)

**Layout:**
- ✅ Standard padding (24px, 32px)
- ✅ Max-width constraint (500px)
- ✅ Uses `SystemSafeScaffold` (shared widget)

**Note:** Different styling pattern - uses Card instead of BackdropFilter glassmorphism

---

## 3. SHARED WIDGETS & UTILITIES

### 3.1 BackgroundPatterns (`lib/shared/utils/background_pattern_utils.dart`)

**Usage in Auth Screens:**
- Login: `BackgroundPatterns.signin` (line 250)
- Signup: `BackgroundPatterns.signin` (line 94)
- Forgot Password: `BackgroundPatterns.signin` (line 98)
- Reset Password: `BackgroundPatterns.signin` (line 158)

**Usage Elsewhere:**
- ⚠️ **Used by 24+ other screens** (dashboard, clients, jobs, quotes, etc.)
- Pattern: `BackgroundPatterns.signin` (auth) and `BackgroundPatterns.dashboard` (main app)

**Risk Assessment:**
- ✅ **VERIFIED: LOW RISK** - `BackgroundPatterns.signin` is ONLY used by 4 auth screens (Login, Signup, Forgot Password, Reset Password)
- ✅ **SAFE** - Auth screens use `.signin` variant (separate from `.dashboard` used by main app)
- ✅ **CONFIRMED:** Changing `.signin` pattern will NOT affect any other screens (grep verified)

**Current Implementation:**
```dart
static const signin = BackgroundPatternPainter(
  opacity: 0.03,
  strokeWidth: 1.0,
  gridSpacing: 50.0,
);
```
- Uses `ChoiceLuxTheme.richGold.withOpacity(0.03)` for grid lines
- Subtle grid pattern (50px spacing)

---

### 3.2 SystemSafeScaffold (`lib/shared/widgets/system_safe_scaffold.dart`)

**Usage in Auth Screens:**
- Pending Approval: Uses `SystemSafeScaffold` (line 15)
- Other auth screens: Use standard `Scaffold`

**Usage Elsewhere:**
- ✅ Used extensively across app (all main screens)
- Safe to modify (auth-only usage is minimal)

**Risk Assessment:**
- ✅ **LOW RISK** - Only Pending Approval uses it in auth
- ✅ Other auth screens use standard Scaffold
- ✅ Safe to adjust SystemSafeScaffold (used by many screens, but auth impact is minimal)

---

### 3.3 Input Field Pattern

**Current State:**
- ❌ **Not a shared widget** - Input fields duplicated across Login/Signup screens
- Login: `_buildInputField()` method (lines 157-213)
- Signup: `_buildInputField()` method (lines 635-685)
- Forgot Password: Inline `TextFormField` (lines 213-264)
- Reset Password: Inline `TextFormField` (lines 233-302, 306-377)

**Styling Pattern (Login/Signup):**
```dart
TextFormField(
  style: TextStyle(color: ChoiceLuxTheme.softWhite, fontSize: 16),
  decoration: InputDecoration(
    filled: true,
    fillColor: Colors.white.withOpacity(0.05), // Hardcoded
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)), // Hardcoded
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: ChoiceLuxTheme.richGold, width: 2), // Theme
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red.withOpacity(0.5)), // Hardcoded
    ),
  ),
)
```

**Risk Assessment:**
- ✅ **LOW RISK** - Input fields are screen-local (not shared)
- ✅ Can migrate independently per screen
- ⚠️ **OPPORTUNITY:** Could create shared input widget for consistency (future refactor)

---

## 4. HARDCODED STYLE DEBT

### 4.1 Hardcoded Colors Summary

| Color Pattern | Count | Files | Lines | Migration Target |
|---------------|-------|-------|-------|------------------|
| `Colors.black.withOpacity(0.4)` | 4 | Login, Signup, Forgot, Reset | BackdropFilter container | Theme: `obsidianSurface` with opacity |
| `Colors.white.withOpacity(0.2)` | 4 | Login, Signup, Forgot, Reset | BackdropFilter border | Theme: `obsidianBorder` |
| `Colors.black.withOpacity(0.3)` | 4 | Login, Signup, Forgot, Reset | BackdropFilter shadow | Theme shadow color |
| `Colors.white.withOpacity(0.05)` | 2 | Login, Signup | Input fillColor | Theme: white 5% opacity (may stay) |
| `Colors.white.withOpacity(0.2)` | 2 | Login, Signup | Input borders | Theme: `obsidianBorder` |
| `Colors.red.withOpacity(0.5/0.8)` | 4 | Login, Signup | Input error borders | Theme: `errorColor` with opacity |
| `Colors.black` | 6 | Login, Signup, Reset | Button text, spinners | Theme: `obsidianTextHeading` or black (ok for gold buttons) |
| `Colors.red` | 3 | Login, Pending | Error snackbars, button | Theme: `errorColor` |
| `Colors.white` | 1 | Pending | Button text | Theme: `obsidianTextHeading` |
| `Colors.grey.withOpacity(0.3)` | 1 | Login | Switch inactive | Theme: muted color |

**Total Hardcoded Color Instances:** ~30 instances across 5 screens

---

### 4.2 Hardcoded Typography

| Pattern | Count | Files | Migration Target |
|---------|-------|-------|------------------|
| `fontSize: 16` (input text) | 4 | Login, Signup, Forgot, Reset | Theme: bodyMedium (14px) or custom |
| `fontSize: 28` (title) | 3 | Forgot, Reset, Pending | Theme: headlineMedium (24px) or custom |
| `fontSize: 24/28` (responsive title) | 2 | Login, Signup | Theme: headlineMedium with responsive scaling |
| `fontSize: 14` (labels/links) | 6 | All screens | Theme: bodySmall (12px) or bodyMedium (14px) |
| `fontSize: 10/12` (subtitle) | 2 | Login, Signup | Theme: bodySmall with responsive scaling |
| No GoogleFonts (Forgot, Reset, Pending) | 3 | Forgot, Reset, Pending | Add GoogleFonts.outfit/inter |

**Total Hardcoded Font Size Instances:** ~20 instances

**GoogleFonts Usage:**
- ✅ Login: Uses `GoogleFonts.outfit()` and `GoogleFonts.inter()`
- ✅ Signup: Uses `GoogleFonts.outfit()` and `GoogleFonts.inter()`
- ❌ Forgot Password: No GoogleFonts (default TextStyle)
- ❌ Reset Password: No GoogleFonts (default TextStyle)
- ❌ Pending Approval: No GoogleFonts (uses Theme.textTheme)

---

### 4.3 Hardcoded Effects

| Effect | Count | Files | Migration Target |
|--------|-------|-------|------------------|
| `BackdropFilter` blur (sigmaX: 10, sigmaY: 10) | 5 | Login, Signup, Forgot (2x), Reset | ✅ Acceptable (auth only per spec) |
| `BoxShadow` values | 5 | All screens | Theme shadow tokens |
| Border radius: `BorderRadius.circular(12/20)` | 10+ | All screens | Theme: `radiusMd` (12px) or responsive tokens |
| Border radius: `BorderRadius.circular(8)` | 3 | Forgot, Reset | Theme: smaller radius token |

**Note:** BackdropFilter usage is acceptable per design system spec (auth screens only)

---

## 5. RISKS & IMPACT ANALYSIS

### 5.1 High Risk (Could Affect Non-Auth UI)

| Component | Risk Level | Impact | Mitigation |
|-----------|------------|--------|------------|
| `BackgroundPatterns.signin` | ✅ **VERIFIED: LOW** | Only used by 4 auth screens | Safe to modify (grep verified - no other screens use `.signin`) |
| `ChoiceLuxTheme` color constants | 🟡 **MEDIUM** | All screens use these | Update theme constants (affects all, but intentional) |
| `SystemSafeScaffold` | 🟢 **LOW** | Only Pending Approval uses in auth | Safe (other screens also use, but auth impact minimal) |

**BackgroundPatterns.signin Verification Needed:**
- Check if other screens use `BackgroundPatterns.signin` (not just `.dashboard`)
- If only auth screens use `.signin`, safe to modify
- If other screens use `.signin`, need new variant or coordinate changes

---

### 5.2 Low Risk (Auth-Only)

| Component | Risk Level | Notes |
|-----------|------------|-------|
| Input field methods (`_buildInputField`) | 🟢 **LOW** | Screen-local, not shared |
| Button styling (inline ElevatedButton) | 🟢 **LOW** | Screen-local, not shared |
| BackdropFilter containers | 🟢 **LOW** | Auth-only (acceptable per spec) |
| Logo styling | 🟢 **LOW** | Auth screens only |
| Animations (shake, scale, fade) | 🟢 **LOW** | Screen-local |

---

### 5.3 Safe to Modify (No External Impact)

**Auth-Specific Patterns:**
- ✅ BackdropFilter glassmorphism (auth-only, per spec)
- ✅ Input field styling (duplicated, screen-local)
- ✅ Button styling (inline, screen-local)
- ✅ Logo hover effects (auth-only)
- ✅ Error display patterns (screen-local)
- ✅ Form layouts (screen-local)

**Shared but Safe:**
- ✅ `ChoiceLuxTheme` constants (updating theme is intentional migration)
- ✅ `BackgroundPatterns.signin` (if verified auth-only usage)

---

## 6. STYLING CONSISTENCY ISSUES

### 6.1 Inconsistencies Across Auth Screens

| Issue | Screens Affected | Impact |
|-------|------------------|--------|
| **No GoogleFonts** | Forgot, Reset, Pending | Typography inconsistent (Login/Signup use Outfit/Inter) |
| **No BackdropFilter** | Pending Approval | Visual inconsistency (others use glassmorphism) |
| **Different input styling** | Forgot, Reset | Input fields styled inline (Login/Signup use methods) |
| **Different button patterns** | Pending | Uses FilledButton (others use ElevatedButton) |
| **Hardcoded font sizes** | All screens | Should use TextTheme or responsive tokens |
| **Hardcoded colors** | All screens | Should use theme colors |

---

### 6.2 Duplication

| Pattern | Duplication | Files |
|---------|-------------|-------|
| Input field styling | 2x methods + 2x inline | Login, Signup, Forgot, Reset |
| BackdropFilter container | 4x similar code | Login, Signup, Forgot (2x), Reset |
| Button styling | 5x similar ElevatedButton | All screens |
| Error display | 2x similar patterns | Login, Signup |

**Migration Opportunity:** Could create shared auth components (but out of scope for this migration)

---

## 7. MIGRATION READINESS

### 7.1 Ready for Migration

✅ **Theme References:**
- All screens use `ChoiceLuxTheme` constants (good foundation)
- Login/Signup use GoogleFonts (good pattern to extend)

✅ **Isolated Styling:**
- Most styling is screen-local (low risk)
- BackdropFilter acceptable (auth-only per spec)

✅ **Clear Patterns:**
- Consistent use of gold for primary actions
- Consistent glassmorphism pattern (Login, Signup, Forgot, Reset)

---

### 7.2 Migration Challenges

⚠️ **Hardcoded Colors:**
- 30+ instances of `Colors.white/black/red.withOpacity()`
- Need systematic replacement with theme colors

⚠️ **Typography Inconsistency:**
- Forgot/Reset/Pending don't use GoogleFonts
- Hardcoded font sizes (20+ instances)
- Need to add GoogleFonts and use TextTheme

⚠️ **Pending Approval Difference:**
- Uses Card instead of BackdropFilter
- Uses FilledButton instead of ElevatedButton
- Uses Theme.textTheme (good) but no GoogleFonts
- Needs decision: Make consistent or keep different?

---

## 8. SUMMARY & RECOMMENDATIONS

### 8.1 Key Findings

1. **5 auth screens** with similar but not identical patterns
2. **30+ hardcoded color instances** (Colors.white/black/red.withOpacity)
3. **20+ hardcoded font sizes** (should use TextTheme)
4. **BackdropFilter used correctly** (auth-only, acceptable per spec)
5. **BackgroundPatterns.signin** - Verify usage (could be shared risk)
6. **Typography inconsistency** - 2 screens use GoogleFonts, 3 don't
7. **Pending Approval different** - Uses Card, not BackdropFilter

### 8.2 Migration Priorities

**High Priority:**
1. Replace hardcoded colors with theme colors
2. Add GoogleFonts to Forgot/Reset/Pending screens
3. Use TextTheme/responsive tokens for font sizes
4. ✅ BackgroundPatterns.signin verified auth-only (safe to modify)

**Medium Priority:**
1. Decide on Pending Approval pattern (BackdropFilter or keep Card?)
2. Standardize button styling (all use ElevatedButton or allow FilledButton?)
3. Consider input field consistency (but screen-local is OK)

**Low Priority:**
1. Create shared auth components (future refactor, not migration scope)

### 8.3 Risk Mitigation

**Before Migration:**
- ✅ **VERIFIED:** `BackgroundPatterns.signin` is auth-only (4 screens only, grep confirmed)
- ✅ Decide on Pending Approval pattern (make consistent or keep different)
- ✅ Document BackdropFilter decision (acceptable per spec, no change needed)

**During Migration:**
- ✅ Update theme colors first (ChoiceLuxTheme constants)
- ✅ Update screens one by one (isolated, low risk)
- ✅ Test each screen independently

**After Migration:**
- ✅ Verify no impact on non-auth screens
- ✅ BackgroundPatterns.signin safe (auth-only, verified)

---

**END OF BASELINE REPORT**

---

*Next Steps:*
1. ✅ BackgroundPatterns.signin verified (auth-only, safe to modify)
2. Decide on Pending Approval pattern (BackdropFilter or Card?)
3. Begin migration with theme color updates
4. Migrate screens one by one (isolated, low risk)

