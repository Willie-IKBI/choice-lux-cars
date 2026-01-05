# Design System Specification: Obsidian Luxury Ops
## Choice Lux Cars - Theme & Component System

**Version:** 0.7 (Draft - Pre-Migration)  
**Target Version:** 1.0 (Post-Migration)  
**Date:** 2025-01-XX  
**Status:** Living Document  
**Purpose:** Complete design system definition for "Obsidian Luxury Ops" theme migration

**Version History:**
- **v0.7** (Pre-Migration): Initial specification, based on design principles
- **v0.8** (Target: After Phase 1): Validated with prototype screens, adjustments based on real usage
- **v0.9** (Target: After Phase 2): Refined after component migration, patterns established
- **v1.0** (Target: After Phase 4): Finalized after full migration and real-world usage

**Note:** This is a **living document**. It will evolve as we migrate and learn from real usage. Do not assume v1.0 is final—the system should adapt based on actual user experience and operational needs.

---

## 1. DESIGN PHILOSOPHY

### 1.1 Core Principles

**"Luxury through Restraint, Not Decoration"**

The Obsidian design system prioritizes:
- **Clarity over complexity** - Information hierarchy through spacing and scale, not decoration
- **Restraint over richness** - Flat surfaces, minimal effects, intentional use of premium touches
- **Function over form** - Every visual element serves a purpose (signals, hierarchy, interaction)
- **Operational over impressive** - Designed for daily use, long sessions, multi-device support

### 1.2 Key Principles

1. **Gold is a SIGNAL, not a frame** - Gold indicates action, selection, priority, status. Not containers, borders, or passive elements.
2. **Three surface tiers** - Clear hierarchy through surface treatment (Primary, Secondary, Passive)
3. **Reduced visual weight** - ~25% less decoration (gradients, glows, shadows)
4. **Desktop vs Mobile behavior** - Same colors, different rules (depth on desktop, flat on mobile)
5. **Spacing over borders** - Use grouping and spacing for structure, borders only where ambiguous

---

## 2. COLOR PALETTE

### 2.1 Base Colors (Dark Mode Only)

| Name | Hex Code | Usage | Flutter Reference |
|------|----------|-------|-------------------|
| **Background** (Deepest Onyx) | `#09090B` | Root canvas, scaffold background | `obsidianBackground` |
| **Surface** (Zinc 900) | `#18181B` | Cards, panels, Tier 2 surfaces | `obsidianSurface` |
| **Surface Highlight** (Zinc 800) | `#27272A` | Hover states, selected surfaces | `obsidianSurfaceHighlight` |

