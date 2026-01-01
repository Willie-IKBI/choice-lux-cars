# Feature-to-Feature Import Violations — invoices → jobs

**Generated:** 2025-01-XX  
**Agent:** CLC-ARCH  
**Purpose:** Document and resolve feature-to-feature import violations  
**Status:** PLANNING — No code changes yet

---

## Summary

**Total Violations Found:** 1

**Violating File:** `lib/features/invoices/widgets/invoice_action_buttons.dart`

**Import Statement:**
```dart
import 'package:choice_lux_cars/features/jobs/jobs.dart';
```

**Violation Type:** Direct feature-to-feature import (invoices → jobs)

---

## Full List of Violations

### Violation #1: invoice_action_buttons.dart → jobs.dart

**Importing File:**
- **Path:** `lib/features/invoices/widgets/invoice_action_buttons.dart`
- **Line:** 8

**Imported Symbol/File:**
- **Barrel Export:** `package:choice_lux_cars/features/jobs/jobs.dart`
- **Actual Symbols Used:**
  1. `jobsProvider` (exported from `lib/features/jobs/providers/jobs_provider.dart`)
  2. `JobsNotifier` (via `jobsProvider.notifier`)
  3. `Job` model (via `jobsProvider` data)

**Why It Exists:**

The invoice widget needs to:

1. **Read current job's invoice PDF URL:**
   - Watches `jobsProvider` to get the latest `Job.invoicePdf` field
   - Uses this to display the current invoice PDF URL in the UI
   - Code: Lines 38-56, 208-221

2. **Refresh jobs list after invoice operations:**
   - After creating/regenerating an invoice, calls `ref.read(jobsProvider.notifier).refreshJobs()`
   - Invalidates `jobsProvider` to force UI update
   - Code: Lines 88, 91, 152, 155

**Usage Details:**

```dart
// Line 38: Watch jobs provider
final jobsAsync = ref.watch(jobsProvider);

// Line 42-43: Access job data
final job = jobs.firstWhere(
  (job) => job.id.toString() == widget.jobId,
);

// Line 46: Access invoicePdf field
print('Job ${widget.jobId} invoice PDF: ${job.invoicePdf}');

// Line 59: Use invoice PDF URL
final currentInvoicePdfUrl = currentJob?.invoicePdf ?? widget.invoicePdfUrl;

// Line 88: Refresh jobs after creating invoice
await ref.read(jobsProvider.notifier).refreshJobs();

// Line 91: Invalidate provider
ref.invalidate(jobsProvider);

// Line 152: Refresh jobs after regenerating invoice
await ref.read(jobsProvider.notifier).refreshJobs();

// Line 155: Invalidate provider
ref.invalidate(jobsProvider);

// Line 208: Read jobs provider
final jobsAsync = ref.read(jobsProvider);
```

**Dependency Analysis:**

The invoice feature depends on:
- **Job data structure:** Needs `Job.invoicePdf` field
- **Jobs state management:** Needs to read and refresh jobs provider
- **Job lookup:** Needs to find job by ID in jobs list

**Root Cause:**

The invoice widget is trying to:
1. Display the latest invoice PDF URL from the job (which gets updated after invoice creation)
2. Trigger a refresh of the jobs list after invoice operations so the UI reflects the updated invoice PDF URL

This creates a tight coupling where invoices must know about jobs' internal state management.

---

## Chosen Resolution per Violation

### Violation #1 Resolution: **Option B** — Move shared logic to `lib/core/`

**Decision:** Create a lightweight service in `lib/core/services/` that provides job invoice PDF URL access without importing the jobs feature.

