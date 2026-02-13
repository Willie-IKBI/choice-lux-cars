
# VOUCHER_FLOW.md
_Last updated: 2025-08-11_

## 1) Purpose & Scope
This document defines the end-to-end flow for **generating, storing, linking, viewing, downloading, and sharing a Voucher PDF** for a Job in the **Choice Lux Cars** Flutter app. It mirrors the existing FlutterFlow action and uses the **same Supabase database** and Storage bucket.

This spec covers:
- UX flow on **Manage Jobs** (list of job cards)
- **PDF generation** (client-side in Flutter)
- **Upload to Supabase Storage** and **DB linking**
- **Indicators** on each Job card (created / view / share)
- **Sharing via WhatsApp** options (mobile & web)
- Security, RLS, error states, and acceptance criteria

---

## 2) High-Level Flow
1. **User opens Manage Jobs** → sees cards for each Job.
2. On a card, user taps **"Create Voucher"** (if not created yet).
3. App **fetches voucher data** via RPC (`get_voucher_data_for_pdf(p_voucher_id)`) or by job id → voucher id mapping.
4. App **generates Voucher PDF** locally with the `pdf` package.
5. App **uploads** the PDF to Supabase **Storage** (`pdfdocuments/vouchers/voucher_<voucher_id>.pdf`, `upsert: true`).
6. App **updates** `jobs.voucher_pdf` with the **public (or signed) URL**.
7. Card UI updates to show **"Voucher Created"** (badge) and shows two actions:
   - **View/Download** (opens the stored URL)
   - **Share** → **WhatsApp** (and optionally other share targets)
8. On subsequent visits, the app detects `voucher_pdf` and **skips** re-generation unless the user **chooses to regenerate** (optional control).

---

## 3) UX & UI Requirements

### 3.1 Manage Jobs Card
Each job card displays:
- **Primary info**: passenger name, pickup date/time, pickup & dropoff locations, driver & vehicle summary.
- **Voucher section** (right-aligned or bottom row on mobile):
  - If `voucher_pdf` is **null**:
    - **Button (filled)**: `Create Voucher`
  - If `voucher_pdf` is **not null**:
    - **Status Chip**: `Voucher Created`
    - **IconButton**: `Open` (launches URL in browser / in-app webview)
    - **IconButton**: `Share` (opens share sheet; WhatsApp if available)
    - **Menu (optional)**: `Regenerate Voucher` (with confirm dialog)

**Loading states**:
- While generating: disable actions, show progress (`Generating voucher…`).
- While uploading/linking: show progress (`Uploading voucher…`).

**Error states**:
- RPC fetch failed → `Could not fetch voucher data.`
- PDF build failed → `Could not generate PDF.`
- Upload failed → `Could not upload voucher.`
- DB link failed → `Could not save voucher link.`
- Each error should offer **Retry** (where safe).

### 3.2 View/Download behavior
- **Mobile (Android/iOS)**: open in an in-app viewer (if available) or external browser; allow OS download dialog.
- **Web**: open the **public or signed** URL in a new tab; rely on browser download UX.

### 3.3 Share behavior (WhatsApp)
- **Mobile**: use the platform share sheet (e.g., `share_plus`) or **WhatsApp deep links**:
  - `https://wa.me/<phone>?text=<encoded text with voucher link>`
- **Web**: open `https://web.whatsapp.com/send?phone=<phone>&text=<encoded text>` in a new tab.
- This approach **does not require additional services** if the share is **user-initiated** and the recipient uses WhatsApp.
- If **automated, server-side sending** is required, use **WhatsApp Business API** (requires a provider & approval).

---

## 4) Data & API Contracts

### 4.1 RPCs & Tables
- **RPC**: `get_voucher_data_for_pdf(p_voucher_id int)`  
  _Returns_ a single JSON record with:
  - `job_id`, `quote_no`, `quote_date`
  - `company_name`, `company_logo`
  - `agent_name`, `agent_contact`
  - `passenger_name`, `passenger_contact`, `number_passangers`, `luggage`
  - `driver_name`, `vehicle_type`
  - `transport`: array of rows: `pickup_date`, `pickup_time`, `pickup_location`, `dropoff_location`
  - `notes`

