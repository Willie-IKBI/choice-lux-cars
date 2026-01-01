# Theme Rules — Enforceable Theming Standards

**Generated:** 2025-01-XX  
**Agent:** CLC-ARCH  
**Purpose:** Define enforceable theming rules and token strategy to prevent drift  
**Status:** RULES ESTABLISHED

**Source of Truth:** `/ai/THEME_SPEC.md` — All theme specifications must align with this document.

---

## 1) Authoritative Theme Sources

### Single ThemeData Entry Point

**File:** `lib/app/theme.dart`

**Function/Class:** `ChoiceLuxTheme.darkTheme` (or similar theme factory)

**Authority:** This is the **only** place where `ThemeData` is constructed. All theme configuration must be centralized here.

**Enforcement:** No widget, screen, or feature may create its own `ThemeData` instance. All theme access must flow through this entry point.

### Color Token Container

**Name:** `AppTokens` (ThemeExtension)

**File:** `lib/app/theme_tokens.dart` (or `lib/core/theme/app_tokens.dart`)

**Purpose:** Contains all custom semantic tokens that are not part of Material 3 ColorScheme:
- Status colors (success, info, warning)
- Text color tokens (textHeading, textBody, textSubtle)
- Interactive state tokens (hoverSurface, activeSurface, focusBorder)
- Visual effect tokens (glowAmber)

**Authority:** This is the **only** place where custom color tokens are defined. All semantic colors must be defined here.

### ThemeExtensions Used

**Required Extensions:**

1. **`AppTokens`** (ThemeExtension)
   - **Purpose:** Custom semantic tokens (status colors, text colors, interactive states, visual effects)
   - **File:** `lib/app/theme_tokens.dart`
   - **Access:** `context.extension<AppTokens>()` or `context.tokens` (via extension)

2. **Optional: `GlassTokens`** (if glass effects need additional configuration)
   - **Purpose:** Glassmorphic surface configuration (blur radius, opacity levels)
   - **File:** `lib/app/theme_tokens.dart` (can be part of AppTokens)
   - **Access:** `context.extension<GlassTokens>()` or via AppTokens

3. **Optional: `SpacingTokens`** (if spacing is part of theme)
   - **Purpose:** Consistent spacing values
   - **File:** `lib/app/theme_tokens.dart` (can be part of AppTokens)
   - **Access:** `context.extension<SpacingTokens>()` or via AppTokens

**Authority:** All ThemeExtensions must be defined in the theme tokens file and registered in the main ThemeData.

---

## 2) Token Categories

### Core ColorScheme Tokens

**Source:** Material 3 `ColorScheme.dark()` fields

**Tokens:**
- `primary`, `onPrimary`, `primaryContainer`
- `secondary`, `onSecondary`, `secondaryContainer`
- `background`, `onBackground`
- `surface`, `onSurface`, `surfaceVariant`, `onSurfaceVariant`
- `outline`, `outlineVariant`
- `error`, `onError`, `errorContainer`, `onErrorContainer`
- `inverseSurface`, `onInverseSurface`
- `shadow`, `scrim`, `surfaceTint`

**Access:** `Theme.of(context).colorScheme.primary` (or `context.colorScheme.primary` via extension)

**Authority:** These tokens are defined in `/ai/THEME_SPEC.md` Section 3 (Material 3 Mapping). All mappings must match the specification exactly.

### Semantic Tokens

**Source:** `AppTokens` ThemeExtension

**Tokens:**
- `successColor` — Success states, completed status
- `infoColor` — Info messages, progress indicators
- `warningColor` — Warning states, urgent alerts, errors
- `onSuccess`, `onInfo`, `onWarning` — Text colors for status backgrounds

**Access:** `context.extension<AppTokens>()!.successColor` or `context.tokens.successColor` (via extension)

**Authority:** These tokens are defined in `/ai/THEME_SPEC.md` Section 2 (Color Tokens). All hex values must match the specification exactly.

### Structural Tokens

**Source:** Mix of ColorScheme and AppTokens

