# Theme Migration Batch 6 — Execution Plan

**Generated:** 2025-01-XX  
**Agent:** CLC-ARCH  
**Purpose:** Define strict execution plan for Theme Migration Batch 6  
**Status:** PLAN READY

**Source Documents:**
- `/ai/THEME_SPEC.md` — Theme specification
- `/ai/THEME_RULES.md` — Enforcement rules
- `/ai/THEME_AUDIT.md` — Violation audit

---

## A) Batch Objective

Migrate `lib/features/jobs/widgets/active_jobs_summary.dart` to use theme tokens exclusively, removing all hard-coded `Colors.*` usage and inline `TextStyle` colors. This widget displays system overview metrics and is visible on dashboard/job management screens. Token replacement only; no visual redesign.

---

## B) In-Scope File (Exact Path)

- `lib/features/jobs/widgets/active_jobs_summary.dart`

---

## C) Out-of-Scope (Explicit)

**Explicitly Excluded:**
- All other files in `lib/features/jobs/`
- All files in `lib/shared/widgets/`
- `lib/app/theme.dart` (authoritative source, allowed)
- All other feature files

**Boundary:** Only `active_jobs_summary.dart` may be modified.

---

## D) Patterns to Remove

- `Colors.blue` / `Colors.blue[700]` → Replace with `context.colorScheme.primary` or `context.tokens.infoColor`
- `Colors.green` → Replace with `context.tokens.successColor`
- `Colors.orange` → Replace with `context.colorScheme.primary` or `context.tokens.warningColor`
- `Colors.red` → Replace with `context.tokens.warningColor`
- `Colors.grey` / `Colors.grey[600]` → Replace with `context.tokens.textSubtle`
- Inline `TextStyle(color: Colors.grey[600])` → Replace with `context.textTheme.bodySmall?.copyWith(color: context.tokens.textSubtle)`

---

## E) Token Replacement Mapping

- Status colors: `Colors.green` → `context.tokens.successColor`, `Colors.blue` → `context.tokens.infoColor`, `Colors.orange` → `context.colorScheme.primary`, `Colors.red` → `context.tokens.warningColor`
- Text colors: `Colors.grey[600]` → `context.tokens.textSubtle`
- Health indicator colors: Map green/blue/orange/red to semantic tokens based on health score thresholds
- Icon colors: Use semantic tokens matching their status context

---

## F) Acceptance Criteria

- Zero violations: No `Colors.*` (except `Colors.transparent`), no `Color(0xFF...)`, all colors via `context.colorScheme.*` or `context.tokens.*`, no inline `TextStyle` colors
- Compilation: `flutter analyze` passes, app compiles successfully
- No layout changes: Visual appearance unchanged (token replacement only)

---

## G) Manual Validation Checklist

- [ ] Overview cards (Active Jobs, Driver Status) display with correct theme token colors for icons and borders
- [ ] Status rows (Very Recent, Recent, Stale, Active, Inactive) use correct semantic tokens for indicators and text
- [ ] System Health Indicator shows correct color mapping (Excellent=success, Good=info, Fair=primary, Poor=warning)
- [ ] All text labels use theme tokens (no hard-coded grey colors)
- [ ] Dashboard icon and card decorations use theme tokens

---

**Status:** PLAN READY  
**Next Step:** CLC-BUILD implements Batch 6 per this plan



