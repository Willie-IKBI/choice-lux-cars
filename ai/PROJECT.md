🚗 Choice Lux Cars — Project Definition

Audience: Cursor Agents (CLC-ARCH, CLC-BUILD, CLC-REVIEW)
Status: Single source of truth for project scope and intent

1. Project Summary

Choice Lux Cars is a production-grade, mobile-first operations platform for a luxury vehicle rental company.

The system supports admins, managers, driver managers, and drivers to coordinate jobs, vehicles, documents, and notifications in real time using a secure, role-based architecture.

This repository represents a FlutterFlow-originated application that is being systematically rebuilt and hardened using clean Flutter architecture, Riverpod, and Supabase.

2. Core Objectives

Agents must optimize for the following objectives in this order:

Stability – App must compile and run after every batch

Security – RLS, auth, storage, and notifications must be airtight

Correctness – Jobs, quotes, invoices, vouchers must behave as expected

Maintainability – Clear boundaries, minimal duplication

Scalability – Architecture must support future growth without rewrites

3. Target Stack (Non-Negotiable)
Frontend

Flutter (v3.22+)

Material 3

Riverpod (v2+)

GoRouter

Backend

Supabase (Auth, Postgres, RLS, Storage)

Supabase Edge Functions

Notifications

Firebase Cloud Messaging (FCM)

Documents

pdf + printing packages

Supabase Storage (public URLs persisted in DB)

4. User Roles
Role	Description
admin	Full system control
manager	Operational control
driver_manager	Driver oversight
driver	Assigned jobs only

Roles are:

Stored in profiles.role

Enforced by Supabase RLS

Reflected in frontend routing and UI

Frontend role checks are not security mechanisms.

5. Functional Scope
In Scope

Authentication & role-based access

Job lifecycle management

Quote, invoice, and voucher PDF generation

Vehicle and client management

Push notifications (role-based)

Mobile + web responsive UI

Supabase storage integration

Clean Flutter architecture migration

Explicitly Out of Scope

FlutterFlow runtime dependencies

Offline-first sync (future phase)

Multi-tenant SaaS abstraction

UI redesign without functional justification

6. Core Feature Modules

Agents must treat these as vertical slices:

Auth

Dashboard

Jobs

Quotes

Invoices

Vouchers

Clients

Vehicles

User Management

Notifications

Each feature:

Owns its screens, controllers, models

Must not depend on other features directly

7. Architecture Expectations

Clean, layered Flutter architecture

Business logic lives outside widgets

Services handle IO only

Riverpod manages state deterministically

Supabase is the system of record

See ARCHITECTURE.md for binding rules.

8. Migration Context

This project:

Originated in FlutterFlow

Contains legacy artifacts that must be removed

Is being rebuilt incrementally

Must Be Removed

lib/flutter_flow/

*_model.dart

Generated FF helpers and wrappers

Allowed Temporarily

Refactored custom actions as services

Transitional adapters during batch refactors

9. Agent Responsibilities
CLC-ARCH

Define architecture and boundaries

Produce refactor batch plans

Identify P0–P3 risks

Prevent scope creep

CLC-BUILD

Implement only approved batches

Keep diffs small and reversible

Ensure app compiles after each batch

CLC-REVIEW

Gate quality, security, and correctness

Block architectural violations

Prevent regressions

No agent may operate outside its role.

10. Batch-Based Workflow (Mandatory)

All changes must follow this loop:

CLC-ARCH defines batch scope + acceptance criteria

CLC-BUILD implements the batch

CLC-REVIEW approves or blocks

Only then may the next batch begin

No parallel refactors.

11. Quality Gates

Before a batch is considered complete:

App builds successfully

No new lints or runtime warnings introduced

Role access remains correct

PDFs generate and upload successfully (if touched)

Notifications still fire (if touched)

12. Definition of “Done”

The project is considered complete when:

FlutterFlow artifacts are fully removed

Clean architecture is consistently applied

All core workflows function end-to-end

Security is enforced at the backend

Codebase is readable, predictable, and extensible

13. Final Rule

If a change improves speed today but increases confusion tomorrow, it is rejected.

This document overrides assumptions, preferences, and convenience.