**Tokens:**
- `border` — Card borders, input borders (maps to `outline` in ColorScheme)
- `borderVariant` — Subtle dividers (maps to `outlineVariant` in ColorScheme)
- `divider` — List dividers, section separators (maps to `outline` in ColorScheme)
- `hoverSurface` — Hover state background (AppTokens)
- `activeSurface` — Active/pressed state background (AppTokens)

**Access:** 
- Borders: `context.colorScheme.outline` or `context.colorScheme.outlineVariant`
- Interactive: `context.tokens.hoverSurface`, `context.tokens.activeSurface`

**Authority:** These tokens are defined in `/ai/THEME_SPEC.md` Section 2 (Color Tokens). All values must match the specification.

### Visual Effect Tokens

**Source:** `AppTokens` ThemeExtension

**Tokens:**
- `glowAmber` — Amber glow effect color (for primary actions, active states)
- Glass surface configuration (opacity, blur radius) — via AppTokens or separate extension

**Access:** `context.tokens.glowAmber`

**Authority:** These tokens are defined in `/ai/THEME_SPEC.md` Section 8 (Implementation Notes). All visual effects must follow the implementation patterns specified.

### Text Color Tokens

**Source:** `AppTokens` ThemeExtension

**Tokens:**
- `textHeading` — H1-H3 headings, page titles, key stats
- `textBody` — Body text, descriptions, default content
- `textSubtle` — Helper text, placeholders, disabled text

**Access:** `context.tokens.textHeading`, `context.tokens.textBody`, `context.tokens.textSubtle`

**Authority:** These tokens are defined in `/ai/THEME_SPEC.md` Section 2 (Color Tokens). All hex values must match the specification exactly.

**Note:** TextTheme styles should use these tokens, not hard-coded colors.

---

## 3) Access Rules (How Widgets Must Read Theme Data)

### Accessing Colors

**Rule 1: Use ColorScheme for Material 3 Colors**
```dart
// ✅ CORRECT
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface
context.colorScheme.primary  // via extension

// ❌ WRONG
Color(0xFFF59E0B)
Colors.amber
```

**Rule 2: Use AppTokens for Semantic Colors**
```dart
// ✅ CORRECT
context.extension<AppTokens>()!.successColor
context.tokens.successColor  // via extension
context.tokens.textHeading

// ❌ WRONG
Color(0xFF10B981)  // success color
Color(0xFFFAFAFA)  // text heading
```

**Rule 3: Use ColorScheme for Structural Colors**
```dart
// ✅ CORRECT
context.colorScheme.outline  // borders
context.colorScheme.outlineVariant  // subtle borders
context.colorScheme.surfaceVariant  // secondary surfaces

// ❌ WRONG
Color(0xFF27272A)  // border color
```

### Accessing Text Styles

**Rule 4: Use TextTheme for Typography**
```dart
// ✅ CORRECT
Theme.of(context).textTheme.headlineLarge
Theme.of(context).textTheme.bodyLarge
context.textTheme.titleMedium  // via extension

// ❌ WRONG
TextStyle(fontSize: 24, fontWeight: FontWeight.w700)
TextStyle(color: Color(0xFFFAFAFA))
```

**Rule 5: Override Text Color via Theme Tokens**
```dart
// ✅ CORRECT
context.textTheme.bodyLarge?.copyWith(
  color: context.tokens.textBody,
)

// ❌ WRONG
context.textTheme.bodyLarge?.copyWith(
  color: Color(0xFFA1A1AA),
)
```

### When ThemeExtension is Required vs ColorScheme

**Use ColorScheme When:**
- Accessing Material 3 standard colors (primary, surface, background, etc.)
- Accessing standard Material 3 structural colors (outline, surfaceVariant, etc.)
- Accessing standard Material 3 text colors (onSurface, onPrimary, etc.)

**Use AppTokens (ThemeExtension) When:**
- Accessing semantic status colors (success, info, warning)
- Accessing custom text color tokens (textHeading, textBody, textSubtle)
- Accessing interactive state tokens (hoverSurface, activeSurface, focusBorder)
- Accessing visual effect tokens (glowAmber)

**Decision Tree:**
1. Is it a Material 3 standard color? → Use `ColorScheme`
2. Is it a custom semantic token? → Use `AppTokens`
3. Is it a custom text color? → Use `AppTokens`
4. Is it a visual effect? → Use `AppTokens`

