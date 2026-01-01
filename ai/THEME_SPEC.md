# Theme Specification — Stealth Luxury (Fleet Command Dark)

**Generated:** 2025-01-XX  
**Agent:** CLC-ARCH  
**Purpose:** Define the dark mode theme specification for Choice Lux Cars  
**Status:** SPECIFICATION COMPLETE

---

## 1) Theme Intent

The "Stealth Luxury (Fleet Command Dark)" theme is designed to provide a sophisticated, professional dark mode experience optimized for fleet management operations. The theme emphasizes:

- **Low-light operation:** Dark backgrounds reduce eye strain during extended use
- **High contrast:** Clear visual hierarchy with amber accents for primary actions
- **Professional aesthetic:** Subtle glassmorphic effects and refined typography
- **Fleet command focus:** Optimized for data-heavy interfaces, status monitoring, and operational dashboards
- **Luxury feel:** Premium materials (glass surfaces, amber glow effects) without ostentation

**Design Philosophy:**
- Minimal, functional elegance
- Information-first approach
- Subtle luxury through material quality, not decoration
- Amber accent color provides warmth and urgency without being aggressive

**Use Cases:**
- Dashboard screens with KPIs and metrics
- Job management and monitoring interfaces
- Data tables and lists
- Forms and input screens
- Status indicators and notifications

---

## 2) Color Tokens

### Background & Surface Tokens

| Token Name | Hex Value | Usage |
|------------|-----------|-------|
| `background` | `#09090b` | Main app background, canvas |
| `surface` | `#18181b` | Card backgrounds, elevated surfaces |
| `surfaceVariant` | `#27272a` | Secondary surfaces, muted backgrounds |
| `surfaceContainer` | `#18181b` with 50% opacity + backdrop blur | Glassmorphic surfaces |

### Primary & Accent Tokens

| Token Name | Hex Value | Usage |
|------------|-----------|-------|
| `primary` | `#f59e0b` | Primary actions, key CTAs, important highlights |
| `primaryContainer` | `#f59e0b` with 10% opacity | Primary action backgrounds (active/hover states) |
| `onPrimary` | `#09090b` | Text/icons on primary background |
| `secondary` | `#27272a` | Secondary actions, muted elements |
| `onSecondary` | `#fafafa` | Text/icons on secondary background |

### Text Tokens

| Token Name | Hex Value | Usage |
|------------|-----------|-------|
| `textHeading` | `#fafafa` | H1-H3 headings, page titles, key stats |
| `textBody` | `#a1a1aa` | Body text, descriptions, default content |
| `textSubtle` | `#52525b` | Helper text, placeholders, disabled text |
| `onSurface` | `#fafafa` | Default text on surfaces (maps to Material `onSurface`) |
| `onSurfaceVariant` | `#a1a1aa` | Secondary text on surfaces |

### Status Tokens

| Token Name | Hex Value | Usage |
|------------|-----------|-------|
| `success` | `#10b981` | Success states, completed status, positive indicators |
| `info` | `#3b82f6` | Info messages, progress indicators, informational states |
| `warning` | `#f43f5e` | Warning states, urgent alerts, error conditions |
| `onSuccess` | `#09090b` | Text/icons on success background |
| `onInfo` | `#fafafa` | Text/icons on info background |
| `onWarning` | `#fafafa` | Text/icons on warning background |

### Border & Divider Tokens

| Token Name | Hex Value | Usage |
|------------|-----------|-------|
| `border` | `#27272a` | Card borders, input borders, dividers |
| `borderVariant` | `#27272a` with 50% opacity | Subtle dividers, separator lines |
| `divider` | `#27272a` | List dividers, section separators |

### Interactive State Tokens

| Token Name | Hex Value | Usage |
|------------|-----------|-------|
| `hoverSurface` | `#27272a` | Hover state background (slightly lighter than surface) |
| `activeSurface` | `#f59e0b` with 10% opacity | Active/pressed state background |
| `focusBorder` | `#f59e0b` | Focus ring color for inputs, buttons |
| `ripple` | `#f59e0b` with 20% opacity | Ripple effect color |

### Shadow & Glow Tokens