- **Table**: `jobs`
  - `id` (pk)
  - `voucher_pdf` (text, nullable) → **stored URL** (public or signed)
  - Other job fields (not enumerated here)

- **Storage**: bucket `pdfdocuments`, path pattern `vouchers/voucher_<voucher_id>.pdf`

> **Note**: If you only have `job_id` on the card and not `voucher_id`, add a resolver:
> - `select voucher_id from vouchers where job_id = :job_id` or
> - a new `get_voucher_id_for_job(p_job_id)` RPC, or
> - extend the main RPC to accept `p_job_id`.

### 4.2 URL Strategy
- **Public URL** (current FlutterFlow behavior):
  - Fast & simple, but anyone with the URL can view.
- **Private + Signed URL** (recommended):
  - Store only `storage_path` in DB; generate **time-limited signed URL** when user taps "Open"/"Share".
  - Improves privacy, aligned with RLS on Storage.

---

## 5) Security & RLS

1. **Auth required** for all operations.
2. **Jobs visibility**: users should only see jobs belonging to their business/org.
3. **Storage policies**:
   - Allow **upload** only if user belongs to the job's business.
   - **Public** bucket is acceptable but **not ideal** for PII; prefer **private** with signed URLs.
4. **RPC** `get_voucher_data_for_pdf` must check **tenant isolation**:
   - Ensure the current user can access the target voucher/job (e.g., via `auth.uid()` in SQL and joins to business ownership).

---

## 6) App Architecture (Flutter)

### 6.1 Layers
- **UI**: Manage Jobs Card (`JobCard`)
- **State**: Riverpod providers
  - `jobListProvider`: loads jobs with `voucher_pdf`
  - `voucherControllerProvider`: handles create/open/share flows per job/voucher
- **Services**:
  - `VoucherPdfService`:
    - `Future<Uint8List> buildVoucherPdf(VoucherData data)`
  - `VoucherRepository`:
    - `Future<VoucherData> fetchVoucherData({required int voucherId})`
    - `Future<String> uploadVoucherBytes({required int voucherId, required Uint8List bytes})`
    - `Future<void> linkVoucherUrlToJob({required int jobId, required String url})`
    - `Future<String> getPublicOrSignedUrl({required String storagePath})`

