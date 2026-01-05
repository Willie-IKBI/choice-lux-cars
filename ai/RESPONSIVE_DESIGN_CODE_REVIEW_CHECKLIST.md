# Responsive Design Code Review Checklist
## Choice Lux Cars - Prevention of Regression

**Document Version:** 1.0  
**Date:** 2025-01-04  
**Status:** Active

---

## Purpose

This checklist ensures that all new code and changes maintain responsive design standards and prevent regression of responsive design fixes.

**Use this checklist for:**
- Code reviews of new screens
- Code reviews of screen modifications
- Pre-commit validation
- Pull request reviews

---

## Pre-Commit Checklist

Before committing responsive design changes, verify:

### ✅ Breakpoints
- [ ] All breakpoint checks use `ResponsiveBreakpoints` class
- [ ] No hardcoded breakpoint checks (e.g., `screenWidth < 600`)
- [ ] No direct `MediaQuery.of(context).size.width` comparisons
- [ ] Breakpoints are consistent across the screen

**❌ Bad:**
```dart
final isMobile = screenWidth < 600;
final isDesktop = screenWidth >= 800;
```

**✅ Good:**
```dart
final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
```

### ✅ Spacing & Padding
- [ ] All padding uses `ResponsiveTokens.getPadding(screenWidth)`
- [ ] All spacing uses `ResponsiveTokens.getSpacing(screenWidth)`
- [ ] No hardcoded `EdgeInsets.all(16)` or similar
- [ ] No hardcoded `SizedBox(height: 24)` or similar

**❌ Bad:**
```dart
padding: const EdgeInsets.all(16),
SizedBox(height: 24),
```

**✅ Good:**
```dart
padding: EdgeInsets.all(ResponsiveTokens.getPadding(screenWidth)),
SizedBox(height: ResponsiveTokens.getSpacing(screenWidth) * 2),
```

### ✅ Font Sizes
- [ ] All font sizes use `ResponsiveTokens.getFontSize(screenWidth, baseSize: X)`
- [ ] No hardcoded `fontSize: 16` or similar
- [ ] Base sizes are appropriate for the context

**❌ Bad:**
```dart
fontSize: 16,
fontSize: 18,
```

**✅ Good:**
```dart
fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 16),
fontSize: ResponsiveTokens.getFontSize(screenWidth, baseSize: 18),
```

### ✅ Icon Sizes
- [ ] All icon sizes use `ResponsiveTokens.getIconSize(screenWidth)`
- [ ] No hardcoded `size: 24` or similar
- [ ] Icons scale appropriately

**❌ Bad:**
```dart
Icon(Icons.home, size: 24),
```

**✅ Good:**
```dart
Icon(Icons.home, size: ResponsiveTokens.getIconSize(screenWidth)),
```

### ✅ Scaffold Usage
- [ ] Screen uses `SystemSafeScaffold` (not `Scaffold`)
- [ ] Proper system UI handling
- [ ] No redundant `SafeArea` wrappers

**❌ Bad:**
```dart
Scaffold(
  body: SafeArea(
    child: ...
  ),
)
```

**✅ Good:**
```dart
SystemSafeScaffold(
  body: ...
)
```

### ✅ Desktop Max-Width
- [ ] Desktop content has max-width constraint
- [ ] Content is centered using `Center` widget
- [ ] Appropriate max-width for screen type:
  - Content areas: 1200px
  - Forms/Detail views: 800px
  - Dashboard/Analytics: 1400px
  - Auth screens: 400-500px

**❌ Bad:**
```dart
body: SingleChildScrollView(
  child: Column(...),
)
```

**✅ Good:**
```dart
body: Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 1200),
    child: SingleChildScrollView(
      child: Column(...),
    ),
  ),
)
```

### ✅ Mobile Stacking
- [ ] Form fields stack vertically on mobile
- [ ] Action buttons stack vertically on mobile (except 2 small buttons)
- [ ] Grids use single column on mobile
- [ ] No side-by-side layouts on mobile

**❌ Bad:**
```dart
Row(
  children: [
    TextField(...),
    TextField(...),
  ],
)
```

**✅ Good:**
```dart
Column(
  children: [
    TextField(...),
    if (!isMobile) TextField(...),
  ],
)
// OR
if (isMobile)
  Column(children: [TextField(...), TextField(...)])
else
  Row(children: [TextField(...), TextField(...)])
```

### ✅ Component Types
- [ ] Cards used for interactive content
- [ ] Compact containers used for metrics
- [ ] Appropriate component type for use case

**Guidelines:**
- **Cards**: Interactive content, hover states, grid items
- **Compact Containers**: Metrics, read-only info, form sections
- **Plain Containers**: Grouping, padding, layout structure

---

## Code Review Checklist

During code review, verify:

### Architecture
- [ ] Screen follows responsive design patterns
- [ ] Responsive tokens imported: `import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';`
- [ ] Screen width obtained: `final screenWidth = MediaQuery.of(context).size.width;`
- [ ] Breakpoints checked: `final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);`