| Token Name | Value | Usage |
|------------|-------|-------|
| `shadowSm` | Material `shadow-sm` | Default card shadows |
| `glowAmber` | `#f59e0b` with 30% opacity blur | Amber glow for primary actions, active states |

---

## 3) Material 3 Mapping (ColorScheme field mapping)

### Core ColorScheme Mapping

```dart
ColorScheme.dark(
  // Primary colors
  primary: Color(0xFFF59E0B),              // primary token
  onPrimary: Color(0xFF09090B),             // onPrimary token
  primaryContainer: Color(0xFFF59E0B).withOpacity(0.1), // primaryContainer token
  
  // Secondary colors
  secondary: Color(0xFF27272A),             // secondary token
  onSecondary: Color(0xFFFAFAFA),           // onSecondary token
  secondaryContainer: Color(0xFF27272A),     // surfaceVariant token
  onSecondaryContainer: Color(0xFFA1A1AA),   // textBody token
  
  // Tertiary (optional, can match secondary)
  tertiary: Color(0xFF27272A),
  onTertiary: Color(0xFFFAFAFA),
  
  // Error/Warning
  error: Color(0xFFF43F5E),                 // warning token
  onError: Color(0xFFFAFAFA),               // onWarning token
  errorContainer: Color(0xFFF43F5E).withOpacity(0.1),
  onErrorContainer: Color(0xFFF43F5E),
  
  // Background & Surface
  background: Color(0xFF09090B),           // background token
  onBackground: Color(0xFFFAFAFA),          // textHeading token
  surface: Color(0xFF18181B),                // surface token
  onSurface: Color(0xFFFAFAFA),              // textHeading token
  surfaceVariant: Color(0xFF27272A),        // surfaceVariant token
  onSurfaceVariant: Color(0xFFA1A1AA),       // textBody token
  
  // Outline
  outline: Color(0xFF27272A),                // border token
  outlineVariant: Color(0xFF27272A).withOpacity(0.5), // borderVariant token
  
  // Inverse (for elevated surfaces)
  inverseSurface: Color(0xFF27272A),
  onInverseSurface: Color(0xFFFAFAFA),
  inversePrimary: Color(0xFFF59E0B),
  
  // Shadow
  shadow: Colors.black,
  scrim: Colors.black.withOpacity(0.5),
  
  // Surface tint (for elevation)
  surfaceTint: Color(0xFF27272A),
)
```

### Custom Extension Tokens (AppTokens)

```dart
// Status colors (not in standard ColorScheme)
extension AppTokens on ThemeData {
  Color get successColor => Color(0xFF10B981);      // success token
  Color get infoColor => Color(0xFF3B82F6);          // info token
  Color get warningColor => Color(0xFFF43F5E);       // warning token
  
  // Text colors
  Color get textHeading => Color(0xFFFAFAFA);        // textHeading token
  Color get textBody => Color(0xFFA1A1AA);            // textBody token
  Color get textSubtle => Color(0xFF52525B);          // textSubtle token
  
  // Interactive states
  Color get hoverSurface => Color(0xFF27272A);       // hoverSurface token
  Color get activeSurface => Color(0xFFF59E0B).withOpacity(0.1); // activeSurface token
  Color get focusBorder => Color(0xFFF59E0B);         // focusBorder token
  
  // Glow effect
  Color get glowAmber => Color(0xFFF59E0B).withOpacity(0.3); // glowAmber token
}
```

---

## 4) Typography Mapping (TextTheme + weights guidance)

### Font Family

- **Primary Font:** Inter (Google Fonts)
- **Fallback:** System sans-serif

### Font Weights

- **400 (Regular):** Body text, descriptions, default content
- **500 (Medium):** UI labels, buttons, table headers, form labels
- **700 (Bold):** Titles, key stats, important headings

### Letter Spacing (Tracking)

- **Tight (-0.5px to -1px):** Large headings (H1-H2, >24px)
- **Normal (0px):** Body text, medium headings (H3-H4, 16-24px)
- **Wide (0.5px to 1px):** Small uppercase labels (<14px, buttons, badges)

### TextTheme Mapping