### 6.2 UI States (per Job)
- `idle` → show **Create Voucher** (if `voucher_pdf == null`)
- `creating` → loading spinner, disabled actions
- `created` → show **Created** chip + **Open**/**Share**
- `error(type)` → show error banner/snackbar with retry

### 6.3 Error Handling
- Map exceptions to user-friendly messages.
- Log to console + optional telemetry table (`voucher_logs`).

---

## 7) PDF Layout Requirements
- Title: **"Voucher"** (not "Confirmation Voucher")
- **No amounts** displayed.
- **No footer** (unless brand requires it).
- Sections:
  - Header: `company_name` (bold) + right-aligned logo
  - Meta: `Voucher Date` (formatted `dd MMM yyyy`), `Voucher No`
  - Agent, Passenger
  - Driver & Vehicle
  - Trip Details table (`Date | Time | Pick-Up | Drop-Off`)
  - Notes (optional)
- **Fonts**: Prefer brand fonts via `PdfGoogleFonts`.
- **A4**, margins 30pt, consistent spacing and 9–11pt text.

---

## 8) WhatsApp Sharing Options

### 8.1 User-Initiated Sharing (No extra services)
- Generate (or use existing) **URL** to the PDF.
- Build a message: `Your booking voucher: <URL>` (include job reference).
- Launch a WhatsApp deep link:
  - Mobile: `https://wa.me/<phone>?text=<encoded>`
  - Web: `https://web.whatsapp.com/send?phone=<phone>&text=<encoded>`
- Or use `share_plus` to open a system share sheet and let the user pick WhatsApp.

### 8.2 Automated/Programmatic Sending (Extra services required)
- Use **WhatsApp Business API** via providers (e.g., Meta Cloud API, Twilio, 360dialog).
- Requires Facebook Business verification, templates approval, costs per message, and server-side integration (e.g., Supabase Edge Function or Cloud Function).

**Recommendation**: Start with **user-initiated share** (no extra infra).

---

## 9) Edge Cases & Regeneration
- **Voucher already exists**:
  - Default: **do not regenerate** automatically.
  - Provide a **"Regenerate"** menu item (guard with confirm).
  - Overwrite Storage path (`upsert: true`) or create a versioned path (e.g., `vouchers/{id}/voucher_v2.pdf`). If you version, store latest path in DB.
- **Missing fields**:
  - Show placeholders for non-critical fields.
  - If critical keys missing (e.g., `job_id`), **abort** with a clear error.
- **Logo missing**: omit logo container to avoid awkward spacing.
- **Transport empty**: render "No trip details available."

---

## 10) Performance & Caching
- Avoid re-fetching the same voucher data multiple times; cache in memory during the flow.
- Add a cache-buster (`?t=timestamp`) to public URLs after upload to avoid stale caching in viewers.

---

## 11) Acceptance Criteria (AC)

- **AC1**: From Manage Jobs, a job without a voucher shows a **Create Voucher** button.
- **AC2**: Tapping **Create Voucher** generates the PDF, uploads to Storage, and updates `jobs.voucher_pdf`.
- **AC3**: After success, the card shows a **Voucher Created** chip and **Open**/**Share** icons.
- **AC4**: **Open** launches the voucher URL in an appropriate viewer (mobile/web).
- **AC5**: **Share** opens a WhatsApp share flow (mobile: app; web: web.whatsapp.com).
- **AC6**: Errors are shown with actionable messages; user can retry.
- **AC7**: RLS/permissions prevent cross-tenant access to jobs or voucher files.
- **AC8**: Regeneration (if enabled) prompts confirmation and updates the stored file and link.

---

## 12) QA Checklist
- Create voucher → success path (mobile/web).
- View after navigation away and back (state restored).
- Share to WhatsApp with and without a pre-filled phone number.
- Invalid voucher id / missing job id.
- No logo / no transport rows.
- Storage upload failure (simulate network).
- DB update failure (RLS block or constraint).

---

## 13) Open Questions (please confirm)
1. **Voucher ID vs Job ID**: On the job card, do we have a **voucher_id** directly, or should the app resolve it from **job_id**?
2. **Storage privacy**: Keep using **public URLs** or switch to **private + signed URLs**?
3. **Regeneration**: Do you want a **Regenerate Voucher** action on created vouchers?
4. **Footer/T&Cs**: Should vouchers include **any footer or terms**, or keep them **clean** (no T&Cs)?
5. **WhatsApp prefill**: Do we have a **preferred phone field** (e.g., passenger or agent contact) to prefill when the user taps **Share**?
6. **Branding**: Any specific **fonts/colors** required for the PDF (brand typography)?
7. **Bucket & path**: Confirm bucket `pdfdocuments` and path `vouchers/voucher_<id>.pdf` (same as FlutterFlow). Should we **version** files on regeneration?
8. **Button copy**: Are the **button/label** texts final? (`Create Voucher`, `Open`, `Share`, `Voucher Created`)
9. **Viewer behavior**: Prefer in-app PDF viewer on mobile (e.g., `printing`/`open_filex`) or open in external browser?

---

## 14) Future Enhancements (optional)
- **Email** the voucher from the app (with template & attachments).
- **Audit trail** table (`voucher_logs`) with actions (created, viewed, shared).
- **Watermark** for non-admin roles or free plans.
- **Multi-language** support.
- **Role-based** restrictions for voucher creation.

---

## 15) Implementation Notes (Pseudo-Interfaces)