---

## 4) Forbidden Patterns (Hard Rules)

### ❌ Hard-Coded Color Literals

**Forbidden:**
- `Color(0xFFF59E0B)` — Use `context.colorScheme.primary` instead
- `Color(0xFF18181B)` — Use `context.colorScheme.surface` instead
- `Color(0xFFFAFAFA)` — Use `context.tokens.textHeading` instead
- Any `Color(0x...)` literal in widget code

**Enforcement:** REVIEW must block all PRs containing hard-coded Color literals (except transparent).

### ❌ Colors.* Constants

**Forbidden:**
- `Colors.white` — Use `context.colorScheme.onSurface` or `context.tokens.textHeading`
- `Colors.black` — Use `context.colorScheme.background` or `context.colorScheme.surface`
- `Colors.amber` — Use `context.colorScheme.primary`
- `Colors.green` — Use `context.tokens.successColor`
- `Colors.blue` — Use `context.tokens.infoColor`
- `Colors.red` — Use `context.tokens.warningColor`
- Any `Colors.*` usage (except `Colors.transparent`)

**Enforcement:** REVIEW must block all PRs containing `Colors.*` usage (except transparent).

### ❌ Inline TextStyle Colors

**Forbidden:**
```dart
TextStyle(
  color: Color(0xFFFAFAFA),  // ❌
  fontSize: 16,
)
```

**Required:**
```dart
TextStyle(
  color: context.tokens.textHeading,  // ✅
  fontSize: 16,
)
```

**Enforcement:** REVIEW must block all PRs containing inline color definitions in TextStyle.

### ❌ FlutterFlow Legacy Constants

**Forbidden:**
- Any constants from `lib/flutter_flow/` directory
- Any `*_model.dart` files with color definitions
- Any legacy theme files from FlutterFlow migration

**Enforcement:** REVIEW must block all PRs referencing FlutterFlow legacy code.

### ❌ Per-Widget Theme Overrides

**Forbidden:**
```dart
// ❌ Creating local ThemeData
Theme(
  data: ThemeData.dark().copyWith(...),
  child: Widget(),
)

// ❌ Overriding theme in widget
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).copyWith(...),  // ❌
  ),
)
```

**Required:**
- All theme configuration must be in `lib/app/theme.dart`
- Widgets must use theme as-is, not override it

**Enforcement:** REVIEW must block all PRs containing per-widget theme overrides.

### ❌ Hard-Coded Font Sizes and Weights

**Forbidden:**
```dart
TextStyle(
  fontSize: 16,  // ❌
  fontWeight: FontWeight.w500,  // ❌
)
```

**Required:**
```dart
context.textTheme.bodyLarge  // ✅ (includes size and weight)
```

**Enforcement:** REVIEW must block all PRs containing hard-coded font sizes or weights (except when extending TextTheme styles).

---

## 5) Allowed Exceptions (Explicit)

### ✅ Colors.transparent

**Allowed:** `Colors.transparent` is explicitly allowed.

**Usage:** For transparent backgrounds, borders, or overlays.

**Example:**
```dart
Container(
  color: Colors.transparent,  // ✅ ALLOWED
  child: child,
)
```

### ✅ Debug-Only Visuals

**Allowed:** Hard-coded colors in debug-only code (wrapped in `kDebugMode` or `assert`).

**Usage:** Debug overlays, development-only indicators, test visuals.

**Example:**
```dart
if (kDebugMode) {
  Container(
    color: Colors.red,  // ✅ ALLOWED (debug only)
    child: Text('DEBUG'),
  );
}
```

**Requirement:** Must be clearly marked as debug-only and removed before production.

### ✅ Temporary Legacy Areas (Documented)

**Allowed:** Legacy code areas that are explicitly documented and scheduled for migration.

**Requirements:**
1. Must be documented in code comments: `// TODO: Migrate to theme tokens - see /ai/THEME_RULES.md`
2. Must be listed in `/ai/LEGACY_THEME_AREAS.md` (if such file exists)
3. Must have a migration ticket/plan
4. Must not be expanded or copied to new code