```dart
TextTheme(
  // Display (largest, rarely used)
  displayLarge: TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Color(0xFFFAFAFA), // textHeading
    fontFamily: 'Inter',
  ),
  displayMedium: TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Color(0xFFFAFAFA),
    fontFamily: 'Inter',
  ),
  displaySmall: TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Color(0xFFFAFAFA),
    fontFamily: 'Inter',
  ),
  
  // Headline (page titles, section headers)
  headlineLarge: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Color(0xFFFAFAFA), // textHeading
    fontFamily: 'Inter',
  ),
  headlineMedium: TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: Color(0xFFFAFAFA),
    fontFamily: 'Inter',
  ),
  headlineSmall: TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: Color(0xFFFAFAFA),
    fontFamily: 'Inter',
  ),
  
  // Title (card titles, subsection headers)
  titleLarge: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    color: Color(0xFFFAFAFA), // textHeading
    fontFamily: 'Inter',
  ),
  titleMedium: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: Color(0xFFFAFAFA),
    fontFamily: 'Inter',
  ),
  titleSmall: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: Color(0xFFFAFAFA),
    fontFamily: 'Inter',
  ),
  
  // Label (buttons, form labels, table headers)
  labelLarge: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5, // wide for small uppercase
    color: Color(0xFFFAFAFA),
    fontFamily: 'Inter',
  ),
  labelMedium: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: Color(0xFFA1A1AA), // textBody
    fontFamily: 'Inter',
  ),
  labelSmall: TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: Color(0xFF52525B), // textSubtle
    fontFamily: 'Inter',
  ),
  
  // Body (default text)
  bodyLarge: TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Color(0xFFA1A1AA), // textBody
    fontFamily: 'Inter',
  ),
  bodyMedium: TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Color(0xFFA1A1AA),
    fontFamily: 'Inter',
  ),
  bodySmall: TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    color: Color(0xFF52525B), // textSubtle
    fontFamily: 'Inter',
  ),
)
```

### Typography Usage Guidelines

- **Headings (H1-H3):** Use `headlineLarge/Medium/Small` with `textHeading` color
- **Card Titles:** Use `titleLarge` with `textHeading` color
- **Body Text:** Use `bodyLarge/Medium` with `textBody` color
- **Helper Text:** Use `bodySmall` with `textSubtle` color
- **Buttons:** Use `labelLarge` with appropriate weight (500 for primary, 400 for secondary)
- **Table Headers:** Use `labelMedium` with `textHeading` color
- **Uppercase Labels:** Use `labelSmall` with wide letter spacing (0.5px)

---

## 5) Component Theming Rules

### AppBar

- **Background:** `surface` token (`#18181b`)
- **Elevation:** 0 (no shadow, uses border instead)
- **Border:** 1px bottom border using `border` token (`#27272a`)
- **Title:** `titleLarge` style with `textHeading` color
- **Icon Color:** `textBody` color (`#a1a1aa`)
- **Actions:** Use `textBody` color, amber on hover/active

### Card

- **Background:** `surface` token (`#18181b`)
- **Border:** 1px using `border` token (`#27272a`)
- **Border Radius:** 12px
- **Elevation:** `shadowSm` (Material shadow-sm)
- **Padding:** 16px default
- **Glass Variant:** Use `surfaceContainer` with backdrop blur for glassmorphic cards

### Input Fields (TextField, TextFormField)

- **Background:** `surfaceVariant` token (`#27272a`)
- **Border:** 1px using `border` token (`#27272a`)
- **Border Radius:** 8px
- **Focused Border:** 2px using `focusBorder` token (`#f59e0b`)
- **Text Color:** `textBody` token (`#a1a1aa`)
- **Label Color:** `textBody` token when unfocused, `primary` when focused
- **Hint/Placeholder:** `textSubtle` token (`#52525b`)
- **Padding:** 12px horizontal, 16px vertical

### Buttons

**Primary Button (ElevatedButton):**
- **Background:** `primary` token (`#f59e0b`)
- **Text Color:** `onPrimary` token (`#09090b`)
- **Border Radius:** 8px
- **Padding:** 12px horizontal, 16px vertical
- **Text Style:** `labelLarge` with weight 500
- **Hover:** Slightly lighter primary (10% lighter)
- **Active:** `activeSurface` background (`#f59e0b` with 10% opacity) + amber glow
- **Shadow:** `glowAmber` on active state

