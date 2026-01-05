# UI Migration Plan: Obsidian Luxury Ops
## Phased Theme & Component Migration Strategy

**Version:** 1.0  
**Date:** 2025-01-XX  
**Status:** Migration Plan  
**Estimated Duration:** 4-6 weeks  
**Risk Level:** Medium (phased approach minimizes risk)

---

## EXECUTIVE SUMMARY

This plan outlines a phased migration from the current theme system to the new "Obsidian Luxury Ops" design system. The migration follows a **component-first, screen-second** approach to minimize risk and enable incremental testing.

**Key Principles:**
- ✅ Extend existing theme system (don't replace)
- ✅ Phased rollout with clear acceptance criteria
- ✅ No business logic changes
- ✅ Backward compatibility during transition
- ✅ Performance-conscious (no BackdropFilter in lists)

**Total Estimated Effort:** 25-37 days (5-7 weeks)

---

## MIGRATION OVERVIEW

### Core Principle

**"Do not migrate the app to the system. Migrate the system to the app."**

This means:
- ✅ Validate visually before abstracting
- ✅ Stop when clarity is achieved
- ✅ Leave low-impact screens "good enough"
- ✅ Protect existing strengths (responsive breakpoints, layout logic, functional clarity)
- ✅ Refine, don't re-invent

### Phases

1. **Phase 0: Preparation** (2-3 days) - Theme tokens, no screen changes
2. **Phase 1: Prototype** (5-7 days) - One reference screen (Dashboard) + one list screen + **Design Confidence Gate**
3. **Phase 2: Core Components** (7-10 days) - Shared cards + buttons across app
4. **Phase 3: Remaining Screens** (10-15 days) - Screen-by-screen migration (P0/P1 priority)
5. **Phase 4: Polish & QA** (5-7 days) - Testing, contrast audit, performance profiling

---

## PHASE 0: PREPARATION

**Duration:** 2-3 days  
**Risk:** Low  
**Goal:** Set up theme infrastructure without changing any screens

### Objectives

1. Extend `AppTokens` with new Obsidian colors
2. Create `SurfaceTier` enum and tier system
3. Update `ThemeData` with new colors (keep old for compatibility)
4. Create surface tier token system
5. No visual changes (screens unchanged)

### Files to Modify

1. `lib/app/theme_tokens.dart`
   - Extend `AppTokens` with new colors
   - Add surface tier support
   - Keep existing fields (backward compatibility)

2. `lib/app/theme.dart`
   - Update `ChoiceLuxTheme` with new color constants
   - Update `ThemeData` colorScheme with new colors
   - Add TextTheme with Outfit/Inter fonts
   - Keep old colors (dual system during transition)

3. `lib/app/theme_helpers.dart`
   - Add context extensions for new tokens
   - Add surface tier helpers

4. **NEW:** `lib/design_system/surface_tier_tokens.dart`
   - Create `SurfaceTier` enum
   - Create `SurfaceTierTokens` class with decoration methods
   - Desktop vs mobile differentiation logic

### Implementation Details

**AppTokens Extension:**
```dart
class AppTokens extends ThemeExtension<AppTokens> {
  // Existing (keep for compatibility)
  final Color brandGold;
  final Color brandBlack;
  final double radiusMd;
  final double spacing;
  
  // New Obsidian colors
  final Color obsidianBackground;
  final Color obsidianSurface;
  final Color obsidianSurfaceHighlight;
  final Color obsidianPrimary;
  final Color obsidianSecondary;
  final Color obsidianTextHeading;
  final Color obsidianTextBody;
  final Color obsidianTextMuted;
  final Color obsidianBorder;
}
```

**SurfaceTier System:**
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
    // Returns appropriate decoration based on tier and device
  }
}
```

### Acceptance Criteria

- [ ] AppTokens extended with new colors
- [ ] SurfaceTier enum and tokens created
- [ ] ThemeData updated (new colors available)
- [ ] TextTheme configured (Outfit/Inter)
- [ ] All existing screens still work (no visual changes)
- [ ] No runtime errors
- [ ] Backward compatibility maintained

### Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing code | High | Keep old tokens, extend (don't replace) |
| Theme extension conflicts | Medium | Test thoroughly, maintain backward compatibility |
| Missing color mappings | Low | Comprehensive color audit in Phase 0 |

### Rollback Strategy

- Revert changes to `theme_tokens.dart` and `theme.dart`
- No screen changes, so rollback is safe
- Git branch: `feature/obsidian-phase-0-prep`

### QA Checklist

- [ ] App compiles without errors
- [ ] All screens render correctly (no visual changes expected)
- [ ] Theme extension system works
- [ ] New tokens accessible via context extensions
- [ ] No performance regressions

---

## PHASE 1: PROTOTYPE

**Duration:** 5-7 days  
**Risk:** Medium  
**Goal:** Build one reference screen (Dashboard) + one list screen (Clients or Jobs) using new system

### Objectives

1. Migrate Dashboard screen to new system
2. Migrate one list screen (Clients or Jobs) to new system
3. Create reference implementations for Tier 1/2/3 usage
4. Validate design system in real usage
5. Establish patterns for Phase 2

### Screen Selection Rationale

**Dashboard Screen:**
- ✅ Central hub (high visibility)
- ✅ Mix of card types (navigation cards)
- ✅ Good test case for Tier 2 cards
- ✅ Limited complexity (manageable)
- ✅ Reference implementation for other screens

**Clients Screen (Recommended) OR Jobs Screen:**
- ✅ List/grid layout (common pattern)
- ✅ Card-based (ClientCard or JobCard)
- ✅ Good test case for Tier 2 list items
- ✅ Filters/search (common pattern)
- ✅ Reference for other list screens

### Files to Modify

1. **Dashboard Screen:**
   - `lib/features/dashboard/dashboard_screen.dart`
   - `lib/shared/widgets/dashboard_card.dart` (create Tier 2 variant)

2. **List Screen (Clients recommended):**
   - `lib/features/clients/clients_screen.dart`
   - `lib/features/clients/widgets/client_card.dart` (migrate to Tier 2)

3. **Shared Components:**
   - Create `lib/design_system/obsidian_card.dart` (base card widget)
   - Update button system (if needed)

### Implementation Steps

1. **Create ObsidianCard Base Widget**
   - Supports SurfaceTier (Tier 1/2/3)
   - Handles desktop vs mobile styling
   - No gradients (flat colors)
   - Conditional shadows/glow

2. **Migrate DashboardCard**
   - Convert to Tier 2 styling
   - Remove gradients
   - Remove gold borders/icons (use white/silver)
   - Remove glow effects
   - Use ObsidianCard base

3. **Migrate Dashboard Screen**
   - Update background (flat #09090B or gradient removal)
   - Update DashboardCard usage
   - Test responsive behavior

4. **Migrate ClientCard (or JobCard)**
   - Convert to Tier 2 styling
   - Remove gradients
   - Remove gold borders (keep only for selection)
   - Use ObsidianCard base
   - Update status badges (remove shadows)

5. **Migrate Clients Screen (or Jobs Screen)**
   - Update ClientCard usage
   - Update filters/search styling
   - Test responsive behavior
   - Test performance (large lists)

### Acceptance Criteria

- [ ] Dashboard screen uses new theme (Tier 2 cards)
- [ ] List screen uses new theme (Tier 2 cards)
- [ ] No gradients on Tier 2 cards
- [ ] No gold borders on navigation/list cards
- [ ] Responsive behavior works (mobile/tablet/desktop)
- [ ] Performance acceptable (no lag in lists)
- [ ] Visual hierarchy clear (tier distinction)
- [ ] No runtime errors
- [ ] Screenshots captured (before/after)

### Design Confidence Gate (CRITICAL PAUSE)

**After Phase 1 completion, STOP and evaluate:**

Before proceeding to Phase 2, explicitly answer these questions:

1. **Is scan speed better?**
   - Can users find information faster?
   - Is hierarchy clearer?
   - Is information easier to parse?

2. **Is fatigue reduced?**
   - Does the screen feel calmer?
   - Less visual noise?
   - Easier on the eyes for long sessions?

3. **Does this feel calmer in daily use?**
   - Professional appearance?
   - Appropriate for operational use?
   - Better than before?

**If any answer is "No" or "Uncertain":**
- **STOP Phase 2**
- Review design system spec
- Adjust styling/rules as needed
- Update DESIGN_SYSTEM_OBSIDIAN.md (version to 0.8)
- Re-test Phase 1 screens
- Only proceed when confidence is high

**If all answers are "Yes":**
- Document what worked
- Update DESIGN_SYSTEM_OBSIDIAN.md (version to 0.8)
- Proceed to Phase 2

**Key Principle:** Validate visually before abstracting. Don't migrate the app to the system—migrate the system to the app.

### Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Visual regressions | High | Screenshot comparison, user review |
| Performance issues | Medium | Profile on mid-range device, optimize if needed |
| Breaking changes | Medium | Test thoroughly, maintain backward compatibility where possible |
| Design system gaps | Medium | Document gaps, create workarounds, update spec |

### Rollback Strategy

- Revert changes to Dashboard and Clients/Jobs screens
- Keep Phase 0 changes (theme tokens)
- Git branch: `feature/obsidian-phase-1-prototype`

### QA Checklist

**Visual:**
- [ ] Dashboard looks correct (Tier 2 styling)
- [ ] List screen looks correct (Tier 2 styling)
- [ ] No gradients on cards
- [ ] No gold borders on navigation/list cards
- [ ] Gold used only for signals (if any)
- [ ] Typography correct (Outfit/Inter)
- [ ] Spacing appropriate

**Functional:**
- [ ] All interactions work (taps, navigation)
- [ ] Filters/search work
- [ ] Cards display correctly
- [ ] No layout breaks

**Responsive:**
- [ ] Mobile (< 600px): Flat, no shadows, appropriate spacing
- [ ] Tablet (600-800px): Hybrid styling
- [ ] Desktop (> 800px): Subtle depth, hover effects
- [ ] Large desktop (> 1200px): Proper max-width constraints

**Performance:**
- [ ] No lag when scrolling lists
- [ ] No janky animations
- [ ] Acceptable frame rate (50-60fps)
- [ ] Memory usage acceptable

**Accessibility:**
- [ ] Touch targets 44px minimum
- [ ] Text readable (contrast)
- [ ] Screen reader compatible

---

## PHASE 2: CORE COMPONENTS

**Duration:** 7-10 days  
**Risk:** Medium-High  
**Goal:** Migrate shared card widgets + button system across the app

### Objectives

1. Migrate all card widgets to ObsidianCard base
2. Unify button system (Primary, Ghost, Icon variants)
3. Standardize status indicators (tier-based)
4. Update shared widgets (AppBar, Drawer, etc.)
5. Ensure consistency across app

### Component Migration Order

**Priority 1 (High Impact):**
1. `DashboardCard` (already done in Phase 1)
2. `ClientCard` (already done in Phase 1) OR `JobCard`
3. `JobCard` / `JobListCard` (if not done in Phase 1)
4. `QuoteCard`
5. `VehicleCard`

**Priority 2 (Medium Impact):**
6. `UserCard`
7. `AgentCard`
8. `NotificationCard` (Tier 3 - flatter)
9. `InsightsCard` (Tier 1 - may need gold accents)

**Priority 3 (Specialized):**
10. `JobMonitoringCard` (Tier 1)
11. `DriverActivityCard` (Tier 3)

### Button System Migration

**Create Unified Button System:**
1. Create `ObsidianButton` widget (Primary, Ghost, Icon variants)
2. Migrate `LuxuryButton` usage
3. Standardize custom button implementations
4. Update action buttons (VoucherActionButtons, InvoiceActionButtons)

**Button Variants:**
- Primary: Solid gold, black text
- Ghost: Transparent, white text, hover bg-white/10
- Icon: Round/square, bg-white/5, hover bg-white/10

### Status Indicator Migration

**Standardize Status Indicators:**
1. Update `StatusPill` with tier support
2. Migrate hardcoded status colors to theme
3. Create tier-based status variants (Tier 1: glow, Tier 2/3: flat)
4. Update status badges in cards

### Shared Widgets Migration

**Update Shared Components:**
1. `LuxuryAppBar` - New background color (#09090B)
2. `LuxuryDrawer` - Tier 3 styling (quiet zone)
3. `SystemSafeScaffold` - New background color
4. `CompactMetricTile` - Tier 1 styling for KPIs

### Files to Modify

**Card Widgets (12 files):**
- All card widget files (see Component Inventory in UI_AUDIT.md)

**Button System:**
- `lib/shared/widgets/luxury_button.dart` (replace with ObsidianButton)
- `lib/features/vouchers/widgets/voucher_action_buttons.dart`
- `lib/features/invoices/widgets/invoice_action_buttons.dart`
- Custom button implementations in cards

**Status Indicators:**
- `lib/shared/widgets/status_pill.dart`
- Status badge implementations in cards

**Shared Widgets:**
- `lib/shared/widgets/luxury_app_bar.dart`
- `lib/shared/widgets/luxury_drawer.dart`
- `lib/shared/widgets/system_safe_scaffold.dart`
- `lib/shared/widgets/compact_metric_tile.dart`

### Implementation Steps

1. **Create ObsidianCard Base (if not done in Phase 1)**
   - Tier 1/2/3 support
   - Desktop vs mobile styling
   - Hover effects (desktop only)

2. **Migrate Card Widgets (one by one)**
   - Convert to use ObsidianCard base
   - Remove gradients
   - Remove gold borders (keep only for selection/Tier 1)
   - Update icons (white/silver instead of gold)
   - Test each card individually

3. **Create Unified Button System**
   - Build ObsidianButton widget
   - Primary, Ghost, Icon variants
   - Desktop vs mobile styling
   - Replace LuxuryButton

4. **Migrate Button Usage**
   - Update LuxuryButton calls
   - Update custom button implementations
   - Standardize action buttons

5. **Standardize Status Indicators**
   - Update StatusPill with tier support
   - Migrate hardcoded colors
   - Update status badges in cards

6. **Update Shared Widgets**
   - AppBar, Drawer, Scaffold background colors
   - Tier 3 styling for Drawer (quiet zone)

### Acceptance Criteria

- [ ] All card widgets use ObsidianCard base
- [ ] No gradients on Tier 2/3 cards
- [ ] Gold borders removed from Tier 2 cards (keep only selection/Tier 1)
- [ ] Button system unified (Primary, Ghost, Icon)
- [ ] Status indicators standardized (tier-based)
- [ ] Shared widgets updated (AppBar, Drawer, etc.)
- [ ] Hardcoded colors removed (migrated to theme)
- [ ] All screens compile (may have visual inconsistencies)
- [ ] No runtime errors

### Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Breaking existing screens | High | Test each component, maintain backward compatibility |
| Inconsistent styling | Medium | Use base components (ObsidianCard), enforce via code review |
| Performance regression | Medium | Profile after each major component migration |
| Button system complexity | Medium | Start with simple variants, extend as needed |

### Rollback Strategy

- Revert component changes (cards, buttons, status indicators)
- Keep Phase 0/1 changes (theme, prototype screens)
- Git branch: `feature/obsidian-phase-2-components`

### QA Checklist

**Components:**
- [ ] All card widgets render correctly
- [ ] Tier styling applied correctly (Tier 1/2/3)
- [ ] No gradients on Tier 2/3
- [ ] Gold usage correct (signals only)
- [ ] Button variants work (Primary, Ghost, Icon)
- [ ] Status indicators styled correctly (tier-based)
- [ ] Shared widgets updated (AppBar, Drawer)

**Consistency:**
- [ ] Similar components look consistent
- [ ] Tier assignment consistent across app
- [ ] Button styling consistent
- [ ] Status indicator styling consistent

**Performance:**
- [ ] No performance regression
- [ ] Lists scroll smoothly
- [ ] No janky animations

---

## PHASE 3: REMAINING SCREENS

**Duration:** 10-15 days  
**Risk:** Medium  
**Goal:** Migrate all remaining screens to new system

### Screen Migration Strategy

**Batch Similar Screens:**
- Fix all "List" screens together (similar patterns)
- Fix all "Detail" screens together (similar patterns)
- Fix all "Form" screens together (similar patterns)
- Fix all "Auth" screens together (simple, low risk)

### Screen Migration Order (Priority-Based)

**P0 - Daily, High-Impact (Required for Initial Completion):**
1. Dashboard Screen ✅ (done in Phase 1)
2. Jobs Screen (list screen, high usage)
3. Clients Screen ✅ (done in Phase 1)
4. Client Detail Screen (detail screen, complex)
5. Job Summary Screen (detail screen, complex)
6. Job Progress Screen (very complex, needs careful migration)
7. Notification List Screen (list screen, Tier 3 cards)

**P1 - Regular (Should Migrate):**
8. Quotes Screen (list screen, similar to Clients)
9. Vehicles Screen (list screen, similar pattern)
10. Create Job Screen (form screen, complex)
11. Create/Edit Client Screens (form screens)
12. Create Quote Screen (form screen, complex)
13. Quote Details Screen (detail screen)
14. Trip Management Screen (complex interactions)
15. Insights Screen (complex, custom styling)
16. Invoices Screen (reuses JobListCard)
17. Vouchers Screen (reuses JobListCard)
18. User Profile Screen (form screen)

**P2 - Occasional (Nice to Have, Can Wait):**
19. Edit Job Screen
20. User Detail Screen
21. Vehicle Editor Screen
22. Quote Transport Details Screen
23. Agent Add/Edit Screens
24. Settings/Preferences Screens
25. Insights Jobs List Screen
26. Inactive Clients Screen

**P3 - Rare / Admin / Edge Cases (Low Priority, Leave "Good Enough"):**
27. Auth screens (minimal changes needed)
28. PDF Viewer screens
29. Any other edge cases

**Migration Strategy:**
- **Initial completion:** P0 screens only (7 screens, 2 done in Phase 1, 5 remaining)
- **Full migration:** P0 + P1 screens (18 screens total)
- **P2/P3:** Migrate only if time allows, or leave "good enough"

### Files to Modify

**List Screens (5 screens):**
- `lib/features/jobs/jobs_screen.dart`
- `lib/features/quotes/quotes_screen.dart`
- `lib/features/vehicles/vehicles_screen.dart`
- `lib/features/users/users_screen.dart`
- `lib/features/invoices/invoices_screen.dart`
- `lib/features/vouchers/vouchers_screen.dart`
- `lib/features/notifications/screens/notification_list_screen.dart`

**Detail Screens (10+ screens):**
- All detail screen files (see UI_AUDIT.md)

**Form Screens (10+ screens):**
- All form/edit screen files (see UI_AUDIT.md)

**Auth Screens (5 screens):**
- Auth screen files (minimal changes)

### Implementation Steps (Per Screen)

1. **Audit Screen**
   - Identify components used
   - Identify hardcoded colors
   - Identify styling issues
   - Assign tiers to components

2. **Update Background**
   - Update scaffold background (#09090B)
   - Remove/update gradients
   - Update background patterns (if needed)

3. **Update Components**
   - Cards already migrated (Phase 2)
   - Buttons already migrated (Phase 2)
   - Status indicators already migrated (Phase 2)
   - Update any custom styling

4. **Remove Hardcoded Colors**
   - Replace Colors.white/black with theme colors
   - Replace hardcoded status colors with theme
   - Use theme text colors

5. **Update Typography**
   - Use TextTheme (Outfit/Inter)
   - Use ResponsiveTokens.getFontSize()
   - Remove hardcoded font sizes

6. **Test Responsive**
   - Mobile, tablet, desktop
   - Verify tier styling (desktop vs mobile)
   - Verify hover effects (desktop only)

7. **Test Functionality**
   - All interactions work
   - Navigation works
   - Forms work
   - No layout breaks

### Acceptance Criteria (Per Screen)

- [ ] Screen uses new theme colors
- [ ] No hardcoded colors (all from theme)
- [ ] Components use new system (cards, buttons, status)
- [ ] Tier styling applied correctly
- [ ] Typography uses TextTheme
- [ ] Responsive behavior correct (mobile/tablet/desktop)
- [ ] All functionality works
- [ ] No visual regressions
- [ ] Performance acceptable

### Batch Acceptance Criteria

- [ ] All screens in batch migrated
- [ ] Consistent styling across batch
- [ ] No runtime errors
- [ ] Screenshots captured (before/after)

### Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Screen-specific issues | Medium | Test each screen individually, document issues |
| Complex screen complexity | High | Break into smaller tasks, test incrementally |
| Visual inconsistencies | Medium | Use base components, code review |
| Performance issues | Medium | Profile complex screens, optimize if needed |

### Rollback Strategy

- Revert screen changes (per screen or batch)
- Keep Phase 0/1/2 changes (theme, components)
- Git branch: `feature/obsidian-phase-3-screens`

### QA Checklist (Per Screen)

**Visual:**
- [ ] Colors from theme (no hardcoded)
- [ ] Tier styling correct
- [ ] Typography correct (Outfit/Inter)
- [ ] Spacing appropriate
- [ ] No gradients on Tier 2/3
- [ ] Gold usage correct (signals only)

**Functional:**
- [ ] All interactions work
- [ ] Navigation works
- [ ] Forms work (if applicable)
- [ ] No layout breaks

**Responsive:**
- [ ] Mobile: Flat, no shadows, appropriate spacing
- [ ] Tablet: Hybrid styling
- [ ] Desktop: Subtle depth, hover effects

**Performance:**
- [ ] No lag
- [ ] Acceptable frame rate
- [ ] Memory usage acceptable

---

## PHASE 4: POLISH & QA

**Duration:** 5-7 days  
**Risk:** Low  
**Goal:** Final testing, contrast audit, performance profiling, documentation

### Objectives

1. Comprehensive testing (all screens, all breakpoints)
2. Contrast audit (WCAG AA compliance)
3. Performance profiling (identify bottlenecks)
4. Visual regression testing (screenshot comparison)
5. Documentation update
6. Final polish (fix issues found)

### Testing Tasks

**Visual Testing:**
1. Screenshot comparison (before/after)
2. Visual consistency audit
3. Tier assignment verification
4. Gold usage verification
5. Gradient removal verification
6. Shadow reduction verification

**Functional Testing:**
1. All screens tested (35 screens)
2. All interactions tested
3. Navigation tested
4. Forms tested
5. Edge cases tested

**Responsive Testing:**
1. Small mobile (< 400px)
2. Mobile (400-600px)
3. Tablet (600-800px)
4. Desktop (800-1200px)
5. Large desktop (> 1200px)
6. Portrait/landscape orientations

**Accessibility Testing:**
1. Contrast audit (all text/background combinations)
2. Touch target verification (44px minimum)
3. Screen reader testing
4. Reduced motion testing

**Performance Testing:**
1. Profile on mid-range Android device
2. Profile on iOS device
3. Profile on desktop browser
4. Memory usage profiling
5. Frame rate monitoring (target: 50-60fps)
6. List scrolling performance (100+ items)

### Files to Review/Update

**Documentation:**
- Update design system documentation
- Update component documentation
- Create migration guide (for future changes)

**Code:**
- Fix any issues found during testing
- Optimize performance bottlenecks
- Remove any remaining hardcoded colors
- Clean up unused code

### Acceptance Criteria

- [ ] All screens tested and working
- [ ] Contrast audit passed (WCAG AA)
- [ ] Performance acceptable (50-60fps, no lag)
- [ ] Visual consistency verified
- [ ] No runtime errors
- [ ] No visual regressions
- [ ] Documentation updated
- [ ] Ready for production

### Risks & Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Contrast issues | High | Comprehensive audit, fix all issues |
| Performance issues | Medium | Profile, optimize, retest |
| Visual inconsistencies | Medium | Visual audit, fix inconsistencies |
| Missing edge cases | Low | Comprehensive testing, user feedback |

### Rollback Strategy

- Fix issues found (prefer fixes over rollback)
- If major issues: Rollback to previous phase
- Git branch: `feature/obsidian-phase-4-polish`

### QA Checklist

**Visual:**
- [ ] All screens look correct
- [ ] Tier styling consistent
- [ ] Gold usage correct
- [ ] No gradients on Tier 2/3
- [ ] Shadows reduced
- [ ] Typography consistent
- [ ] Spacing appropriate

**Functional:**
- [ ] All screens work
- [ ] All interactions work
- [ ] No runtime errors
- [ ] No layout breaks

**Responsive:**
- [ ] All breakpoints tested
- [ ] Mobile: Flat, appropriate
- [ ] Desktop: Subtle depth, hover effects
- [ ] Tablet: Hybrid approach

**Accessibility:**
- [ ] Contrast ratios pass (WCAG AA)
- [ ] Touch targets 44px minimum
- [ ] Screen reader compatible
- [ ] Reduced motion respected

**Performance:**
- [ ] Frame rate 50-60fps
- [ ] No lag in lists
- [ ] Memory usage acceptable
- [ ] No performance regressions

**Documentation:**
- [ ] Design system documented
- [ ] Components documented
- [ ] Migration guide created
- [ ] Code comments updated

---

## ROLLBACK STRATEGIES

### Phase-Level Rollback

Each phase maintains backward compatibility where possible. Rollback strategy per phase:

**Phase 0:**
- Revert theme token changes
- Safe (no screen changes)

**Phase 1:**
- Revert prototype screen changes
- Keep Phase 0 (theme tokens)

**Phase 2:**
- Revert component changes
- Keep Phase 0/1 (theme, prototype)

**Phase 3:**
- Revert screen changes (per screen or batch)
- Keep Phase 0/1/2 (theme, components)

**Phase 4:**
- Fix issues (prefer fixes)
- Rollback only if major issues

### Feature Flag Strategy (Optional)

Consider feature flags for gradual rollout:

```dart
// Optional: Feature flag for new theme
final useObsidianTheme = true; // or from config