**Example:**
```dart
// TODO: Migrate to theme tokens - Legacy area, scheduled for Q2 2025
Container(
  color: Color(0xFF18181B),  // ✅ ALLOWED (temporary, documented)
  child: legacyWidget,
)
```

**Enforcement:** REVIEW must verify that legacy areas are properly documented and not expanded.

### ✅ PDF Generation (Separate Theme)

**Allowed:** PDF generation code may use separate color definitions (not Flutter theme).

**Reason:** PDFs are generated server-side or offline and don't use Flutter's theme system.

**File:** `lib/features/pdf/pdf_theme.dart`

**Requirement:** PDF theme must still follow the same color palette from THEME_SPEC.md, but can use hard-coded values in the PDF theme file only.

---

## 6) Review Enforcement Rules

### What REVIEW Must Block

**REVIEW must reject PRs containing:**

1. **Hard-coded Color literals** (`Color(0x...)`) in widget code
2. **Colors.* usage** (except `Colors.transparent`)
3. **Inline TextStyle colors** (must use theme tokens)
4. **FlutterFlow legacy constants** or references
5. **Per-widget theme overrides** (ThemeData.copyWith in widgets)
6. **Hard-coded font sizes/weights** (must use TextTheme)
7. **New legacy areas** (expanding undocumented hard-coded colors)
8. **Missing theme token usage** (using hard-coded values when tokens exist)

**Enforcement Method:**
- Code review checklist
- Automated linting (if available)
- Manual grep for forbidden patterns

### What REVIEW May Allow Temporarily

**REVIEW may allow (with conditions):**

1. **Legacy areas** — If properly documented with TODO and migration plan
2. **Debug-only code** — If wrapped in `kDebugMode` and clearly marked
3. **PDF theme code** — If in `lib/features/pdf/pdf_theme.dart` only
4. **Emergency hotfixes** — If documented and scheduled for immediate follow-up migration

**Conditions:**
- Must add TODO comment referencing THEME_RULES.md
- Must not expand the pattern to new code
- Must have a migration plan/ticket

### What Must Be Escalated Back to ARCH

**REVIEW must escalate to ARCH:**

1. **New token requests** — If a new color token is needed that doesn't exist in THEME_SPEC.md
2. **Theme architecture changes** — If the theme structure needs modification
3. **Exception requests** — If a new exception to forbidden patterns is needed
4. **Token conflicts** — If there's ambiguity about which token to use
5. **Performance issues** — If theme access patterns cause performance problems
6. **Migration blockers** — If migration is blocked by architectural constraints

**Escalation Process:**
- Create issue/ticket with "ARCH-REVIEW" label
- Include context, proposed solution, and impact analysis
- Wait for ARCH approval before proceeding

---

## 7) Migration Strategy

### How Existing Screens Should Be Migrated Safely

**Migration Process:**

1. **Audit Phase:**
   - Identify all hard-coded colors in the feature/screen
   - Map each color to the appropriate theme token
   - Document the mapping in a migration checklist

2. **Preparation Phase:**
   - Ensure theme tokens are available (verify AppTokens extension)
   - Ensure TextTheme styles are configured correctly
   - Create a test plan for visual regression

3. **Migration Phase:**
   - Replace hard-coded colors with theme tokens one-by-one
   - Replace hard-coded text styles with TextTheme
   - Test each change incrementally
   - Verify visual appearance matches design

4. **Verification Phase:**
   - Run visual regression tests
   - Verify all colors match THEME_SPEC.md
   - Verify no hard-coded colors remain
   - Verify theme access follows access rules

**Migration Checklist Template:**
```
Feature: [Feature Name]
- [ ] Audit hard-coded colors
- [ ] Map colors to theme tokens
- [ ] Replace Color(0x...) with theme tokens
- [ ] Replace Colors.* with theme tokens
- [ ] Replace inline TextStyle colors
- [ ] Replace hard-coded font sizes with TextTheme
- [ ] Test visual appearance
- [ ] Verify no regressions
- [ ] Remove legacy TODO comments
```

### Batch Size Guidance (Feature-by-Feature)

**Recommended Approach:** Migrate one feature at a time.

**Batch Size:**
- **Small features:** 1-2 screens → 1 PR
- **Medium features:** 3-5 screens → 1-2 PRs
- **Large features:** 6+ screens → Multiple PRs (2-3 screens per PR)