**Rationale:**
- The invoice widget needs job data (specifically `invoicePdf` field) but shouldn't depend on jobs feature
- Creating a service in `core/` allows invoices to access job invoice PDF URL without feature-to-feature coupling
- The service will use the jobs repository (which is already in core's dependency scope via dependency injection)
- This maintains separation of concerns while allowing necessary data access

**Alternative Considered:**
- **Option D (Interface):** Rejected — Over-engineering for a simple data access need
- **Option C (Duplicate):** Not applicable — This is not a constant
- **Option A (Move to shared):** Not applicable — This is not a UI-only widget

**Implementation Approach:**

1. **Create `lib/core/services/job_invoice_service.dart`:**
   - Provides method to get job invoice PDF URL by job ID
   - Uses jobs repository (injected via provider) to fetch job data
   - Returns only the invoice PDF URL (not the entire Job model)

2. **Create `lib/core/providers/job_invoice_provider.dart`:**
   - Riverpod provider that exposes job invoice PDF URL
   - Watches jobs repository to get latest invoice PDF URL
   - Provides refresh method to invalidate/refresh

3. **Update `invoice_action_buttons.dart`:**
   - Remove `import 'package:choice_lux_cars/features/jobs/jobs.dart';`
   - Import `lib/core/providers/job_invoice_provider.dart`
   - Replace `jobsProvider` usage with `jobInvoicePdfProvider`
   - Replace `ref.read(jobsProvider.notifier).refreshJobs()` with `ref.invalidate(jobInvoicePdfProvider)`

**Note:** The jobs repository is already accessible via dependency injection, so the service can use it without creating a feature-to-feature import.

---

## Exact Destination Paths for Moved Code

### New Files to Create:

1. **`lib/core/services/job_invoice_service.dart`**
   - Service to fetch job invoice PDF URL
   - Uses `JobsRepository` (injected via provider)
   - Methods:
     - `Future<String?> getInvoicePdfUrl(String jobId)`
     - `Future<void> refreshJobInvoice(String jobId)` (optional, for explicit refresh)

2. **`lib/core/providers/job_invoice_provider.dart`**
   - Riverpod provider for job invoice PDF URL
   - Watches jobs repository
   - Provides:
     - `jobInvoicePdfProvider(String jobId)` — Returns `AsyncValue<String?>`
     - Refresh/invalidation methods

### Files to Modify:

1. **`lib/features/invoices/widgets/invoice_action_buttons.dart`**
   - Remove: `import 'package:choice_lux_cars/features/jobs/jobs.dart';`
   - Add: `import 'package:choice_lux_cars/core/providers/job_invoice_provider.dart';`
   - Replace all `jobsProvider` usage with `jobInvoicePdfProvider(widget.jobId)`
   - Replace `ref.read(jobsProvider.notifier).refreshJobs()` with `ref.invalidate(jobInvoicePdfProvider(widget.jobId))`
   - Replace `ref.invalidate(jobsProvider)` with `ref.invalidate(jobInvoicePdfProvider(widget.jobId))`

### Files That May Need Updates:

1. **`lib/core/providers/jobs_repository_provider.dart`** (if it exists)
   - Ensure `JobsRepository` is accessible via provider
   - If not, create provider for `JobsRepository`

2. **`lib/features/jobs/data/jobs_repository.dart`**
   - May need to expose a method to fetch single job by ID (if not already exists)
   - Or ensure existing methods are sufficient

---

## Minimal Change Plan (Order of Edits)

### Step 1: Create Core Service
1. Create `lib/core/services/job_invoice_service.dart`
   - Implement `getInvoicePdfUrl(String jobId)` method
   - Inject `JobsRepository` via constructor
   - Handle errors gracefully

### Step 2: Create Core Provider
1. Create `lib/core/providers/job_invoice_provider.dart`
   - Create `jobInvoicePdfProvider` that takes `jobId` as parameter
   - Use `JobInvoiceService` to fetch invoice PDF URL
   - Return `AsyncValue<String?>`

### Step 3: Ensure Jobs Repository is Accessible
1. Check if `JobsRepository` has a provider in `lib/core/providers/`
2. If not, create `lib/core/providers/jobs_repository_provider.dart`
3. Ensure `JobsRepository` can be injected into `JobInvoiceService`

### Step 4: Update Invoice Widget
1. Open `lib/features/invoices/widgets/invoice_action_buttons.dart`
2. Remove: `import 'package:choice_lux_cars/features/jobs/jobs.dart';`
3. Add: `import 'package:choice_lux_cars/core/providers/job_invoice_provider.dart';`
4. Replace `ref.watch(jobsProvider)` with `ref.watch(jobInvoicePdfProvider(widget.jobId))`
5. Replace `ref.read(jobsProvider.notifier).refreshJobs()` with `ref.invalidate(jobInvoicePdfProvider(widget.jobId))`
6. Replace `ref.invalidate(jobsProvider)` with `ref.invalidate(jobInvoicePdfProvider(widget.jobId))`
7. Update logic to work with `AsyncValue<String?>` instead of `AsyncValue<List<Job>>`
8. Remove job lookup logic (no longer needed — provider returns URL directly)

### Step 5: Verify No Other Imports
1. Search entire codebase for any other imports from `features/jobs` in `features/invoices`
2. Confirm only one violation exists

### Step 6: Test Compilation
1. Run `flutter analyze` to check for compilation errors
2. Fix any import or type errors

### Step 7: Test Functionality
1. Verify invoice PDF URL is displayed correctly
2. Verify invoice creation updates the URL
3. Verify invoice regeneration updates the URL
4. Verify no regressions in invoice functionality

---

## Acceptance Criteria

### ✅ No Feature-to-Feature Imports Remain

- [ ] No files under `lib/features/invoices/` import from `lib/features/jobs/`
- [ ] No files under `lib/features/invoices/` import from `lib/features/jobs/` indirectly (via barrel exports)
- [ ] Verified via: `grep -r "features/jobs" lib/features/invoices/` returns zero matches

### ✅ App Compiles Successfully

- [ ] `flutter analyze` passes with no errors
- [ ] `flutter build` succeeds for target platform
- [ ] No import errors in IDE
- [ ] All type checks pass

### ✅ Behavior Unchanged

- [ ] Invoice PDF URL is displayed correctly in invoice action buttons
- [ ] Invoice PDF URL updates after creating invoice
- [ ] Invoice PDF URL updates after regenerating invoice
- [ ] Invoice widget refreshes correctly after invoice operations
- [ ] No UI regressions in invoice screens
- [ ] No performance regressions

### ✅ Architecture Compliance

- [ ] Invoices feature no longer depends on jobs feature
- [ ] Core service follows dependency injection pattern
- [ ] Core provider follows Riverpod best practices
- [ ] No circular dependencies introduced
- [ ] Code follows ARCHITECTURE.md guidelines

### ✅ Code Quality

- [ ] No `print()` statements added (use `Log.d()` instead)
- [ ] Error handling is appropriate
- [ ] Code is properly documented
- [ ] No unused imports
- [ ] No linter warnings introduced

---

## Implementation Notes

### Service Design

The `JobInvoiceService` should:
- Be a simple, focused service that only handles invoice PDF URL access
- Not expose the entire `Job` model (only the invoice PDF URL)
- Use dependency injection for `JobsRepository`
- Handle errors gracefully (return `null` if job not found, throw exceptions for real errors)

### Provider Design

The `jobInvoicePdfProvider` should:
- Take `jobId` as a parameter (using `family` provider pattern)
- Return `AsyncValue<String?>` to handle loading/error states
- Cache results appropriately
- Support invalidation for refresh

### Migration Strategy

1. **Create new code first** (service + provider)
2. **Test new code in isolation** (if possible)
3. **Update invoice widget** to use new provider
4. **Remove old import**
5. **Test end-to-end**
6. **Verify no regressions**

### Risk Assessment

**Low Risk:**
- Creating new core service (isolated change)
- Creating new provider (isolated change)

**Medium Risk:**
- Updating invoice widget (requires careful replacement of provider usage)
- Ensuring jobs repository is accessible (may require provider creation)

**Mitigation:**
- Test each step incrementally
- Keep old code commented out initially (for rollback)
- Verify compilation after each change
- Test functionality after each change

---

## Verification Commands

After implementation, run these commands to verify:

```bash
# Check for remaining violations
grep -r "features/jobs" lib/features/invoices/

# Check compilation
flutter analyze

# Check for import errors
flutter pub get
flutter build web --no-sound-null-safety  # or target platform

# Check for circular dependencies (manual review)
# Review import graph in IDE
```

---

**Status:** PLANNING COMPLETE  
**Next Step:** CLC-BUILD implements the resolution following this plan  
**Approval Required:** Yes — Before implementation begins

