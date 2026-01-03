# Driver Expense Capture - Final Specification

## 1. SLIP UPLOAD SPEC

### Storage Bucket
**Bucket Name:** `clc_images` (existing bucket, used for odometer, vehicles, profiles)
**Justification:** 
- Already exists and configured
- Consistent with existing storage pattern
- RLS policies can be extended for expense slips

### Path Convention
**Pattern:** `expenses/{jobId}/{expenseId}/{timestamp}_{sanitizedOriginalName}`

**Example:** `expenses/1145/42/1704123456789_receipt_fuel.jpg`

**Rationale:**
- `expenses/` - Top-level folder for all expense slips
- `{jobId}/` - Organizes by job for easy cleanup/audit
- `{expenseId}/` - Unique per expense (prevents overwrites)
- `{timestamp}_{sanitizedOriginalName}` - Ensures uniqueness, preserves original name for reference

**Filename Sanitization:**
- Remove special characters except `-`, `_`, `.`
- Limit length to 100 chars
- Preserve extension

### Upload Timing Strategy

**Recommended: Option A - Create expense first, then upload slip**

**Flow:**
1. User fills expense form (without slip)
2. Create expense row in DB → get `expenseId`
3. Upload slip to `expenses/{jobId}/{expenseId}/...`
4. Update expense row with `slip_image` URL
5. If step 4 fails, expense exists but slip_image is NULL (handle in UI)

**Why Option A:**
- **Atomicity:** Expense record exists even if upload fails (can retry upload)
- **Cleanup:** If expense creation fails, no orphaned files
- **Audit:** Expense ID in path makes it easy to trace
- **Failure Handling:** Can show expense with "Slip upload failed - retry" message

**Failure Handling:**
- **Upload fails:** Expense saved with `slip_image = NULL`, show error + retry button
- **Update fails:** Slip uploaded but not linked, show error + manual retry
- **Both fail:** Expense saved, slip lost (user must re-upload)

**Alternative (Option B) - Upload first:**
- Risk: Orphaned files if expense creation fails
- Requires cleanup job for temp files
- Not recommended

### Security Model

**Bucket Type:** **PRIVATE** (recommended)
- Expense slips contain sensitive financial data
- Should not be publicly accessible
- Requires authentication to view

**RLS Policies (Storage):**
- **INSERT:** Only driver of the job can upload slips
  - Path must match `expenses/{jobId}/...` where `jobId` belongs to driver
  - Verify via `jobs.driver_id = auth.uid()` check
- **SELECT:** Drivers (their jobs), managers (managed jobs), admins (all)
  - Use signed URLs for display (60min expiry)
- **UPDATE:** Blocked (slips immutable after upload)
- **DELETE:** Only driver (before approval) OR admin (cleanup)

**Signed URL Strategy:**
- Generate signed URL when displaying slip
- Cache signed URL for 50 minutes (refresh before expiry)
- Use `storage.from('clc_images').createSignedUrl(path, 3600)` (1 hour expiry)

**Display Flow:**
1. Check if `expense.slipImage` exists
2. Extract path from URL or store path directly
3. Generate signed URL on-demand
4. Display in image viewer (tap to expand)

---

## 2. FINAL LOCKED REQUIREMENTS

### Navigate Button Removal
- ✅ Remove Navigate button from `JobProgressScreen` (mobile + desktop layouts)
- ✅ Keep address display container (informational only, no action button)
- ✅ Remove `_openNavigation()` method (or keep for future use, unused)

### Driver Expense Create Flow
- ✅ Location: `JobProgressScreen` (driver flow screen)
- ✅ UI Pattern: Modal/bottom-sheet form (mobile-first design)
- ✅ Trigger: "Add Expense" button in expense section
- ✅ Placement: Below trip progress card, above action buttons

### Required Fields
- ✅ **Expense Type:** Dropdown (fuel, parking, toll, other) - REQUIRED
- ✅ **Amount:** Numeric input (> 0) - REQUIRED
- ✅ **Date/Time:** DateTime picker (default: now) - REQUIRED
- ✅ **Slip/Receipt:** Image picker + upload - **REQUIRED**
- ✅ **Description:** Text input - REQUIRED if type = "other", optional otherwise
- ✅ **Location:** Text input - OPTIONAL

### Slip Upload Requirements
- ✅ **Required:** Every expense MUST have a slip uploaded
- ✅ **Validation:** Form cannot submit without slip selected
- ✅ **File Types:** JPG, PNG, PDF (max 5MB)
- ✅ **Storage:** Supabase Storage bucket `clc_images`
- ✅ **Path:** `expenses/{jobId}/{expenseId}/{timestamp}_{filename}`