**Secondary Button (OutlinedButton):**
- **Background:** Transparent
- **Border:** 1px using `border` token (`#27272a`)
- **Text Color:** `textBody` token (`#a1a1aa`)
- **Border Radius:** 8px
- **Hover:** `hoverSurface` background (`#27272a`)
- **Active:** `activeSurface` background

**Text Button (TextButton):**
- **Background:** Transparent
- **Text Color:** `textBody` token (`#a1a1aa`)
- **Hover:** `hoverSurface` background
- **Active:** `activeSurface` background

### Dividers

- **Color:** `divider` token (`#27272a`)
- **Thickness:** 1px
- **Variant (Subtle):** `borderVariant` token (`#27272a` with 50% opacity)
- **Spacing:** 8px vertical padding around divider

### Snackbars

- **Background:** `surface` token (`#18181b`)
- **Border:** 1px using `border` token (`#27272a`)
- **Border Radius:** 8px
- **Text Color:** `textBody` token (`#a1a1aa`)
- **Action Button:** Use `primary` color for action text
- **Success Variant:** Background `success` token (`#10b981`), text `onSuccess` (`#09090b`)
- **Error Variant:** Background `warning` token (`#f43f5e`), text `onWarning` (`#fafafa`)
- **Info Variant:** Background `info` token (`#3b82f6`), text `onInfo` (`#fafafa`)

### Status Indicators

- **Success:** `success` token (`#10b981`)
- **Info:** `info` token (`#3b82f6`)
- **Warning/Error:** `warning` token (`#f43f5e`)
- **Background (for badges):** Use status color with 10% opacity
- **Text (for badges):** Use status color for text

---

## 6) Interaction Rules

### Hover States

- **Surface Hover:** Change background to `hoverSurface` token (`#27272a`) — slightly lighter than base surface
- **Border Hover:** Change border color to `primary` token (`#f59e0b`) at 50% opacity
- **Text Hover:** Change text color to `textHeading` token (`#fafafa`) if currently `textBody`
- **Button Hover:** Primary buttons get 10% lighter background; secondary buttons get `hoverSurface` background

### Active/Pressed States

- **Surface Active:** Change background to `activeSurface` token (`#f59e0b` with 10% opacity)
- **Text Active:** Change text color to `primary` token (`#f59e0b`)
- **Button Active:** Add `glowAmber` shadow effect (amber glow)
- **Border Active:** Change border to `primary` token (`#f59e0b`)

### Focus States

- **Input Focus:** 2px border using `focusBorder` token (`#f59e0b`)
- **Button Focus:** 2px outline using `focusBorder` token
- **Focus Ring:** Use `focusBorder` color with 20% opacity for focus ring
- **Remove default Material focus indicators** (replace with custom amber focus ring)

### Disabled States

- **Background:** `surfaceVariant` token (`#27272a`)
- **Text:** `textSubtle` token (`#52525b`)
- **Border:** `borderVariant` token (`#27272a` with 50% opacity)
- **Opacity:** 0.5 for entire disabled component

### Selection States

- **Selected Background:** `activeSurface` token (`#f59e0b` with 10% opacity)
- **Selected Text:** `primary` token (`#f59e0b`)
- **Selected Border:** `primary` token (`#f59e0b`)

---

## 7) Do/Don't Rules

### ✅ DO

- **Use semantic tokens:** Always reference color tokens by name (e.g., `theme.colorScheme.surface`, `theme.extension<AppTokens>()!.textHeading`)
- **Use Theme.of(context):** Access theme via `Theme.of(context)` or `context.theme` extension
- **Use AppTokens extension:** Access custom tokens via `context.tokens.textHeading`, `context.tokens.successColor`, etc.
- **Use Material 3 components:** Prefer Material 3 widgets (Card, ElevatedButton, etc.) over custom implementations
- **Use TextTheme:** Reference `Theme.of(context).textTheme.headlineLarge` instead of hard-coding font sizes
- **Use ColorScheme:** Reference `Theme.of(context).colorScheme.primary` instead of hard-coding colors
- **Use opacity helpers:** Use `.withOpacity()` for transparency instead of hard-coding rgba values
- **Use constants for magic numbers:** Define border radius, spacing, etc. as constants in theme tokens

