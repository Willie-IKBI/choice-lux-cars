# Theme Migration Batch 5 — Execution Plan

**Generated:** 2025-01-XX  
**Agent:** CLC-ARCH  
**Purpose:** Define strict execution plan for Theme Migration Batch 5  
**Status:** PLAN READY

**Source Documents:**
- `/ai/THEME_SPEC.md` — Theme specification
- `/ai/THEME_RULES.md` — Enforcement rules
- `/ai/THEME_AUDIT.md` — Violation audit

---

## A) Batch Objective

Migrate `lib/features/clients/widgets/client_card.dart` to use theme tokens exclusively, removing all hard-coded colors and legacy constants. This shared widget is highly reused across the clients feature and fixing it will improve consistency across all client list views. Token replacement only; no visual redesign.

---

## B) In-Scope File (Exact Path)

- `lib/features/clients/widgets/client_card.dart`

---

## C) Out-of-Scope (Explicit)

**Explicitly Excluded:**
- All other files in `lib/features/clients/`
- All files in `lib/shared/widgets/`
- `lib/app/theme.dart` (authoritative source, allowed)
- All other feature files

**Boundary:** Only `client_card.dart` may be modified.

---

## D) Patterns to Remove

- `Colors.black` → Replace with `context.colorScheme.onPrimary` or `context.colorScheme.background`
- `Colors.white` → Replace with `context.colorScheme.onPrimary` or `context.tokens.textHeading`
- `Colors.orange` → Replace with `context.colorScheme.primary` or `context.tokens.warningColor`
- `Colors.red` → Replace with `context.tokens.warningColor`
- `ChoiceLuxTheme.richGold` → Replace with `context.colorScheme.primary`
- `ChoiceLuxTheme.charcoalGray` → Replace with `context.colorScheme.surface`
- `ChoiceLuxTheme.platinumSilver` → Replace with `context.tokens.textBody` or `context.colorScheme.onSurfaceVariant`
- `ChoiceLuxTheme.softWhite` → Replace with `context.tokens.textHeading`
- `ChoiceLuxTheme.successColor` → Replace with `context.tokens.successColor`
- `ChoiceLuxTheme.errorColor` → Replace with `context.tokens.warningColor` or `context.colorScheme.error`

---

## E) Token Replacement Mapping

- Status colors: `Colors.orange` → `context.colorScheme.primary`, `Colors.red` → `context.tokens.warningColor`, `ChoiceLuxTheme.successColor` → `context.tokens.successColor`
- Text colors: `ChoiceLuxTheme.softWhite` → `context.tokens.textHeading`, `ChoiceLuxTheme.platinumSilver` → `context.tokens.textBody`
- Surface colors: `ChoiceLuxTheme.charcoalGray` → `context.colorScheme.surface`
- Primary accent: `ChoiceLuxTheme.richGold` → `context.colorScheme.primary`
- Error/warning: `ChoiceLuxTheme.errorColor` → `context.tokens.warningColor`
- On-colors: `Colors.black` → `context.colorScheme.onPrimary`, `Colors.white` → `context.colorScheme.onPrimary` or `context.tokens.textHeading`

---

## F) Acceptance Criteria

- Zero violations: No `Colors.*` (except `Colors.transparent`), no `Color(0xFF...)`, no `ChoiceLuxTheme.*`, all colors via `context.colorScheme.*` or `context.tokens.*`
- Compilation: `flutter analyze` passes, app compiles successfully
- No layout changes: Visual appearance unchanged (token replacement only)

---

## G) Manual Validation Checklist

- [ ] Status indicators display correctly (VIP, Pending, Inactive, Active) with theme tokens
- [ ] Card borders and hover states use theme tokens (selected, hover, default)
- [ ] Text colors (company name, contact info, hint text) use theme tokens
- [ ] Action buttons (Edit, Manage Agents, Deactivate) use theme tokens for backgrounds and foregrounds
- [ ] Logo placeholder and selection indicator use theme tokens

---

**Status:** PLAN READY  
**Next Step:** CLC-BUILD implements Batch 5 per this plan