```dart
// Riverpod controller (sketch)
class VoucherController extends StateNotifier<AsyncValue<void>> {
  VoucherController(this._repo, this._pdf);

  final VoucherRepository _repo;
  final VoucherPdfService _pdf;

  Future<void> createForVoucherId(int jobId, int voucherId) async {
    state = const AsyncLoading();
    try {
      final data = await _repo.fetchVoucherData(voucherId: voucherId);
      final bytes = await _pdf.buildVoucherPdf(data);
      final url = await _repo.uploadAndLink(jobId: jobId, voucherId: voucherId, bytes: bytes);
      // Optionally return url or update a jobs provider to refresh the card.
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

// Repository (sketch)
abstract class VoucherRepository {
  Future<VoucherData> fetchVoucherData({required int voucherId});
  Future<String> uploadAndLink({required int jobId, required int voucherId, required Uint8List bytes});
  Future<String> getPublicOrSignedUrl(String path);
}
```

---

## 16) Dependencies
- `pdf`, `printing`, `http`
- `url_launcher` (open URL)
- `share_plus` (optional; platform share sheet)
- `intl` (date formatting)
- `flutter_riverpod` (state)

---

## 17) Risks
- Public URLs expose content to anyone with the link (privacy risk).
- WhatsApp Business API adds cost & compliance (if automated messages are required).
- Regeneration with the same path may be cached by clients; use cache-busters or versioned paths.

---

## 18) Glossary
- **Voucher**: A PDF confirmation document for a Job with itinerary and contact info.
- **Signed URL**: Time-limited URL for private Storage files.
- **RLS**: Row Level Security enforcing tenant isolation in Postgres.

---

## 19) IMPLEMENTATION TASK LIST

### Phase 1: Database & Backend Setup
- [ ] **Create Supabase RPC function** `get_voucher_data_for_pdf(p_voucher_id int)`
  - [ ] Implement SQL function to fetch voucher data with proper joins
  - [ ] Add RLS security checks for tenant isolation
  - [ ] Test with sample data
- [ ] **Verify Storage bucket setup**
  - [ ] Confirm `pdfdocuments` bucket exists
  - [ ] Set up proper RLS policies for voucher uploads
  - [ ] Test upload permissions
- [ ] **Add voucher_pdf column to jobs table** (if not exists)
  - [ ] Verify column exists and is nullable text
  - [ ] Add appropriate indexes if needed

### Phase 2: Data Models & Services
- [ ] **Create VoucherData model**
  - [ ] Define data structure matching RPC response
  - [ ] Add JSON serialization/deserialization
  - [ ] Include validation methods
- [ ] **Create VoucherRepository service**
  - [ ] Implement `fetchVoucherData({required int voucherId})`
  - [ ] Implement `uploadVoucherBytes({required int voucherId, required Uint8List bytes})`
  - [ ] Implement `linkVoucherUrlToJob({required int jobId, required String url})`
  - [ ] Implement `getPublicOrSignedUrl({required String storagePath})`
  - [ ] Add proper error handling and logging
- [ ] **Create VoucherPdfService**
  - [ ] Implement `buildVoucherPdf(VoucherData data)` method
  - [ ] Design PDF layout according to specifications
  - [ ] Add company logo support
  - [ ] Implement proper date formatting
  - [ ] Add error handling for PDF generation

### Phase 3: State Management
- [ ] **Create VoucherController (Riverpod)**
  - [ ] Implement state management for voucher creation process
  - [ ] Add loading, success, and error states
  - [ ] Implement retry functionality
  - [ ] Add proper error mapping to user-friendly messages
- [ ] **Update JobsProvider**
  - [ ] Ensure jobs include `voucher_pdf` field
  - [ ] Add refresh method after voucher creation
  - [ ] Update job card state management