### Role Permissions
- ✅ **CREATE:** Drivers only (for their assigned jobs)
- ✅ **READ:** Drivers (their jobs), Managers (managed jobs), Admins (all)
- ✅ **UPDATE:** Drivers only (before approval, DB trigger enforces)
- ✅ **DELETE:** Drivers only (before approval, DB trigger enforces)
- ✅ **APPROVE:** Managers (managed jobs) + Admins (all) via RPC

### Business Rules
- ✅ Expenses can be created during job execution (job_status != 'completed')
- ✅ Expenses can be created after job completion (before approval)
- ✅ Expenses CANNOT be created after approval (DB trigger blocks)
- ✅ Expenses become read-only after approval (DB trigger enforces)
- ✅ Slip upload is mandatory (client-side validation + server-side check)

---

## 3. ACCEPTANCE CRITERIA

### AC1: Driver Cannot Submit Without Slip
**Given:** Driver is on expense creation form
**When:** Driver fills all fields except slip upload
**Then:** 
- Submit button is disabled
- Error message: "Slip/Receipt image is required"
- Form highlights slip upload field in red

### AC2: Slip Upload Failure Allows Retry
**Given:** Driver selects slip image and fills form, then submits
**When:** Expense row is created successfully but slip upload fails (network error, storage error, RLS denial)
**Then:**
- Expense row IS created with `slip_image = NULL`
- Error message: "Expense saved, but slip upload failed. Please retry uploading the slip."
- Modal closes, expense list refreshes
- Expense appears in list with "Slip Missing" badge/warning
- "Retry Upload" button visible on the expense row
- Form data is NOT preserved (expense already created)

### AC3: Successful Save Stores Slip Reference
**Given:** Driver completes form with valid slip
**When:** Expense is created and slip uploaded successfully
**Then:**
- Expense row created with `slip_image` URL populated
- Slip stored at `expenses/{jobId}/{expenseId}/...`
- Success message: "Expense added successfully"
- Modal closes, expense list refreshes
- New expense appears in list with slip thumbnail

### AC4: Slip Display in Expense List
**Given:** Expense exists with slip_image URL
**When:** Driver views expense list in JobProgressScreen
**Then:**
- Each expense shows slip thumbnail (if available)
- Thumbnail is clickable (opens full-size viewer)
- Signed URL generated on-demand (60min expiry)
- Fallback icon if slip fails to load

### AC5: RLS Prevents Cross-Driver Uploads
**Given:** Driver A is logged in
**When:** Driver A attempts to upload slip for job assigned to Driver B
**Then:**
- Storage RLS blocks upload
- Error: "You can only upload slips for your assigned jobs"
- Upload fails, expense creation aborted

### AC6: RLS Prevents Cross-Driver Reads
**Given:** Driver A is logged in
**When:** Driver A attempts to view slip for expense on Driver B's job
**Then:**
- Storage RLS blocks signed URL generation
- Slip thumbnail shows "Access Denied" placeholder
- No error thrown (graceful degradation)

### AC7: Manager View Shows Slip Links
**Given:** Manager views JobSummaryScreen for managed job
**When:** Manager sees ExpensesCard with expenses
**Then:**
- Each expense shows slip thumbnail/link
- Clicking opens slip in viewer (signed URL)
- Slips are readable (manager has SELECT permission)

### AC8: Approved Expenses Become Read-Only
**Given:** Expense is approved by manager
**When:** Driver views expense in JobProgressScreen
**Then:**
- Edit button is hidden/disabled
- Delete button is hidden/disabled
- Expense shows "Approved" badge
- Slip is still viewable (read-only)

### AC9: Cannot Create Expense After Approval
**Given:** Job has at least one approved expense
**When:** Driver attempts to create new expense
**Then:**
- "Add Expense" button is disabled/hidden
- If attempted via API, DB trigger blocks with: "Cannot add expenses to job with approved expenses"
- Error message: "Expenses cannot be added after approval"

### AC10: Navigate Button Removed
**Given:** Driver is on JobProgressScreen
**When:** Driver views any step with address
**Then:**
- Navigate button is NOT visible (mobile or desktop)
- Address display is visible (informational only)
- No navigation action available