### ❌ DON'T

- **No hard-coded Color literals:** Never use `Color(0xFFF59E0B)` directly in widget code
- **No Colors.* except transparent:** Don't use `Colors.white`, `Colors.black`, etc. (except `Colors.transparent`)
- **No inline hex values:** Don't use `#f59e0b` or `0xFFF59E0B` in widget code
- **No hard-coded font sizes:** Don't use `fontSize: 16` directly — use `textTheme.bodyLarge.fontSize`
- **No hard-coded font weights:** Don't use `fontWeight: FontWeight.w500` directly — use text theme styles
- **No direct Material color access:** Don't use `MaterialColors.amber[500]` or similar
- **No theme mixing:** Don't mix light and dark theme tokens
- **No opacity in hex:** Don't use 8-digit hex colors (e.g., `#80F59E0B`) — use `.withOpacity()` instead

### Code Examples

**❌ BAD:**
```dart
Container(
  color: Color(0xFF18181B),
  child: Text(
    'Hello',
    style: TextStyle(
      color: Color(0xFFFAFAFA),
      fontSize: 16,
      fontWeight: FontWeight.w500,
    ),
  ),
)
```

**✅ GOOD:**
```dart
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text(
    'Hello',
    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  ),
)
```

**❌ BAD:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Color(0xFFF59E0B),
    foregroundColor: Color(0xFF09090B),
  ),
  child: Text('Submit'),
)
```

**✅ GOOD:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
  ),
  child: Text('Submit'),
)
```

---

## 8) Implementation Notes

### Glassmorphic Surfaces

**Definition:**
Glass surfaces use semi-transparent backgrounds with backdrop blur to create a "frosted glass" effect.

**Implementation:**
```dart
// Glass surface container
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: Theme.of(context).colorScheme.outline,
      width: 1,
    ),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: child,
    ),
  ),
)
```

**Token Guidance:**
- **Background:** `surface` token with 50% opacity
- **Border:** `border` token (`#27272a`)
- **Blur:** 10px sigma (adjust based on platform performance)
- **Use Cases:** Modal overlays, floating action panels, elevated cards

### Amber Glow Effects

**Definition:**
Amber glow provides visual feedback for primary actions and active states, creating a subtle "halo" effect.

**Implementation:**
```dart
// Amber glow shadow
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).colorScheme.primaryContainer,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Theme.of(context).extension<AppTokens>()!.glowAmber,
        blurRadius: 12,
        spreadRadius: 2,
      ),
    ],
  ),
  child: child,
)
```

**Token Guidance:**
- **Glow Color:** `glowAmber` token (`#f59e0b` with 30% opacity)
- **Blur Radius:** 12px
- **Spread Radius:** 2px (optional, for stronger glow)
- **Use Cases:** Primary button active state, focused inputs, selected items

### Consistent Application

**Glass Surfaces:**
- Use for: Modal dialogs, bottom sheets, floating panels, elevated cards
- Don't use for: Main app background, standard cards (use solid surface instead)

**Amber Glow:**
- Use for: Primary button active/pressed state, focused input fields, selected list items
- Don't use for: Hover states (too subtle), disabled states, secondary actions

**Performance Considerations:**
- Backdrop blur can be expensive on some platforms — test performance
- Consider using solid backgrounds on low-end devices
- Use `RepaintBoundary` for complex glass surfaces to optimize repaints

### Theme Extension Pattern

**Create AppTokens Extension:**
```dart
// In theme_tokens.dart or similar
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final Color successColor;
  final Color infoColor;
  final Color warningColor;
  final Color textHeading;
  final Color textBody;
  final Color textSubtle;
  final Color hoverSurface;
  final Color activeSurface;
  final Color focusBorder;
  final Color glowAmber;
  
  // ... constructor, copyWith, lerp methods
}

// Extension for easy access
extension AppTokensExtension on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
}
```

**Usage:**
```dart
// Access custom tokens
context.tokens.successColor
context.tokens.textHeading
context.tokens.glowAmber
```

---

**Status:** SPECIFICATION COMPLETE  
**Next Step:** CLC-BUILD implements theme based on this specification  
**Approval Required:** Yes — Before implementation begins