### Phase 4: UI Components
- [ ] **Update JobCard widget**
  - [ ] Add voucher section to job card layout
  - [ ] Implement conditional UI based on `voucher_pdf` status
  - [ ] Add "Create Voucher" button for jobs without vouchers
  - [ ] Add "Voucher Created" status chip
  - [ ] Add "Open" and "Share" action buttons
  - [ ] Implement loading states during voucher creation
  - [ ] Add error states with retry options
- [ ] **Create VoucherActionButtons widget**
  - [ ] Implement "Open" button functionality
  - [ ] Implement "Share" button with WhatsApp integration
  - [ ] Add optional "Regenerate" menu item
  - [ ] Handle mobile vs web sharing differences

### Phase 5: PDF Generation
- [ ] **Implement PDF layout**
  - [ ] Create header with company name and logo
  - [ ] Add voucher metadata (date, voucher number)
  - [ ] Include agent and passenger information
  - [ ] Add driver and vehicle details
  - [ ] Create trip details table
  - [ ] Add notes section (optional)
  - [ ] Implement proper spacing and typography
- [ ] **Add PDF styling**
  - [ ] Use brand fonts (PdfGoogleFonts)
  - [ ] Implement A4 page format with 30pt margins
  - [ ] Add consistent spacing and 9-11pt text
  - [ ] Handle missing logo gracefully
  - [ ] Add proper date formatting

### Phase 6: Sharing & URL Handling
- [ ] **Implement URL opening**
  - [ ] Add `url_launcher` dependency
  - [ ] Handle mobile in-app viewer vs external browser
  - [ ] Implement web URL opening in new tab
  - [ ] Add proper error handling for URL opening
- [ ] **Implement WhatsApp sharing**
  - [ ] Add `share_plus` dependency
  - [ ] Create WhatsApp deep link generation
  - [ ] Handle mobile vs web WhatsApp sharing
  - [ ] Implement share message template
  - [ ] Add phone number prefill functionality
- [ ] **Add alternative sharing options**
  - [ ] Implement system share sheet for mobile
  - [ ] Add email sharing option
  - [ ] Handle cases where WhatsApp is not available

### Phase 7: Error Handling & Edge Cases
- [ ] **Implement comprehensive error handling**
  - [ ] Map database errors to user-friendly messages
  - [ ] Handle network connectivity issues
  - [ ] Add retry mechanisms for transient failures
  - [ ] Implement proper error logging
- [ ] **Handle edge cases**
  - [ ] Missing voucher data fields
  - [ ] Empty transport details
  - [ ] Missing company logo
  - [ ] Invalid voucher IDs
  - [ ] Storage upload failures
  - [ ] Database update failures
- [ ] **Add regeneration functionality**
  - [ ] Implement "Regenerate Voucher" option
  - [ ] Add confirmation dialog
  - [ ] Handle file versioning or overwriting
  - [ ] Update database with new URL

### Phase 8: Testing & Quality Assurance
- [ ] **Unit tests**
  - [ ] Test VoucherData model serialization
  - [ ] Test VoucherRepository methods
  - [ ] Test VoucherPdfService PDF generation
  - [ ] Test VoucherController state management
- [ ] **Integration tests**
  - [ ] Test end-to-end voucher creation flow
  - [ ] Test PDF upload and database linking
  - [ ] Test URL opening and sharing
  - [ ] Test error scenarios
- [ ] **Manual testing**
  - [ ] Test on Android device
  - [ ] Test on web browser
  - [ ] Test with various data scenarios
  - [ ] Test WhatsApp sharing on mobile and web
  - [ ] Test error handling and retry functionality

### Phase 9: Performance & Optimization
- [ ] **Add caching mechanisms**
  - [ ] Cache voucher data during creation flow
  - [ ] Implement memory caching for frequently accessed data
  - [ ] Add cache-busting for PDF URLs
- [ ] **Optimize PDF generation**
  - [ ] Optimize PDF file size
  - [ ] Implement async PDF generation
  - [ ] Add progress indicators for large PDFs
- [ ] **Add performance monitoring**
  - [ ] Track voucher creation times
  - [ ] Monitor PDF file sizes
  - [ ] Add performance logging