### AC11: Slip Missing Recovery
**Given:** Expense exists with `slip_image = NULL` (upload failed or not yet uploaded)
**When:** Driver views expense list in JobProgressScreen
**Then:**
- Expense shows "Slip Missing" warning badge/icon
- "Retry Upload" button is visible (if expense not approved)
- Clicking "Retry Upload" opens image picker
- After selecting image, upload proceeds to same path pattern
- On success, expense `slip_image` is updated, badge removed
- On failure, error shown, retry remains available

### AC12: Manager Warning + Confirm on Approve When Slips Missing
**Given:** Manager views ExpensesCard for job with expenses, and at least one expense has `slip_image = NULL`
**When:** Manager clicks "Approve Expenses" button
**Then:**
- Confirmation dialog appears with warning message
- Warning shows: "Warning: {X} expense(s) are missing slip images. Do you want to approve anyway?"
- Dialog lists expense IDs/types with missing slips
- Dialog has "Cancel" and "Approve Anyway" buttons
- If "Cancel": Dialog closes, no approval action
- If "Approve Anyway": Approval proceeds, all expenses approved (including those without slips)
- Success message: "Approved {count} expense(s)" (regardless of slip status)

### AC13: ExpensesCard Displays Missing Slip Indicators
**Given:** Manager views ExpensesCard for job with expenses
**When:** Some expenses have `slip_image = NULL`
**Then:**
- Totals row shows: "Missing Slips: {count}" in warning color (yellow/orange)
- Each expense row with missing slip shows:
  - "No Slip" badge/icon (warning color)
  - Slip thumbnail area shows placeholder icon (not clickable)
- Expenses with slips show normal thumbnail (clickable)
- Missing slip count is visible before clicking "Approve Expenses"

---

## 4. BUILD CHECKLIST

### Phase 1: Repository Layer
**File:** `lib/features/jobs/data/expenses_repository.dart`
- [ ] Add `createExpense(Expense expense)` method
  - INSERT into `expenses` table
  - Return created `Expense` with `id`
- [ ] Add `updateExpense(Expense expense)` method
  - UPDATE expense (only if not approved)
  - Return updated `Expense`
- [ ] Add `deleteExpense(int expenseId)` method
  - DELETE expense (only if not approved)
  - Return success/failure
- [ ] Add `uploadExpenseSlip(int jobId, int expenseId, Uint8List imageBytes, String fileName)` method
  - Upload to `clc_images/expenses/{jobId}/{expenseId}/{timestamp}_{fileName}`
  - Return public/signed URL
  - Handle errors (network, storage, RLS)

### Phase 2: Provider Layer
**File:** `lib/features/jobs/providers/expenses_provider.dart`
- [ ] Add `createExpense(Expense expense, Uint8List? slipBytes, String? slipFileName)` method
  - Create expense row first (get expenseId)
  - Upload slip if provided
  - Update expense with slip_image URL
  - Refresh list on success
  - Handle partial failures (expense created but slip failed)
- [ ] Add `updateExpense(Expense expense)` method
  - Call repository update
  - Refresh list on success
- [ ] Add `deleteExpense(int expenseId)` method
  - Call repository delete
  - Optionally delete slip from storage
  - Refresh list on success

### Phase 3: Storage Helper
**File:** `lib/core/services/upload_service.dart` (extend existing)
- [ ] Add `uploadExpenseSlip(Uint8List bytes, int jobId, int expenseId, String fileName)` method
  - Use existing `uploadImageBytes` pattern
  - Path: `expenses/{jobId}/{expenseId}/{timestamp}_{sanitizedFileName}`
  - Return signed URL (if private bucket) or public URL
- [ ] Add `deleteExpenseSlip(String path)` method
  - Extract path from URL or use direct path
  - Delete from `clc_images` bucket

### Phase 4: UI Modal Widget
**File:** `lib/features/jobs/widgets/add_expense_modal.dart` (NEW)
- [ ] Create modal/bottom-sheet widget
- [ ] Form fields:
  - Expense type dropdown (fuel, parking, toll, other)
  - Amount input (numeric, > 0 validation)
  - Date/time picker (default: now)
  - Description input (required if type = "other")
  - Location input (optional)
  - Slip image picker (REQUIRED, image_picker)
- [ ] Validation:
  - All required fields
  - Amount > 0
  - Description required if type = "other"
  - Slip selected (show error if not)
- [ ] Image preview (thumbnail before upload)
- [ ] Submit button (disabled until valid)
- [ ] Loading state during create + upload
- [ ] Error handling (show snackbar on failure)
- [ ] Success callback (close modal, refresh list)