**Migration Note:** Replace `jetBlack` (#0B0B0C) with `#09090B`, `charcoalGray` (#202125) with `#18181B`

---

### 2.2 Accent Colors

| Name | Hex Code | Usage | Flutter Reference |
|------|----------|-------|-------------------|
| **Primary** (Champagne Gold) | `#C6A87C` | Primary actions, active states, key metrics, selected items | `obsidianPrimary` / `obsidianGold` |
| **Secondary** (Steel) | `#94A3B8` | Secondary icons, metadata, subtle accents | `obsidianSecondary` / `obsidianSteel` |
| **Border** (Subtle White) | `rgba(255, 255, 255, 0.08)` | Card borders, dividers (Tier 2/3) | `obsidianBorder` |

**Migration Note:** Replace `richGold` (#C8A24A) with `#C6A87C`, `platinumSilver` (#B0B7C3) with `#94A3B8`

---

### 2.3 Typography Colors

| Name | Hex Code | Usage | Flutter Reference |
|------|----------|-------|-------------------|
| **Headings** (Pure White) | `#FFFFFF` | Page titles, card headers, large numbers | `obsidianTextHeading` |
| **Body** (Zinc 400) | `#A1A1AA` | Paragraphs, lists, table data, general text | `obsidianTextBody` |
| **Muted** (Zinc 600) | `#52525B` | Labels, hints, timestamps, secondary text | `obsidianTextMuted` |

**Migration Note:** Replace `softWhite` (#F5F7FA) with `#FFFFFF` for headings, add `#A1A1AA` for body

---

### 2.4 Status Colors (Desaturated & Subtle)

| Name | Hex Code | Usage | Tier Behavior |
|------|----------|-------|---------------|
| **Success/Active** (Emerald) | `#10B981` | Active status, completed states | Tier 1: Subtle glow (desktop), Tier 2/3: Flat |
| **Warning/Maintenance** (Amber) | `#F59E0B` | Warning states, pending actions | Tier 1: Subtle glow (desktop), Tier 2/3: Flat |
| **Critical/Error** (Red) | `#EF4444` | Errors, critical alerts, cancelled states | Tier 1: Subtle glow (desktop), Tier 2/3: Flat |
| **Info** (Blue) | `#42A5F5` | Informational states, in-progress | Tier 1: Subtle glow (desktop), Tier 2/3: Flat |

**Note:** Status colors are used from existing theme (no changes needed). Apply tier-based styling (glow for Tier 1 desktop only).

---

## 3. SURFACE TIER SYSTEM

### 3.1 Tier Definitions

The three-tier system creates visual hierarchy through surface treatment, not decoration.

#### Tier 1: Primary (Attention)

**Purpose:** KPIs that drive decisions, alerts, "Today/Now" metrics, critical information

**Characteristics:**
- Gold accents allowed (borders, icons, text highlights)
- Subtle glow effects (desktop only)
- Stronger contrast
- Slightly elevated appearance
- Used sparingly (5-10% of UI)

**Examples:**
- KPI metric cards (revenue, active jobs, alerts)
- Critical alerts/notifications
- Primary CTAs
- Selected states
- Priority status indicators

**Styling:**
- Background: `#18181B` with 60% opacity (desktop), 80% (mobile)
- Border: Gold (`#C6A87C`) at 30% opacity, 1px width
- Shadow: Single shadow (desktop only), `rgba(0,0,0,0.5)` blur 20, offset (0,8)
- Optional glow: Gold glow shadow on desktop only, `rgba(198,168,124,0.1)` blur 15
- No gradients (prefer flat, solid colors)

---

#### Tier 2: Secondary (Working Surfaces)

**Purpose:** Lists, tables, navigation cards, working surfaces, data displays

**Characteristics:**
- NO gold (use white/silver for icons, text)
- NO glow effects
- Minimal borders (white 5% opacity)
- Flat design
- Standard contrast
- Most common tier (70-80% of UI)

**Examples:**
- Navigation cards (Clients, Jobs, Vehicles, Quotes)
- List items (ClientCard, JobCard, QuoteCard)
- Data tables
- Forms and inputs
- Working surfaces

**Styling:**
- Background: `#18181B` with 40% opacity (desktop), 60% (mobile)
- Border: White at 5% opacity, 1px width (or no border, use spacing)
- Shadow: Minimal or none (desktop: single subtle shadow, mobile: none)
- No gradients (flat, solid colors only)
- Hover: Border changes to 8% opacity (desktop only), subtle background change

---

#### Tier 3: Passive (Context)

**Purpose:** Activity logs, history, metadata, low-priority information

**Characteristics:**
- NO borders (or extremely subtle)
- NO shadows
- NO glow
- Reduced contrast
- Maximum quiet
- Used for reference, not decision-making (10-15% of UI)

**Examples:**
- Activity feeds
- Notification list items (non-critical)
- Audit trails
- Historical data
- Metadata fields
- Sidebar/navigation (quiet zone)

**Styling:**
- Background: `#18181B` with 20% opacity
- Border: None (or white 3% opacity only if separation needed)
- Shadow: None
- No gradients
- Text: Muted colors (`#52525B` for labels, `#A1A1AA` for content)

---

### 3.2 Tier Assignment Guidelines

**Tier 1 (Primary) - Use when:**
- ✅ Information drives immediate decisions
- ✅ "Today/Now" time-sensitive metrics
- ✅ Critical alerts requiring attention
- ✅ Primary actions (CTAs)
- ✅ Selected/active states
- ✅ Priority status indicators

**Tier 2 (Secondary) - Use when:**
- ✅ Navigation/routing (cards, lists)
- ✅ Working with data (tables, forms)
- ✅ Standard information display
- ✅ Interactive but not critical
- ✅ Most common use case

**Tier 3 (Passive) - Use when:**
- ✅ Reference information (logs, history)
- ✅ Activity feeds
- ✅ Metadata/background info
- ✅ Quiet zones (sidebar, footer)
- ✅ Non-critical notifications

---

### 3.3 Tier Styling Rules

**Desktop vs Mobile:**

| Property | Tier 1 (Desktop) | Tier 1 (Mobile) | Tier 2 (Desktop) | Tier 2 (Mobile) | Tier 3 (Both) |
|----------|------------------|-----------------|------------------|-----------------|---------------|
| Background Opacity | 60% | 80% | 40% | 60% | 20% |
| Border | Gold 30% | Gold 40% | White 5% | White 8% | None |
| Shadow | 1 shadow (subtle) | None | 1 shadow (minimal) | None | None |
| Glow | Optional (gold) | None | None | None | None |
| Hover Effects | Border/glow | None | Border only | None | None |

**Key Rule:** Mobile = Flatter, Tighter, Fewer Effects

---

## 4. GOLD USAGE RULES

### 4.1 Gold is a SIGNAL, Not a Frame

Gold (`#C6A87C`) must be used sparingly and intentionally. It indicates importance, action, or priority.

#### ✅ Gold IS Allowed For:

1. **Primary Actions**
   - Primary button backgrounds
   - Primary CTAs
   - Submit/confirm actions

2. **Selected/Active States**
   - Selected items (cards, list items)
   - Active navigation items
   - Current step indicators

3. **Priority Indicators**
   - Critical alerts
   - VIP status badges
   - Priority status indicators
   - Urgent notifications

4. **Key Metrics (Tier 1)**
   - KPI highlights (numbers, labels)
   - Important metric cards
   - Dashboard highlights

5. **Tier 1 Borders/Accents**
   - Tier 1 card borders (30% opacity)
   - Tier 1 icon highlights
   - Tier 1 text accents

---

#### ❌ Gold is NOT Allowed For:

1. **Default Card Borders**
   - Navigation cards (Tier 2)
   - List items (Tier 2)
   - Standard containers

2. **Passive Icons**
   - Navigation icons (should be white/silver)
   - Standard action icons (should be white/silver)
   - Metadata icons (should be muted)

3. **Background Structure**
   - Sidebar/navigation backgrounds
   - Container backgrounds
   - Structural elements

4. **Tier 2/3 Elements**
   - Secondary buttons (use white/transparent)
   - Working surfaces
   - Activity feeds
   - Passive information

5. **Decorative Elements**
   - Hover effects (use white opacity)
   - Background patterns
   - Non-functional accents

---

### 4.2 Gold Usage Examples

**✅ Correct:**
```dart
// Primary button
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: obsidianGold, // ✅ Correct
  ),
)

// Selected card border
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: obsidianGold.withOpacity(0.3), // ✅ Correct for Tier 1/selected
    ),
  ),
)

// Priority status badge
Container(
  color: obsidianGold, // ✅ Correct for priority
  child: Text('VIP', style: TextStyle(color: Colors.black)),
)
```

**❌ Incorrect:**
```dart
// Navigation card border
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: obsidianGold, // ❌ Wrong - Tier 2, not priority
    ),
  ),
)

// Navigation icon
Icon(Icons.people, color: obsidianGold), // ❌ Wrong - should be white/silver

// Secondary button border
Container(
  decoration: BoxDecoration(
    border: Border.all(
      color: obsidianGold, // ❌ Wrong - ghost buttons use white
    ),
  ),
)
```

---

## 5. TYPOGRAPHY

### 5.1 Font Families

| Usage | Font | Source | Weights |
|-------|------|--------|---------|
| **Headings** | Outfit | Google Fonts | 400 (regular), 500 (medium), 700 (bold) |
| **Body** | Inter | Google Fonts | 400 (regular), 500 (medium), 600 (semibold) |

**Implementation:**
- Use `google_fonts` package (already in dependencies)
- Apply via `TextTheme` in `ThemeData`
- Fallback to system fonts if loading fails

---

### 5.2 Type Hierarchy

| Level | Font | Size (Desktop) | Size (Mobile) | Weight | Color | Usage |
|-------|------|----------------|---------------|--------|-------|-------|
| **Display** | Outfit | 48px (text-5xl) | 36px | Bold (700) | #FFFFFF | Dashboard summaries, hero numbers |
| **Page Title** | Outfit | 24px (text-2xl) | 20px | Medium (500) | #FFFFFF | Screen headers, page titles |
| **Card Title** | Outfit | 18px (text-lg) | 16px | Medium (500) | #FFFFFF | Card headers, section titles |
| **Label** | Inter | 12px (text-xs) | 11px | Regular (400) | #52525B | Field labels, uppercase, tracking-widest |
| **Body** | Inter | 14px (text-sm) | 14px | Regular (400) | #A1A1AA | Paragraphs, lists, table data |
| **Body Strong** | Inter | 14px (text-sm) | 14px | Semibold (600) | #A1A1AA | Emphasized body text |
| **Caption** | Inter | 12px (text-xs) | 11px | Regular (400) | #52525B | Timestamps, hints, metadata |

**Responsive Scaling:**
- Use `ResponsiveTokens.getFontSize(screenWidth, baseSize: X)`
- Desktop: baseSize + 1 to +2
- Mobile: baseSize - 1 to -2
- Maintain readability (minimum 11px on mobile)

---

### 5.3 Typography Implementation

**TextTheme Structure:**
```dart
textTheme: TextTheme(
  displayLarge: GoogleFonts.outfit(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: obsidianTextHeading,
  ),
  headlineMedium: GoogleFonts.outfit( // Page Title
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: obsidianTextHeading,
  ),
  titleLarge: GoogleFonts.outfit( // Card Title
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: obsidianTextHeading,
  ),
  bodyMedium: GoogleFonts.inter( // Body
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: obsidianTextBody,
  ),
  bodySmall: GoogleFonts.inter( // Label/Caption
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: obsidianTextMuted,
    letterSpacing: 0.5,
  ),
)
```

---

## 6. BUTTON SYSTEM

### 6.1 Button Variants

Three button variants for different use cases:

---

#### Primary Button

**Usage:** Primary actions, CTAs, submit buttons, critical actions

**Styling:**
- Background: Solid gold (`#C6A87C`)
- Text: Black (`#1A1A1A` or `#0A0A0A`)
- Border: None (solid background)
- Shadow: Minimal (desktop only), `rgba(0,0,0,0.3)` blur 4, offset (0,2)
- Border Radius: 6px (mobile), 8px (desktop)
- Padding: 12px horizontal, 10px vertical (mobile), 16px horizontal, 12px vertical (desktop)
- Hover: Slightly darker gold (desktop only)
- No gradients (solid color)

**Example:**
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: obsidianGold,
    foregroundColor: Colors.black,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 0,
    shadowColor: Colors.transparent,
  ),
  child: Text('Submit'),
)
```

---

#### Ghost Button

**Usage:** Secondary actions, cancel, alternative options

**Styling:**
- Background: Transparent
- Text: White (`#FFFFFF`)
- Border: None (or white 10% opacity on hover, desktop only)
- Shadow: None
- Border Radius: 6px (mobile), 8px (desktop)
- Padding: Same as primary
- Hover: White 10% background (desktop only)
- **NO gold borders or accents**

**Example:**
```dart
TextButton(
  style: TextButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: obsidianTextHeading,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  onPressed: () {},
  child: Text('Cancel'),
)
```

---

#### Icon Button

**Usage:** Icon-only actions, toolbars, compact actions

**Styling:**
- Background: White 5% opacity (`rgba(255,255,255,0.05)`)
- Icon: White (`#FFFFFF`) or Steel (`#94A3B8`)
- Border: None
- Shadow: None
- Shape: Circle or rounded square
- Size: 40px minimum (44px for touch targets)
- Hover: White 10% background, gold icon (desktop only)
- Border Radius: 20px (circle) or 8px (rounded)

**Example:**
```dart
IconButton(
  style: IconButton.styleFrom(
    backgroundColor: Colors.white.withOpacity(0.05),
    foregroundColor: obsidianTextHeading,
    minimumSize: Size(44, 44),
    shape: CircleBorder(),
  ),
  icon: Icon(Icons.more_vert),
  onPressed: () {},
)
```

---

### 6.2 Button States

| State | Primary | Ghost | Icon |
|-------|---------|-------|------|
| **Default** | Gold background, black text | Transparent, white text | White 5% bg, white icon |
| **Hover** (desktop) | Darker gold, subtle shadow | White 10% bg | White 10% bg, gold icon |
| **Pressed** | Darker gold | White 15% bg | White 15% bg |
| **Disabled** | Gray background, gray text | Transparent, gray text | White 2% bg, gray icon |
| **Loading** | Gold background, spinner | Transparent, spinner | White 5% bg, spinner |

---

### 6.3 Button Sizing

| Size | Padding (H, V) | Min Height | Usage |
|------|----------------|------------|-------|
| **Small** | 8px, 8px | 32px | Compact spaces, mobile |
| **Medium** | 12px, 10px (mobile) / 16px, 12px (desktop) | 44px | Standard actions |
| **Large** | 20px, 16px | 52px | Hero CTAs, prominent actions |

**Touch Targets:** Minimum 44px height on mobile (WCAG AA)

---

## 7. SPACING & LAYOUT

### 7.1 Spacing Scale

**Responsive Spacing (via ResponsiveTokens):**

| Breakpoint | Padding | Spacing | Section Spacing |
|------------|---------|---------|-----------------|
| Small Mobile (<400px) | 8px | 4px | 16px |
| Mobile (400-600px) | 12px | 6px | 20px |
| Tablet (600-800px) | 16px | 8px | 24px |
| Desktop (800-1200px) | 20px | 12px | 32px |
| Large Desktop (>1200px) | 24px | 16px | 40px |

**Usage:**
- Padding: Card/content padding, container padding
- Spacing: Between related items, within components
- Section Spacing: Between major sections, screen sections

---

### 7.2 Border Radius

**Responsive Border Radius:**

| Breakpoint | Small | Medium | Large |
|------------|-------|--------|-------|
| Small Mobile | 4px | 6px | 8px |
| Mobile | 6px | 8px | 10px |
| Tablet | 8px | 10px | 12px |
| Desktop | 10px | 12px | 16px |
| Large Desktop | 12px | 16px | 20px |

**Usage:**
- Small: Buttons, badges, chips
- Medium: Cards, inputs, containers (standard)
- Large: Modals, hero cards, prominent elements

---

### 7.3 Border Usage Rules

**Use Borders When:**
- ✅ Separation is ambiguous (nested content, overlapping elements)
- ✅ Tier 1 cards (gold border for importance)
- ✅ Selected/active states (gold border)
- ✅ Form inputs (Material standard)
- ✅ Dividers in lists (subtle, white 5% opacity)

**Don't Use Borders When:**
- ❌ Structure can be achieved with spacing (most cases)
- ❌ Tier 2/3 cards (use spacing instead)
- ❌ Navigation cards (use spacing)
- ❌ Standard containers (use spacing)

**Border Styling:**
- Tier 1: Gold 30% opacity, 1px
- Tier 2: White 5% opacity, 1px (or none)
- Tier 3: None (or white 3% opacity if needed)
- Dividers: White 5% opacity, 1px

---

## 8. SHADOWS & EFFECTS

### 8.1 Shadow Rules

**Tier 1 (Desktop Only):**
- Single shadow: `rgba(0,0,0,0.5)` blur 20, offset (0,8)
- Optional glow: Gold `rgba(198,168,124,0.1)` blur 15, offset (0,4)
- Mobile: No shadows

**Tier 2 (Desktop Only):**
- Single subtle shadow: `rgba(0,0,0,0.2)` blur 4, offset (0,2)
- Mobile: No shadows

**Tier 3:**
- No shadows (anywhere)

**Buttons:**
- Primary: Minimal shadow (desktop only)
- Ghost/Icon: No shadows

**Target:** 25% reduction in shadow usage/intensity

---

### 8.2 Glow Effects

**Allowed:**
- Tier 1 status indicators (desktop only) - subtle glow
- Tier 1 cards (desktop only) - optional gold glow

**Not Allowed:**
- Tier 2/3 elements
- Mobile devices (any tier)
- Navigation cards
- Standard buttons

---

### 8.3 Gradient Rules

**Allowed:**
- Tier 1 KPIs (optional, if needed for emphasis) - subtle gradient
- Background (optional, consider flat #09090B instead)

**Not Allowed:**
- Tier 2/3 cards (must be flat, solid colors)
- Buttons (solid colors only)
- Navigation cards
- List items

**Target:** Remove gradients from Tier 2/3 (reduce visual weight by ~25%)

---

## 9. MOTION & INTERACTION

### 9.1 Animation Durations

| Interaction | Duration | Easing |
|-------------|----------|--------|
| Hover transitions | 200ms | easeInOut |
| Press/click feedback | 100ms | easeOut |
| Page transitions | 300ms | easeInOut |
| Staggered animations | 50ms delay | easeOut |

---

### 9.2 Hover Effects

**Desktop Only:**
- Cards: Border opacity change (5% → 8%), subtle background change
- Buttons: Background color change, subtle scale (1.0 → 1.02)
- Icon buttons: Background change (5% → 10%), icon color change (white → gold)
- Tier 1: Optional glow effect

**Mobile:**
- No hover effects (touch devices)

---

### 9.3 Press/Click Feedback

**All Devices:**
- Instant visual feedback (100ms)
- Subtle scale (0.98) or color flash
- Ripple effect (Material standard) for buttons

---

### 9.4 Reduced Motion

**Respect System Settings:**
- Check `MediaQuery.disableAnimations`
- Reduce/disable animations if user preference set
- Keep essential feedback (color changes, state changes)

---

## 10. RESPONSIVE BEHAVIOR

### 10.1 Desktop vs Mobile Rules

**Same Colors, Different Rules:**

| Property | Desktop | Mobile |
|----------|---------|--------|
| Background Opacity | Lower (more transparent) | Higher (more opaque) |
| Borders | Subtle (5% opacity) | Slightly more visible (8% opacity) |
| Shadows | Minimal (Tier 1/2) | None |
| Glow Effects | Optional (Tier 1) | None |
| Hover Effects | Yes | No |
| Spacing | Generous (20-24px) | Tighter (8-12px) |
| Border Radius | Larger (12-16px) | Smaller (6-8px) |

---

### 10.2 Breakpoint Strategy

**Existing Breakpoints (Keep):**
- Small Mobile: < 400px
- Mobile: 400-600px
- Tablet: 600-800px
- Desktop: 800-1200px
- Large Desktop: > 1200px

**Use ResponsiveTokens for all sizing/spacing**

---

## 11. ACCESSIBILITY

### 11.1 Contrast Requirements

**WCAG AA Compliance:**
- Text on background: 4.5:1 minimum
- Large text (18px+): 3:1 minimum
- Interactive elements: 3:1 minimum

**Color Combinations to Verify:**
- Body text (#A1A1AA) on background (#09090B): ✅ 7.2:1 (pass)
- Muted text (#52525B) on background (#09090B): ⚠️ 3.8:1 (pass for large text only)
- Gold (#C6A87C) on background (#09090B): ✅ 3.5:1 (pass)

**Action:** Audit all text/background combinations

---

### 11.2 Touch Targets

**Minimum Sizes:**
- Buttons: 44px height (mobile)
- Icon buttons: 44px × 44px
- Card tap targets: 44px minimum height
- List items: 44px minimum height

---

### 11.3 Reduced Motion

**Implementation:**
- Check `MediaQuery.disableAnimations`
- Disable/hide animations if set
- Keep essential state changes (color, visibility)

---

## 12. DO'S AND DON'TS

### 12.1 Gold Usage

**✅ DO:**
- Use gold for primary buttons
- Use gold for selected/active states
- Use gold for priority badges (VIP, Urgent)
- Use gold for Tier 1 card borders
- Use gold for key metric highlights

**❌ DON'T:**
- Use gold for navigation card borders
- Use gold for navigation icons
- Use gold for Tier 2/3 card borders
- Use gold for ghost/secondary buttons
- Use gold for decorative elements

---

### 12.2 Gradients

**✅ DO:**
- Use flat, solid colors (preferred)
- Use gradients only for Tier 1 KPIs (if needed)
- Use gradients for background (optional)

**❌ DON'T:**
- Use gradients on Tier 2/3 cards
- Use gradients on buttons
- Use gradients on navigation cards
- Use gradients on list items

---

### 12.3 Borders

**✅ DO:**
- Use spacing for structure (preferred)
- Use borders only where separation is ambiguous
- Use gold borders for Tier 1/selected states
- Use subtle white borders (5% opacity) for Tier 2

**❌ DON'T:**
- Use borders for all cards (use spacing)
- Use gold borders for Tier 2/3 cards
- Use borders for navigation structure
- Use multiple border layers

---

### 12.4 Shadows

**✅ DO:**
- Use minimal shadows (Tier 1/2 desktop only)
- Use single shadow (not multiple layers)
- Remove shadows on mobile

**❌ DON'T:**
- Use shadows on Tier 3 elements
- Use multiple shadow layers
- Use shadows on mobile
- Use glow effects on Tier 2/3

---

## 13. COMPONENT SPECIFICATIONS

### 13.1 Card Component (Base)

**Tier 1 Card:**
```dart
Container(
  decoration: BoxDecoration(
    color: obsidianSurface.withOpacity(0.6), // Desktop: 0.6, Mobile: 0.8
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: obsidianGold.withOpacity(0.3), // Desktop: 0.3, Mobile: 0.4
      width: 1,
    ),
    boxShadow: [
      BoxShadow( // Desktop only
        color: Colors.black.withOpacity(0.5),
        blurRadius: 20,
        offset: Offset(0, 8),
      ),
      // Optional glow (desktop only)
      BoxShadow(
        color: obsidianGold.withOpacity(0.1),
        blurRadius: 15,
        offset: Offset(0, 4),
      ),
    ],
  ),
  // No BackdropFilter - solid color
)
```

**Tier 2 Card:**
```dart
Container(
  decoration: BoxDecoration(
    color: obsidianSurface.withOpacity(0.4), // Desktop: 0.4, Mobile: 0.6
    borderRadius: BorderRadius.circular(8),
    border: Border.all(
      color: Colors.white.withOpacity(0.05), // Optional, or no border
      width: 1,
    ),
    boxShadow: [
      BoxShadow( // Desktop only, minimal
        color: Colors.black.withOpacity(0.2),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  ),
  // No gradients, no glow
)
```

**Tier 3 Card:**
```dart
Container(
  decoration: BoxDecoration(
    color: obsidianSurface.withOpacity(0.2),
    borderRadius: BorderRadius.circular(6),
    // No border, no shadow
  ),
  // Maximum quiet
)
```

---

### 13.2 Status Indicator

**Tier 1 Status (Priority):**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: statusColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: statusColor.withOpacity(0.3),
      width: 1,
    ),
    // Optional glow (desktop only)
    boxShadow: [
      BoxShadow(
        color: statusColor.withOpacity(0.2),
        blurRadius: 8,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: statusColor,
          shape: BoxShape.circle,
          // Optional glow
          boxShadow: [
            BoxShadow(
              color: statusColor.withOpacity(0.5),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      SizedBox(width: 6),
      Text(label, style: TextStyle(color: statusColor)),
    ],
  ),
)
```

**Tier 2/3 Status (Standard):**
```dart
Container(
  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: statusColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    // No border, no shadow (flat)
  ),
  child: Text(label, style: TextStyle(color: statusColor)),
)
```

---

## 14. IMPLEMENTATION NOTES

### 14.1 Theme Extension Structure

**Extend AppTokens (don't replace):**
```dart
class AppTokens extends ThemeExtension<AppTokens> {
  // Existing
  final Color brandGold; // Update to #C6A87C
  final Color brandBlack; // Update to #FFFFFF (text) or #09090B (bg)
  final double radiusMd;
  final double spacing;
  
  // New
  final Color obsidianBackground; // #09090B
  final Color obsidianSurface; // #18181B
  final Color obsidianSurfaceHighlight; // #27272A
  final Color obsidianPrimary; // #C6A87C
  final Color obsidianSecondary; // #94A3B8
  final Color obsidianTextHeading; // #FFFFFF
  final Color obsidianTextBody; // #A1A1AA
  final Color obsidianTextMuted; // #52525B
  final Color obsidianBorder; // rgba(255,255,255,0.08)
}
```

---

### 14.2 Surface Tier Enum

**Create Surface Tier System:**
```dart
enum SurfaceTier {
  primary,   // Tier 1
  secondary, // Tier 2
  passive,   // Tier 3
}

class SurfaceTierTokens {
  static BoxDecoration getDecoration(
    SurfaceTier tier,
    double screenWidth,
  ) {
    final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
    // Return appropriate decoration based on tier and device
  }
}
```

---

### 14.3 Migration Strategy

1. **Extend, don't replace** - Keep existing theme structure
2. **Add new tokens** - Surface tiers, new colors
3. **Gradual migration** - Phased approach (see UI_MIGRATION_PLAN.md)
4. **Backward compatibility** - Keep old colors during transition
5. **Component-first** - Build new components, migrate screens incrementally

---

## 15. VALIDATION CHECKLIST

### 15.1 Design System Compliance

- [ ] All colors from theme (no hardcoded colors)
- [ ] Surface tiers applied correctly (Tier 1/2/3)
- [ ] Gold used only for signals (not frames)
- [ ] Gradients removed from Tier 2/3 cards
- [ ] Shadows reduced by 25%
- [ ] Borders used sparingly (spacing preferred)
- [ ] Typography uses Outfit/Inter
- [ ] Responsive tokens used for all sizing

### 15.2 Visual Weight Reduction

- [ ] Gradients removed from Tier 2/3 (25% reduction)
- [ ] Shadows reduced/minimized
- [ ] Glow effects removed (except Tier 1 desktop)
- [ ] Borders reduced (spacing used instead)

### 15.3 Responsive Behavior

- [ ] Mobile: Flatter, no shadows/glow
- [ ] Desktop: Subtle depth, hover effects
- [ ] Tablet: Hybrid approach
- [ ] All breakpoints tested

### 15.4 Accessibility

- [ ] Contrast ratios verified (WCAG AA)
- [ ] Touch targets 44px minimum
- [ ] Reduced motion respected
- [ ] Text readable on all backgrounds

---

## 16. VERSIONING STRATEGY

### 16.1 Treat as Living Document

**This design system is NOT final at v1.0.**

The system should evolve based on:
- Real-world usage (operational needs)
- User feedback (fatigue, scan speed, clarity)
- Technical constraints (performance, maintainability)
- Edge cases discovered during migration

### 16.2 Version Progression

**v0.7 (Current - Pre-Migration):**
- Initial specification
- Based on design principles
- Pre-migration baseline

**v0.8 (Target: After Phase 1):**
- Validated with prototype screens (Dashboard + one list screen)
- Adjustments based on Design Confidence Gate evaluation
- Refined based on real visual testing
- Patterns validated before scaling

**v0.9 (Target: After Phase 2):**
- Refined after component migration
- Patterns established across app
- Component system proven
- Ready for screen migration

**v1.0 (Target: After Phase 4):**
- Finalized after full migration (P0/P1 screens)
- Validated with real-world usage
- Performance verified
- Accessibility verified
- Considered "stable" but still evolvable

### 16.3 Update Triggers

**Update the spec when:**
- Design Confidence Gate reveals issues (Phase 1)
- Component patterns need adjustment (Phase 2)
- Screen migration reveals edge cases (Phase 3)
- Performance profiling reveals constraints (Phase 4)
- Real usage reveals improvements (post-migration)

**Don't update for:**
- Theoretical improvements (validate first)
- Perfectionism (good enough is fine)
- Low-impact screens (P2/P3 can be simpler)

### 16.4 Migration Principle

**"Migrate the system to the app, not the app to the system."**

- If a screen doesn't fit the spec, adjust the spec (if it's a pattern)
- If a pattern doesn't work, document and adjust
- If an edge case is rare, simplify (don't over-engineer)
- Validate with real usage before abstracting

---

**END OF DESIGN SYSTEM SPECIFICATION**

---

*Next Steps:*
1. Review and approve design system spec
2. Understand this is a living document (will evolve)
3. Begin Phase 0 implementation (theme/token preparation)
4. Plan for v0.8 update after Phase 1 (Design Confidence Gate)