### Phase 10: Documentation & Deployment
- [ ] **Update documentation**
  - [ ] Document new voucher functionality
  - [ ] Update API documentation
  - [ ] Add troubleshooting guide
- [ ] **Prepare for deployment**
  - [ ] Test on production environment
  - [ ] Verify Supabase RPC functions
  - [ ] Test storage permissions
  - [ ] Validate RLS policies
- [ ] **Create user guide**
  - [ ] Document voucher creation process
  - [ ] Explain sharing functionality
  - [ ] Add FAQ section

### Phase 11: Security & Compliance
- [ ] **Implement security measures**
  - [ ] Verify RLS policies for voucher access
  - [ ] Implement proper authentication checks
  - [ ] Add audit logging for voucher actions
  - [ ] Secure PDF storage and access
- [ ] **Add compliance features**
  - [ ] Implement data retention policies
  - [ ] Add user consent for sharing
  - [ ] Ensure GDPR compliance for data handling

### Phase 12: Final Testing & Launch
- [ ] **Comprehensive testing**
  - [ ] Test all acceptance criteria
  - [ ] Perform security testing
  - [ ] Test performance under load
  - [ ] Validate all error scenarios
- [ ] **User acceptance testing**
  - [ ] Test with real users
  - [ ] Gather feedback on UX
  - [ ] Validate business requirements
- [ ] **Launch preparation**
  - [ ] Prepare release notes
  - [ ] Plan user training
  - [ ] Monitor initial usage
  - [ ] Plan post-launch support

---

## 20) IMPLEMENTATION QUESTIONS TO RESOLVE

### ✅ RESOLVED QUESTIONS (Based on User Answers):

1. **Voucher ID Resolution**: ✅ **RESOLVED** - Use existing RPC `get_voucher_data_for_pdf(p_voucher_id)` with job_id → voucher_id mapping
2. **Storage Strategy**: ✅ **RESOLVED** - Use public URLs in `pdfdocuments` bucket under `vouchers/` path
3. **PDF Branding**: ✅ **RESOLVED** - Use existing FlutterFlow PDF layout as reference
4. **WhatsApp Integration**: ✅ **RESOLVED** - Use agent contact number, with fallback to alternative number option
5. **Regeneration Policy**: ✅ **RESOLVED** - Allow regeneration, replace old files (upsert: true)
6. **Access Control**: ✅ **RESOLVED** - Administrators, Managers, Driver Managers can create vouchers
7. **PDF Viewer**: ✅ **RESOLVED** - External browser (recommended for better compatibility)
8. **Error Handling**: ✅ **RESOLVED** - Use existing FlutterFlow error handling patterns
9. **File Naming**: ✅ **RESOLVED** - `voucher_<voucher_id>.pdf` in `vouchers/` path
10. **Dependencies**: ✅ **RESOLVED** - Use existing packages: `pdf`, `printing`, `http`, `intl`, `url_launcher`, `share_plus`

### **IMPLEMENTATION APPROACH:**
- **Adapt existing FlutterFlow code** to Flutter/Riverpod architecture
- **Maintain same PDF layout** and styling
- **Use existing RPC function** `get_voucher_data_for_pdf`
- **Keep public storage strategy** for simplicity
- **Implement role-based access control** for voucher creation

---

## 21) STREAMLINED IMPLEMENTATION TASK LIST

### Phase 1: Database & Backend Setup (1-2 days) ✅
- [x] **Verify existing RPC function** `get_voucher_data_for_pdf(p_voucher_id int)`
  - [x] Test with sample voucher data
  - [x] Verify RLS security checks
  - [x] Confirm data structure matches FlutterFlow expectations
- [x] **Verify Storage bucket setup**
  - [x] Confirm `pdfdocuments` bucket exists and is public
  - [x] Test upload permissions for `vouchers/` path
  - [x] Verify `jobs.voucher_pdf` column exists
