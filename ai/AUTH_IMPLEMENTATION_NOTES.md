# Auth Redesign Implementation Notes
## "Executive Control" Direction

**Status:** In Progress  
**Started:** 2025-01-XX

---

## IMPLEMENTATION DECISIONS

### Background
- ✅ Changed to solid obsidian color (no gradient)
- ✅ Vertical grid pattern (very subtle, 1.5% opacity, 80px spacing)
- ✅ BackgroundPatterns.signin updated to VerticalGridPainter

### Layout Structure
- ✅ Left-aligned (not centered)
- ✅ Desktop: 40% from left, max-width 420px
- ✅ Tablet: 32px from left, max-width 400px  
- ✅ Mobile: Full-width, 24px horizontal padding
- ✅ No card container (BackdropFilter removed)

### Typography
- Title: Outfit, 32px desktop / 28px tablet / 24px mobile, weight 700, white (#FFFFFF)
- Remove subtitle ("SIGN IN TO YOUR ACCOUNT")
- Labels: Inter, 12px, weight 500, muted (#52525B)
- Body: Inter, 16px, weight 400, zinc (#A1A1AA)

### Input Fields
- Border radius: 4px (sharp)
- Height: 48px
- Focus border: Gold, 2px
- No gold on enabled/default state
- Label color: Muted (#52525B)

### Button
- Border radius: 4px (sharp)
- Height: 48px
- Background: Gold (#C6A87C)
- Text: Black, weight 600
- No elevation
- No animation
- Full width

### Logo
- Remove animations (hover scale)
- Remove gold border
- Remove gold glow/shadow
- Size: 48px (smaller, more understated)
- Optional: Minimal gold accent (dot/underline) - DECISION PENDING

### Spacing
- Vertical rhythm: 32px between sections
- Between fields: 24px (desktop), 20px (tablet), 16px (mobile)
- Label to input: 16px

### Gold Usage (Signal Only)
- ✅ Primary button (solid fill)
- ✅ Input focus border (2px)
- ❌ No gold on logo border
- ❌ No gold on containers
- ❌ No gold text (title is white)

### Effects Removed
- ✅ Logo hover scale animation
- ✅ Button scale animation  
- ✅ Shake animation (but keep error handling)
- ✅ BackdropFilter container
- ✅ BoxShadow on containers
- ✅ Gradient backgrounds

### Copy Changes
- ✅ Remove "SIGN IN TO YOUR ACCOUNT" subtitle
- ✅ Remove instructional text
- ✅ Keep only essential labels

---

## UNCERTAINTIES / DECISIONS PENDING

1. **Logo Treatment**: Proposal says "Optional: Minimal logo accent (dot or underline, not border)". Should we:
   - Remove logo entirely?
   - Keep plain logo (no accent)?
   - Add minimal gold dot/underline?
   - **DECISION:** Keep plain logo, no gold accent for now (can add later if needed)

2. **Error Display**: Current shake animation - proposal says remove animations but keep error handling. Should errors:
   - Display inline (current approach)?
   - Use snackbar only?
   - **DECISION:** Keep inline error display (functional, not decorative)

3. **Input Field Background**: Current uses softWhite.withOpacity(0.05). Proposal doesn't specify. Should we:
   - Keep subtle fill?
   - Use surface color (#18181B) with opacity?
   - No fill (transparent)?
   - **DECISION:** Keep subtle fill for contrast, but use surface color approach

---

## IMPLEMENTATION PROGRESS

- [x] Update background pattern (VerticalGridPainter)
- [ ] Login screen layout restructure
- [ ] Login screen input fields
- [ ] Login screen button
- [ ] Login screen typography
- [ ] Signup screen (same changes)
- [ ] Forgot Password screen
- [ ] Reset Password screen
- [ ] Verify responsive behavior
- [ ] Final summary