### Layout Structure
- [ ] Proper widget hierarchy
- [ ] No unnecessary nested containers
- [ ] Efficient rebuilds (no unnecessary setState calls)

### Responsive Behavior
- [ ] Layout adapts to screen size (reflow, not resize)
- [ ] Content reorganizes appropriately
- [ ] No content hidden or cut off
- [ ] Proper use of Expanded/Flexible widgets

### Performance
- [ ] No unnecessary rebuilds
- [ ] Efficient list rendering (ListView.builder where appropriate)
- [ ] Proper use of const constructors

### Accessibility
- [ ] Proper semantic labels
- [ ] Touch targets are appropriately sized
- [ ] Text is readable at all sizes
- [ ] Color contrast maintained

---

## Common Mistakes to Watch For

### ❌ Mistake 1: Hardcoded Breakpoints
```dart
// BAD
if (screenWidth < 600) { ... }
```

### ❌ Mistake 2: Hardcoded Spacing
```dart
// BAD
padding: const EdgeInsets.all(16),
SizedBox(height: 24),
```

### ❌ Mistake 3: Using Scaffold Instead of SystemSafeScaffold
```dart
// BAD
Scaffold(
  body: SafeArea(...),
)
```

### ❌ Mistake 4: No Desktop Max-Width
```dart
// BAD
body: SingleChildScrollView(
  child: Column(...), // Stretches full width on desktop
)
```

### ❌ Mistake 5: Side-by-Side on Mobile
```dart
// BAD
Row(
  children: [
    Expanded(child: TextField(...)),
    Expanded(child: TextField(...)),
  ],
) // Breaks on mobile
```

---

## Exception Handling

### Acceptable Exceptions

1. **Helper Functions**: Functions that calculate pixel values may use hardcoded breakpoints
   ```dart
   // ACCEPTABLE - Calculating pixel values
   double _getMaxWidth(double screenWidth) {
     if (screenWidth < 400) return screenWidth - 24;
     if (screenWidth < 600) return screenWidth - 32;
     // ...
   }
   ```

2. **LayoutBuilder Constraints**: When using LayoutBuilder, constraints.maxWidth comparisons are acceptable
   ```dart
   // ACCEPTABLE - Using constraints from LayoutBuilder
   LayoutBuilder(
     builder: (context, constraints) {
       final isMobile = ResponsiveBreakpoints.isMobile(constraints.maxWidth);
       // ...
     },
   )
   ```

3. **Auth Screens**: May use slightly different max-widths (400-500px) for optimal form display

4. **PDF Viewer**: Full-width on desktop is acceptable for document viewing

---

## Automated Prevention (Future)

### Recommended Tools
- **Linter Rules**: Custom rules to flag hardcoded values
- **Code Scanning**: Automated detection of breakpoint violations
- **Visual Regression Testing**: Screenshot comparison
- **CI/CD Integration**: Automated checks in pipeline

### Implementation Ideas
```yaml
# Example linter rule
rules:
  no_hardcoded_breakpoints:
    - pattern: 'screenWidth\s*[<>=]'
      message: 'Use ResponsiveBreakpoints instead of hardcoded breakpoints'
  
  no_hardcoded_spacing:
    - pattern: 'EdgeInsets\.(all|symmetric|only)\([0-9]'
      message: 'Use ResponsiveTokens.getPadding() instead'
```

---

## Review Sign-Off

### Reviewer Information
- **Reviewer Name:** ________________
- **Date:** ________________
- **PR/Commit:** ________________

### Review Status
- [ ] All checklist items verified
- [ ] No violations found
- [ ] Code follows responsive design standards
- [ ] Ready to merge

### Notes
_Add any additional notes or concerns here:_

---

## Quick Reference

### Import Statement
```dart
import 'package:choice_lux_cars/shared/widgets/responsive_grid.dart';
```

### Get Screen Width
```dart
final screenWidth = MediaQuery.of(context).size.width;
```

### Check Breakpoints
```dart
final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(screenWidth);
final isMobile = ResponsiveBreakpoints.isMobile(screenWidth);
final isTablet = ResponsiveBreakpoints.isTablet(screenWidth);
final isDesktop = ResponsiveBreakpoints.isDesktop(screenWidth);
final isLargeDesktop = ResponsiveBreakpoints.isLargeDesktop(screenWidth);
```

### Get Responsive Tokens
```dart
final padding = ResponsiveTokens.getPadding(screenWidth);
final spacing = ResponsiveTokens.getSpacing(screenWidth);
final fontSize = ResponsiveTokens.getFontSize(screenWidth, baseSize: 16);
final iconSize = ResponsiveTokens.getIconSize(screenWidth);
final cornerRadius = ResponsiveTokens.getCornerRadius(screenWidth);
```

### Desktop Max-Width Pattern
```dart
body: Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 1200), // Adjust as needed
    child: SingleChildScrollView(
      child: Column(...),
    ),
  ),
)
```

---

**End of Code Review Checklist**