- [x] **Create voucher_id resolver** (if needed)
  - [x] Add RPC `get_voucher_id_for_job(p_job_id)` or
  - [x] Modify existing RPC to accept `job_id` parameter

### Phase 2: Data Models & Services (1-2 days) ✅
- [x] **Create VoucherData model**
  - [x] Define structure matching RPC response
  - [x] Add JSON serialization/deserialization
  - [x] Include helper methods for data formatting
- [x] **Create VoucherRepository service**
  - [x] Adapt FlutterFlow Supabase calls to Flutter
  - [x] Implement `fetchVoucherData({required int voucherId})`
  - [x] Implement `uploadVoucherBytes({required int voucherId, required Uint8List bytes})`
  - [x] Implement `linkVoucherUrlToJob({required int jobId, required String url})`
  - [x] Add proper error handling and logging
- [x] **Create VoucherPdfService**
  - [x] **Adapt existing FlutterFlow PDF generation code**
  - [x] Convert to Flutter `pdf` package syntax
  - [x] Maintain same layout, styling, and sections
  - [x] Keep logo handling and error fallbacks
  - [x] Preserve terms & conditions section

### Phase 3: State Management (1 day) ✅
- [x] **Create VoucherController (Riverpod)**
  - [x] Implement state management for voucher creation
  - [x] Add loading, success, and error states
  - [x] Implement retry functionality
  - [x] Add role-based access control checks
- [x] **Update JobsProvider**
  - [x] Ensure jobs include `voucher_pdf` field
  - [x] Add refresh method after voucher creation
  - [x] Update job card state management

### Phase 4: UI Components (2-3 days) ✅
- [x] **Update JobCard widget**
  - [x] Add voucher section to existing job card layout
  - [x] Implement conditional UI based on `voucher_pdf` status
  - [x] Add "Create Voucher" button for jobs without vouchers
  - [x] Add "Voucher Created" status chip
  - [x] Add "Open" and "Share" action buttons
  - [x] Implement loading states during voucher creation
  - [x] Add error states with retry options
- [x] **Create VoucherActionButtons widget**
  - [x] Implement "Open" button (external browser)
  - [x] Implement "Share" button with WhatsApp integration
  - [x] Add "Regenerate" menu item with confirmation
  - [x] Handle mobile vs web sharing differences
  - [x] Use agent contact number with fallback option

### Phase 5: PDF Generation (2-3 days) ✅
- [x] **Adapt FlutterFlow PDF code to Flutter**
  - [x] Convert `pw.MultiPage` structure to Flutter `pdf` package
  - [x] Maintain header with company name and logo
  - [x] Keep voucher metadata (date, voucher number)
  - [x] Preserve agent and passenger information sections
  - [x] Maintain driver and vehicle details
  - [x] Keep trip details table with same styling
  - [x] Preserve notes section and terms & conditions
- [x] **Implement PDF styling**
  - [x] Use same fonts and styling as FlutterFlow
  - [x] Maintain A4 page format with 30pt margins
  - [x] Keep consistent spacing and text sizes
  - [x] Handle missing logo gracefully
  - [x] Preserve date formatting logic

### Phase 6: Sharing & URL Handling (1-2 days) ✅
- [x] **Implement URL opening**
  - [x] Add `url_launcher` dependency
  - [x] Open PDF URLs in external browser
  - [x] Add proper error handling for URL opening
- [x] **Implement WhatsApp sharing**
  - [x] Add `share_plus` dependency
  - [x] Create WhatsApp deep link generation
  - [x] Use agent contact number as primary, with fallback option
  - [x] Implement share message template
  - [x] Handle mobile vs web WhatsApp sharing
- [x] **Add alternative sharing options**
  - [x] Implement system share sheet for mobile
  - [x] Handle cases where WhatsApp is not available

### Phase 7: Error Handling & Edge Cases (1 day) ✅
- [x] **Implement comprehensive error handling**
  - [x] Adapt FlutterFlow error handling patterns
  - [x] Map database errors to user-friendly messages
  - [x] Handle network connectivity issues
  - [x] Add retry mechanisms for transient failures
