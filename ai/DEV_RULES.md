DEV_RULES.md — Choice Lux Cars Guardrails

Applies to: all contributors and Cursor Agents (CLC-ARCH, CLC-BUILD, CLC-REVIEW)
Goal: prevent regressions, security gaps, and architectural drift while migrating to clean Flutter.

1) Non-Negotiables

App must compile after every batch
No multi-day broken branches.

No business logic in widgets
UI renders state and delegates actions only.

RLS is authoritative
Frontend role checks are UX guards, not security.

No feature-to-feature imports
Features are isolated vertical slices.

No “drive-by refactors”
Only change what the batch scope requires.

2) Batch Workflow Rules
2.1 Required Loop

CLC-ARCH defines a batch scope + acceptance criteria

CLC-BUILD implements the batch

CLC-REVIEW approves or blocks

Only then proceed

2.2 Batch Size Constraints

Prefer ≤ 10 files touched

One concern per batch (stability OR security OR refactor OR UI polish)

Must include validation steps

2.3 Commit Discipline (Required)

Each batch must be committable with:

Clear message: CLC: <batch> - <change>

Summary of changes

Manual test checklist

3) Architecture Guardrails
3.1 Folder Boundaries (Authoritative)

Use and enforce:

lib/
  app/
  core/
  features/
  shared/

3.2 Dependency Rules

Allowed imports:

features/* → core/*, shared/*

shared/* → Flutter SDK only

core/* → Dart/Flutter SDK + external SDKs (Supabase/Firebase/pdf)

app/* → may import all

Forbidden imports:

features/* → features/other_feature/*

shared/* → core/* or features/*

core/* → features/* or shared/widgets/* (no UI in core)

Any circular dependency

3.3 Where Code Must Live

Widgets: layout, rendering, formatting only

Controllers/Notifiers: orchestration, validation, state

Services: IO calls (Supabase/Firebase/Storage/PDF)

Models: data-only, no side effects

4) State Management Rules (Riverpod)
4.1 Approved

StateNotifier / StateNotifierProvider

AsyncNotifier / AsyncNotifierProvider for async lifecycle

4.2 Prohibited

Mixing Provider/ChangeNotifier with Riverpod (unless in a transitional batch explicitly approved by ARCH)

Global mutable state

Controllers stored inside widgets

Calling Supabase directly from UI

4.3 Controller Rules

Controllers must:

expose immutable state

handle loading/error/empty states

validate inputs

translate exceptions into UI-safe errors

Controllers must NOT:

build widgets

contain layout logic

embed raw JSON mapping in UI

5) Supabase Security Rules
5.1 Never Trust the Frontend

Role checks in UI are convenience only

All data access must succeed/fail based on RLS

5.2 Required for All Queries

Use authenticated Supabase client

Ensure every table query is scoped by business/role constraints

Avoid wildcard selects that overfetch

5.3 RLS Rules

RLS must be ON for sensitive tables

Policies must enforce:

ownership (user_id / business_id)

role constraints (admin/manager/driver/driver_manager)

Any changes to policies require:

migration script

rollback notes

test queries documented

5.4 Storage Rules

Buckets must not be globally public unless intentionally designed

Public URLs stored in DB only after successful upload

Filenames must be deterministic and scoped:

<entity>/<entityId>/<timestamp>_<type>.pdf

<jobs>/<jobId>/pickup_*.jpg, <jobs>/<jobId>/dropoff_*.jpg

6) Notification (FCM) Guardrails
6.1 Token Management

On login/startup:

request permission (where applicable)

fetch token

upsert into profiles.fcm_token

Never hardcode tokens

Never store tokens outside profiles

6.2 Sending Notifications

Send via Supabase Edge Functions only (preferred)

Role targeting must be backend-driven (query by role + business scope)

UI must not contain notification routing logic beyond “call edge function”

6.3 Foreground Handling

Foreground handlers must not navigate automatically

Display in-app banner/toast and allow user action

7) PDF Generation Guardrails
7.1 Single Source of Truth

All PDF generation must go through one service:

core/services/pdf_service.dart (or equivalent)

Quotes/Invoices/Vouchers share base layout

Voucher is quote variant:

no pricing

no T&Cs

7.2 Upload Workflow

Generate bytes

Upload to Supabase Storage

Get public URL (or signed URL if required)

Persist URL in DB

Only then expose to UI

7.3 UI Rules for PDFs

UI may:

trigger generate/upload via controller

preview/download/share

UI may NOT:

construct PDF layout

upload directly to storage

8) Error Handling & Logging
8.1 Required Patterns

Every async operation must surface:

loading state

error state

empty state (when applicable)

8.2 User-Facing Errors

Use clean, actionable messages

No raw exception dumps in UI

Log technical details separately

8.3 Logging Rules

Log at service/controller boundaries

Never log:

access tokens

refresh tokens

passwords

full PII records

9) UI / Theming Guardrails (Material 3)

All screens must use the central theme (ChoiceLuxTheme)

No hardcoded colors unless explicitly defined in theme tokens

Reusable UI components belong in shared/widgets

Responsive design required:

mobile first

web adapts via LayoutBuilder / breakpoints

10) Naming & Code Quality Rules
10.1 Naming

Files: snake_case.dart

Classes: PascalCase

Providers: <feature><Thing>Provider or ...NotifierProvider

Services: <Thing>Service

10.2 Linting

No new lint warnings introduced

Remove unused imports/vars in touched files

10.3 No Mega Files

If a file exceeds ~400 lines, split into:

screen + widgets

controller + state

service + helpers

11) Database Change Rules

No schema changes without:

migration script in repo

rollback script

updated docs (DATA_SCHEMA.md if present)

No “quick changes” directly in production console

12) Release / Environment Guardrails

All secrets in environment variables, not committed

Web redirects/URLs must be environment-specific

Verify:

Supabase URL + anon key

Firebase config (web + android)

Hosting settings (if applicable)

13) Required Validation Checklist (Per Batch)

Every batch must include a checklist like:

 App launches (Android + Web if touched)

 Login works

 Role guard works (admin vs driver)

 Main flow tested (jobs/quotes/invoices/vouchers depending on scope)

 No new errors in console

 If PDF touched: generate + upload + open

 If notifications touched: token updates + test send

14) Enforcement

CLC-REVIEW must block any change that violates Sections 1–6.

CLC-ARCH must keep scope tight and reject “nice-to-have” drift.

CLC-BUILD must not exceed approved batch scope.