ThemeData getTheme() {
  if (useObsidianTheme) {
    return ChoiceLuxTheme.obsidianTheme;
  }
  return ChoiceLuxTheme.darkTheme; // Old theme
}
```

**Benefits:**
- Gradual rollout
- A/B testing
- Easy rollback

**Drawbacks:**
- Maintenance overhead
- Code complexity

**Recommendation:** Not required for this migration (phased approach is sufficient)

---

## PERFORMANCE CONSTRAINTS

### Hard Constraints

1. **No BackdropFilter in scrollable lists/grids**
   - ✅ Already compliant (only auth screens use BackdropFilter)
   - ✅ No changes needed

2. **No gradients on Tier 2/3 cards in lists**
   - ⚠️ Must remove gradients (performance + visual weight)
   - ✅ Will improve performance

3. **Shadows minimized on mobile**
   - ⚠️ Must remove shadows on mobile
   - ✅ Will improve performance

4. **Hover effects desktop only**
   - ⚠️ Must disable hover effects on mobile
   - ✅ Already mostly compliant

### Performance Targets

- **Frame Rate:** 50-60fps on mid-range devices
- **Memory:** No significant increase
- **List Scrolling:** Smooth with 100+ items
- **Animation:** No jank

### Performance Monitoring

- Profile before migration (baseline)
- Profile after Phase 1 (prototype)
- Profile after Phase 2 (components)
- Profile after Phase 3 (all screens)
- Profile after Phase 4 (final)

---

## SUCCESS METRICS

### Quantitative Metrics

1. **Visual Weight Reduction:**
   - Gradients removed: Target 100% from Tier 2/3 cards
   - Shadows reduced: Target 25% reduction
   - Gold usage: Target 50% reduction (removed from Tier 2/3)

2. **Code Quality:**
   - Hardcoded colors: Target 0 (all from theme)
   - Component reusability: Increased (ObsidianCard base)
   - Code duplication: Reduced (unified button system)

3. **Performance:**
   - Frame rate: Maintain 50-60fps
   - Memory: No increase
   - List performance: Maintain smooth scrolling

### Qualitative Metrics

1. **Visual Hierarchy:**
   - Clear tier distinction (Tier 1/2/3)
   - Gold used only for signals
   - Reduced visual fatigue

2. **Consistency:**
   - Similar components look consistent
   - Tier assignment consistent
   - Button/system usage consistent

3. **User Experience:**
   - Easier to scan (better hierarchy)
   - Less visual noise
   - More professional appearance

---

## COMMUNICATION PLAN

### Stakeholder Updates

- **After Phase 0:** Technical team (theme infrastructure ready)
- **After Phase 1:** Design + Tech (prototype screens ready for review)
- **After Phase 2:** Design + Tech (components standardized)
- **After Phase 3:** All stakeholders (all screens migrated)
- **After Phase 4:** All stakeholders (ready for production)

### Documentation Updates

- Update design system docs after Phase 0
- Update component docs after Phase 2
- Create migration guide after Phase 4
- Update README if needed

---

## TIMELINE SUMMARY

| Phase | Duration | Start | End | Dependencies |
|-------|----------|-------|-----|--------------|
| Phase 0: Preparation | 2-3 days | Week 1 | Week 1 | None |
| Phase 1: Prototype | 5-7 days | Week 1-2 | Week 2 | Phase 0 |
| Phase 2: Core Components | 7-10 days | Week 2-3 | Week 3-4 | Phase 1 |
| Phase 3: Remaining Screens | 10-15 days | Week 3-4 | Week 5-6 | Phase 2 |
| Phase 4: Polish & QA | 5-7 days | Week 6 | Week 7 | Phase 3 |
| **Total** | **29-42 days** | - | - | - |

**Recommended:** 6-7 weeks (allowing buffer for issues)

---

## PROTECTING EXISTING STRENGTHS

### What We're NOT Changing

**Existing Strengths to Preserve:**
1. **Responsive Breakpoints System** ✅
   - `ResponsiveBreakpoints` class works well
   - Breakpoints (400, 600, 800, 1200, 1600) are appropriate
   - Keep as-is, only extend if needed

2. **Responsive Tokens System** ✅
   - `ResponsiveTokens` class provides good spacing/sizing
   - Padding, spacing, font sizes scale appropriately
   - Keep as-is, integrate with new theme

3. **Layout Logic** ✅
   - Grid systems work
   - Card layouts are functional
   - Navigation patterns are clear
   - Refine styling, don't change structure

4. **Functional Clarity** ✅
   - Information architecture is good
   - User flows are clear
   - No business logic changes needed
   - Only improve visual presentation

### Migration Philosophy

**Refine, Don't Re-Invent:**
- Improve visual hierarchy (tier system)
- Reduce visual noise (remove gradients, reduce shadows)
- Better use of gold (signal, not frame)
- Cleaner typography (Outfit/Inter)
- **But keep:** Layout patterns, navigation, functionality, responsive system

---

## GO / NO-GO RECOMMENDATION

### ✅ GO — With One Condition

**Proceed only if you agree to this principle:**

**"Do not migrate the app to the system. Migrate the system to the app."**

### What This Means

1. **Validate Visually Before Abstracting**
   - Phase 1 is a test (Design Confidence Gate)
   - If it doesn't feel right, adjust the system
   - Don't force screens to fit a rigid spec

2. **Stop When Clarity is Achieved**
   - P0 screens are required
   - P1 screens are recommended
   - P2/P3 screens can be "good enough"
   - Don't over-engineer low-impact screens

3. **Leave Low-Impact Screens "Good Enough"**
   - Auth screens (P3) can stay minimal
   - Edge cases (P2) can wait
   - Focus on daily-use screens (P0/P1)

4. **Protect Existing Strengths**
   - Keep responsive system
   - Keep layout logic
   - Keep functional clarity
   - Only improve visual presentation

### Expected Outcomes

If you follow this principle, you'll achieve:
- ✅ Stronger brand identity (luxury through restraint)
- ✅ Less visual fatigue (reduced noise, better hierarchy)
- ✅ Better scan speed (clear tier distinction)
- ✅ No performance regression (removing gradients helps)
- ✅ Maintained functionality (no business logic changes)

### Risk Assessment

**Low Risk Because:**
- Phased approach (test before scaling)
- Design Confidence Gate (validate before abstracting)
- Backward compatibility (extend, don't replace)
- Priority-based (focus on high-impact screens)
- Performance-conscious (no BackdropFilter in lists)

**Recommended Action:**
- ✅ **GO** - Proceed with migration
- ✅ Follow phased approach
- ✅ Respect Design Confidence Gate after Phase 1
- ✅ Migrate P0/P1 screens only initially
- ✅ Leave P2/P3 for later or "good enough"

---

## NEXT STEPS

1. **Review and Approve Plan**
   - Review migration plan with team
   - Get stakeholder approval
   - Confirm agreement with core principle
   - Set start date

2. **Set Up Development Environment**
   - Create feature branch
   - Set up testing devices
   - Prepare screenshot tools

3. **Begin Phase 0**
   - Start theme token preparation
   - Follow Phase 0 checklist
   - Test thoroughly before proceeding

4. **Plan for Design Confidence Gate**
   - Schedule review session after Phase 1
   - Prepare evaluation questions
   - Be ready to pause and adjust

---

**END OF MIGRATION PLAN**

---

*Related Documents:*
- UI_AUDIT.md - Complete audit of current state
- DESIGN_SYSTEM_OBSIDIAN.md - Design system specification
- This document - Migration plan and strategy