- [x] **Handle edge cases**
  - [x] Missing voucher data fields
  - [x] Empty transport details
  - [x] Missing company logo
  - [x] Invalid voucher IDs
  - [x] Storage upload failures
  - [x] Database update failures
- [x] **Add regeneration functionality**
  - [x] Implement "Regenerate Voucher" option
  - [x] Add confirmation dialog
  - [x] Use `upsert: true` to replace old files
  - [x] Update database with new URL

### Phase 8: Testing & Quality Assurance (1-2 days)
- [ ] **Unit tests**
  - [ ] Test VoucherData model serialization
  - [ ] Test VoucherRepository methods
  - [ ] Test VoucherPdfService PDF generation
  - [ ] Test VoucherController state management
- [ ] **Integration tests**
  - [ ] Test end-to-end voucher creation flow
  - [ ] Test PDF upload and database linking
  - [ ] Test URL opening and sharing
  - [ ] Test error scenarios
- [ ] **Manual testing**
  - [ ] Test on Android device
  - [ ] Test on web browser
  - [ ] Test with various data scenarios
  - [ ] Test WhatsApp sharing on mobile and web
  - [ ] Test regeneration functionality

### Phase 9: Performance & Optimization (1 day)
- [ ] **Add caching mechanisms**
  - [ ] Cache voucher data during creation flow
  - [ ] Add cache-busting for PDF URLs (already in FlutterFlow code)
- [ ] **Optimize PDF generation**
  - [ ] Optimize PDF file size
  - [ ] Implement async PDF generation
  - [ ] Add progress indicators for large PDFs

### Phase 10: Documentation & Deployment (1 day)
- [ ] **Update documentation**
  - [ ] Document new voucher functionality
  - [ ] Update API documentation
  - [ ] Add troubleshooting guide
- [ ] **Prepare for deployment**
  - [ ] Test on production environment
  - [ ] Verify Supabase RPC functions
  - [ ] Test storage permissions
  - [ ] Validate RLS policies

---

## 22) KEY IMPLEMENTATION NOTES

### **Permission Configuration:**
The voucher system allows the following user roles to create vouchers:
- **Administrator** (`administrator` or `admin`)
- **Manager** (`manager`)
- **Driver Manager** (`driver_manager`)

The system handles role variations automatically to ensure compatibility with different role naming conventions in the database.

### **Code Adaptation Strategy:**
1. **Use existing FlutterFlow code as reference** - Your PDF generation is already well-structured
2. **Convert syntax** from FlutterFlow to Flutter `pdf` package
3. **Maintain same layout and styling** - No need to redesign
4. **Keep error handling patterns** - Your current error handling is comprehensive
5. **Preserve business logic** - Same data flow and validation

### **Dependencies to Add:**
```yaml
dependencies:
  pdf: ^3.10.7
  printing: ^5.11.1
  url_launcher: ^6.2.4
  share_plus: ^7.2.1
  intl: ^0.19.0
```

### **Role-Based Access Control:**
```dart
// Check user role before allowing voucher creation
bool canCreateVoucher(String userRole) {
  return ['admin', 'manager', 'driver_manager'].contains(userRole);
}
```

### **WhatsApp Sharing Logic:**
```dart
// Use agent contact number with fallback
String getPreferredPhoneNumber(VoucherData data) {
  return data.agentContact.isNotEmpty 
    ? data.agentContact 
    : data.passengerContact;
}
```

### **Estimated Timeline: 8-12 days**
- **Phase 1-2**: 3-4 days (Database & Services)
- **Phase 3-4**: 3-4 days (State Management & UI)
- **Phase 5-6**: 3-5 days (PDF Generation & Sharing)
- **Phase 7-10**: 2-3 days (Testing & Deployment)

This approach leverages your existing working code while adapting it to the Flutter/Riverpod architecture, significantly reducing development time and risk.