**Rationale:**
- Easier to review and test
- Reduces risk of regressions
- Allows incremental progress
- Easier to rollback if issues arise

**Feature Priority:**
1. **High-traffic screens** (dashboard, jobs list) — Migrate first
2. **Core features** (jobs, invoices, quotes) — Migrate second
3. **Secondary features** (settings, profile) — Migrate third
4. **Legacy areas** — Migrate last (after main features)

### Visual Regression Avoidance Rules

**Pre-Migration:**
1. **Capture baseline screenshots** of all screens to be migrated
2. **Document current appearance** (colors, spacing, typography)
3. **Create visual test suite** (if available)

**During Migration:**
1. **Test incrementally** — After each screen/widget migration
2. **Compare visually** — Side-by-side comparison with baseline
3. **Verify theme tokens** — Ensure correct token is used
4. **Check all states** — Normal, hover, active, disabled, error

**Post-Migration:**
1. **Run visual regression tests** — Compare new screenshots with baseline
2. **Manual review** — Visual inspection of all screens
3. **User acceptance** — If possible, get stakeholder sign-off
4. **Document changes** — Note any intentional visual changes

**Rollback Plan:**
- Keep old code in version control (git history)
- Create feature flag if needed (for gradual rollout)
- Have migration checklist ready for quick rollback

---

## 8) Definition of Done for Theme Compliance

### ✅ Theme Compliance Checklist

A feature/screen is considered theme-compliant when:

1. **No Hard-Coded Colors:**
   - [ ] Zero `Color(0x...)` literals in widget code (except transparent)
   - [ ] Zero `Colors.*` usage (except transparent)
   - [ ] All colors come from `ColorScheme` or `AppTokens`

2. **Proper Theme Access:**
   - [ ] All colors accessed via `context.colorScheme.*` or `context.tokens.*`
   - [ ] All text styles accessed via `context.textTheme.*`
   - [ ] No per-widget theme overrides

3. **Token Usage:**
   - [ ] Semantic colors use `AppTokens` (success, info, warning)
   - [ ] Text colors use `AppTokens` (textHeading, textBody, textSubtle)
   - [ ] Structural colors use `ColorScheme` (surface, outline, etc.)
   - [ ] Interactive states use `AppTokens` (hoverSurface, activeSurface)

4. **Typography Compliance:**
   - [ ] No hard-coded font sizes (use TextTheme)
   - [ ] No hard-coded font weights (use TextTheme)
   - [ ] Text colors use theme tokens, not hard-coded values

5. **Visual Consistency:**
   - [ ] All colors match THEME_SPEC.md values
   - [ ] All typography matches THEME_SPEC.md specifications
   - [ ] All components follow THEME_SPEC.md component rules

6. **Code Quality:**
   - [ ] No legacy TODO comments (unless documented exception)
   - [ ] No FlutterFlow references
   - [ ] Code follows access rules from Section 3

7. **Testing:**
   - [ ] Visual regression tests pass (if available)
   - [ ] Manual visual review completed
   - [ ] All interactive states tested (hover, active, focus, disabled)

8. **Documentation:**
   - [ ] Migration checklist completed
   - [ ] Any exceptions documented
   - [ ] Code comments reference theme tokens (if needed for clarity)

### ✅ Review Approval Criteria

**REVIEW must approve when:**
- All checklist items are complete
- No forbidden patterns remain
- Visual appearance matches THEME_SPEC.md
- Code follows access rules

**REVIEW must reject when:**
- Any forbidden pattern is present
- Theme tokens are not used correctly
- Visual appearance doesn't match specification
- Access rules are violated

### ✅ Final Sign-Off

**Theme compliance is achieved when:**
1. ✅ All checklist items are complete
2. ✅ REVIEW has approved the PR
3. ✅ Visual regression tests pass (if available)
4. ✅ No exceptions remain (or all exceptions are documented)

**Authority:** ARCH has final authority on theme compliance disputes.

---

**Status:** RULES ESTABLISHED  
**Enforcement:** Effective immediately for all new code; migration applies to existing code  
**Updates:** Any changes to these rules must be approved by ARCH and documented in this file

