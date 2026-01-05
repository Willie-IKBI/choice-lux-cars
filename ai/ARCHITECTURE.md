🧱 Choice Lux Cars — Architecture Guide

Audience: Cursor Architecture Agent (CLC-ARCH)
Status: Canonical reference for architectural decisions

1. Architecture Mission

The purpose of this architecture is to:

Stabilize a production app originally built in FlutterFlow

Transition to clean Flutter + Riverpod without breaking functionality

Enforce security, correctness, and maintainability

Support long-term growth without rewrites

This architecture prioritizes practicality over purity.

2. Architectural Principles (Non-Negotiable)
2.1 Incremental Refactor Only

No “big bang” rewrites

App must compile and run after every batch

Refactors are batch-scoped and reversible

2.2 Backend Is the Source of Truth

Supabase RLS enforces all access rules

Frontend never assumes permission

UI guards are convenience, not security

2.3 Single Responsibility by Layer

UI renders state

Controllers manage orchestration

Services perform IO

Models are dumb data

2.4 No Logic in Widgets

Widgets may format or delegate

No database calls

No business rules

No permission logic

3. Target Architecture Overview
Layered Responsibility Model
UI (Widgets / Screens)
   ↓
State / Controllers (Riverpod)
   ↓
Services (Supabase, PDF, FCM)
   ↓
Backend (Supabase Auth, DB, RLS)


Each layer:

Depends downwards only

Cannot bypass the layer below it

4. Folder Structure (Authoritative)
lib/
├── app/                 # App bootstrap & globals
│   ├── app.dart
│   ├── router.dart
│   ├── theme.dart
│   └── providers.dart
│
├── core/                # Cross-cutting concerns
│   ├── constants.dart
│   ├── utils.dart
│   └── services/
│       ├── supabase_service.dart
│       ├── auth_service.dart
│       ├── fcm_service.dart
│       └── pdf_service.dart
│
├── features/            # Vertical slices
│   ├── auth/
│   ├── jobs/
│   ├── quotes/
│   ├── invoices/
│   ├── vouchers/
│   ├── clients/
│   ├── vehicles/
│   └── notifications/
│
├── shared/              # Reusable UI only
│   ├── widgets/
│   └── layout/
│
└── main.dart

5. Dependency Rules (Strict)
Allowed Imports
From	Can Import
features/*	core, shared
core	dart / flutter only
shared	flutter only
app	everything
widgets	controllers via providers only
Forbidden Imports

features/* → features/other_feature/*

widgets → services

widgets → Supabase / Firebase

services → UI or Riverpod

Circular feature dependencies

Violations must be flagged by CLC-REVIEW.

6. State Management Rules (Riverpod)
Approved Patterns

StateNotifier / StateNotifierProvider

AsyncNotifier where async lifecycle is dominant

Prohibited

Mixed Provider + Riverpod

Global mutable state

Controllers stored in widgets

Controller Responsibilities

Load data

Transform data

Handle errors

Expose immutable state to UI

Controllers do not:

Render UI

Perform raw SQL

Access Firebase directly

7. Supabase Architecture Rules
Auth

All users have a profiles row

Role stored as enum: admin | manager | driver | driver_manager

Role checks:

Enforced in RLS

Reflected in UI routing

Database

No frontend writes without RLS

No trusting user.role in UI

All mutations must be auditable

Storage

PDFs and images uploaded via service

Bucket permissions enforced via RLS

Public URLs stored in DB only after successful upload

8. Push Notification Architecture
Rules

Frontend:

Requests permission

Retrieves token

Updates profiles.fcm_token

Backend:

Edge Functions send notifications

Role-based targeting only

Prohibited

Hardcoded tokens

Direct FCM sends from UI

Notification logic inside widgets

9. PDF Architecture
Centralization

All PDF generation via pdf_service.dart

Quotes, invoices, vouchers share base layout

Overrides must be explicit and minimal

Flow

Build PDF

Upload to Supabase Storage

Save public URL

Expose to UI

No feature builds PDFs independently.

10. Migration Rules (FlutterFlow → Clean Flutter)
Must Be Removed

lib/flutter_flow/

*_model.dart

FlutterFlow page wrappers

Generated FF helpers

Allowed Temporarily

Custom actions rewritten as services

Table models adapted into domain models

11. Batch Refactor Governance
Batch Size

One concern per batch

≤ ~10 files where possible

App must compile after each batch

Batch Priority Order

P0 — Crashers, auth, security

P1 — Broken flows, incorrect logic

P2 — Maintainability, duplication

P3 — UX polish

12. Architecture Agent Authority

The CLC-ARCH agent:

Owns architectural decisions

Defines batch plans

Sets acceptance criteria

Rejects scope creep

The agent must not:

Implement code

Fix UI bugs directly

Override security requirements for convenience

13. Definition of Architectural Success

The architecture is considered successful when:

The app is stable on Android + Web

Role enforcement is airtight

PDFs and notifications are reliable

New features fit naturally into existing structure

No future rebuild is required to scale

14. Final Rule

If a change makes the app harder to reason about, it is architecturally wrong — even if it “works.”