### Phase 5: Expense List Widget
**File:** `lib/features/jobs/widgets/expense_list_widget.dart` (NEW) OR inline in JobProgressScreen
- [ ] Display list of expenses for job
- [ ] Each expense shows:
  - Type chip/badge
  - Amount (formatted currency)
  - Date/time
  - Description
  - Slip thumbnail (if available, clickable)
  - Edit button (if not approved)
  - Delete button (if not approved)
  - Approved badge (if approved)
- [ ] Empty state: "No expenses yet"
- [ ] Loading state
- [ ] Error state

### Phase 6: Integration in JobProgressScreen
**File:** `lib/features/jobs/screens/job_progress_screen.dart`
- [ ] Remove Navigate button (lines 649-664 mobile, 689-703 desktop)
- [ ] Add expense section below trip progress card
- [ ] Add "Add Expense" button (driver only, check role)
- [ ] Show expense list widget
- [ ] Handle modal open/close
- [ ] Refresh expense list after creation
- [ ] Disable "Add Expense" if job has approved expenses

### Phase 7: Update ExpensesCard (Manager View)
**File:** `lib/features/jobs/widgets/expenses_card.dart`
- [ ] Add slip thumbnail/link to each expense row
- [ ] Generate signed URL for slip display
- [ ] Add image viewer (tap to expand)
- [ ] Handle missing slips gracefully
- [ ] Add missing slip indicator per expense row:
  - Show "No Slip" badge/icon when `slip_image IS NULL`
  - Show placeholder icon in slip thumbnail area (not clickable)
- [ ] Add missing slip summary count:
  - Calculate count of expenses with `slip_image IS NULL`
  - Display in totals row: "Missing Slips: {count}" (warning color)
- [ ] Add approval confirmation dialog:
  - Show dialog when "Approve Expenses" clicked AND missing slip count > 0
  - Warning message: "Warning: {X} expense(s) are missing slip images. Do you want to approve anyway?"
  - List expense IDs/types with missing slips
  - "Cancel" and "Approve Anyway" buttons
  - If "Approve Anyway", proceed with approval (no RPC changes needed)

### Phase 8: Storage RLS Policies (Supabase Dashboard)
**Note:** Manual step, not code
- [ ] Create/update Storage RLS policies for `clc_images` bucket
- [ ] INSERT policy: Drivers can upload to `expenses/{jobId}/...` where job.driver_id = auth.uid()
- [ ] SELECT policy: Drivers (their jobs), Managers (managed jobs), Admins (all)
- [ ] UPDATE policy: Blocked (immutable)
- [ ] DELETE policy: Drivers (before approval) OR Admins (cleanup)

### Phase 9: Testing
- [ ] Test AC1: Cannot submit without slip
- [ ] Test AC2: Upload failure allows retry (expense created, slip NULL)
- [ ] Test AC3: Successful save stores slip
- [ ] Test AC4: Slip display in list
- [ ] Test AC5: RLS blocks cross-driver uploads
- [ ] Test AC6: RLS blocks cross-driver reads
- [ ] Test AC7: Manager can view slips
- [ ] Test AC8: Approved expenses read-only
- [ ] Test AC9: Cannot create after approval
- [ ] Test AC10: Navigate button removed
- [ ] Test AC11: Slip missing recovery (retry upload)
- [ ] Test AC12: Manager warning + confirm when slips missing
- [ ] Test AC13: Missing slip indicators in ExpensesCard

---

## IMPLEMENTATION ORDER

1. **Phase 1** - Repository methods (foundation)
2. **Phase 3** - Storage helper (reusable)
3. **Phase 2** - Provider methods (orchestration)
4. **Phase 4** - Expense modal (UI)
5. **Phase 5** - Expense list widget (display)
6. **Phase 6** - Integration in JobProgressScreen (main flow)
7. **Phase 7** - Update ExpensesCard (manager view)
8. **Phase 8** - Storage RLS (security)
9. **Phase 9** - Testing (validation)

**Estimated Time:** 8-10 hours

---

## NOTES

- Slip upload is REQUIRED (not optional) - enforce in UI and backend
- Use existing `UploadService` pattern for consistency
- Signed URLs for private bucket (60min expiry, refresh as needed)
- Handle partial failures gracefully (expense created but slip failed = retry option)
- Navigate button removal is simple (delete widget code)
- **Approval Rule:** Managers can approve expenses with missing slips, but must confirm via warning dialog
- **No RPC Changes:** `approve_job_expenses` RPC does NOT need validation for missing slips (UI handles warning)

