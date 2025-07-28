
# 📋 Project Requirements Document

## 🏷️ Project Name
**Choice Lux Cars – Mobile and Web App**

---

## 🧭 Project Overview

Choice Lux Cars is a digital platform built to streamline operations for a luxury car rental business. The application will manage bookings, quotes, invoices, vehicle logistics, user roles, notifications, and client data. The app will be rebuilt using clean Flutter architecture with Riverpod, Material 3, and Supabase for database/auth/storage, targeting both Android and Web platforms (mobile and desktop responsive).

---

## 🧩 Technology Stack

### 🔹 Frontend
- Flutter (3.22+)
- Material 3
- Riverpod (State Management)
- GoRouter (Routing)
- Firebase Cloud Messaging (Push Notifications)

### 🔹 Backend
- Supabase (Auth, Postgres DB, RLS, Storage)
- Firebase (FCM integration)

### 🔹 Tools
- Cursor / VS Code
- GitHub (Version Control)
- Firebase Hosting (Web Deployment)
- Supabase CLI (Schema Migrations & Edge Functions)

---

## 📱 Target Platforms

- Android (mobile)
- Web (responsive for mobile and desktop)

---

## 🔐 Authentication & Authorization

- Supabase Auth with email/password
- `profiles` table to track:
  - `id`, `role`, `display_name`, `fcm_token`
- Roles:
  - Admin
  - Manager
  - Driver
  - Driver Manager
- RLS to restrict access by role
- FCM token update after login

---

## 📦 Core Functional Requirements

### 1. **Client Management** ✅ **COMPLETED**
- Add/edit clients with:
  - Business details (company name, logo)
  - Contact person information
  - Email, phone, address
  - Company logo upload to Supabase Storage
- View client profile and activity history
- Search and filter clients
- **Soft Delete Implementation** ✅ **COMPLETED**
  - Deactivate clients instead of permanent deletion
  - Preserve all related data (quotes, invoices, agents)
  - Status management (Active, Pending, VIP, Inactive)
  - Restore functionality for deactivated clients
  - Inactive clients management screen
  - Data integrity protection
- **Agent Management** ✅ **NEWLY COMPLETED**
  - Add/edit agents linked to clients
  - Agent contact information (name, phone, email)
  - View agents within client detail screen
  - Manage client-agent relationships
  - Agent CRUD operations with responsive UI
  - Agent cards with hover effects and action buttons
  - Proper navigation between client and agent screens
  - Agent deletion with confirmation dialogs
  - Client detail screen with agents tab integration
- **Client Edit Functionality** ✅ **NEWLY COMPLETED**
  - Fixed client edit button navigation issue
  - Implemented proper client data loading for edit mode
  - Created EditClientScreen wrapper for async data handling
  - Added loading, error, and success states
  - Form pre-population with existing client data
  - Proper update functionality instead of creating new clients

### 2. **Quotes**
- Create/edit/delete quotes
- Add line items with:
  - Description, quantity, price, VAT toggle
- Generate quote PDF and upload to Supabase Storage
- Attach photos to quotes
- Limit to 5 quotes for free users (upgrade for more)

### 3. **Jobs**
- Convert quote to job
- Assign driver and vehicle
- Track job status (pickup, en route, delivered)
- Upload delivery/pickup photos

### 4. **Invoices**
- Generate invoice from completed job
- PDF generation and storage
- Link to client record

### 5. **Vouchers**
- Similar to quote, but:
  - No pricing
  - No terms & conditions
- Generate and store PDF

### 6. **Vehicles**
- Add/edit vehicle records
- View assigned vehicles per job

### 7. **User Management**
- Add/edit users
- Assign roles
- View/update user profiles

### 8. **Push Notifications**
- Use Firebase Cloud Messaging
- Triggered via Supabase Edge Functions
- Send updates on job assignments and status
- Role-specific delivery (e.g., only notify drivers)

### 9. **Dashboard**
- Admin: total jobs, open quotes, active drivers
- Driver: assigned jobs
- Manager: fleet activity, summary reports

---

## 🧱 Non-Functional Requirements

- Responsive UI for web (mobile and desktop)
- Modern Material 3 design
- Offline fallback handling (planned future feature)
- Secure file uploads with Supabase Storage
- Modular codebase for scalability
- Use of Riverpod for testable, maintainable state

---

## 🗂️ Suggested Folder Structure

```plaintext
lib/
├── app/                # Routing, theming, ProviderScope
├── core/               # Services, constants, helpers
├── features/           # Feature modules: quotes, jobs, etc.
├── shared/             # Widgets, layout, utils
└── main.dart
```

---

## 🚀 Deliverables

- Fully functioning Flutter app for Android and Web
- Role-based dashboards and features
- PDF generation and delivery flow (quotes, invoices, vouchers)
- Push notification integration
- Supabase secure backend (Auth, DB, Storage)
- Firebase Hosting deployment (web)
- GitHub project with version control
- Migration of all critical FlutterFlow logic into Riverpod

---

## 📆 Timeline (Suggested Phases)

1. ✅ Project setup and auth – 2 days  
2. ✅ **Client Management System** – 4 days (Completed)
   - Client CRUD operations
   - Agent management with full integration
   - Company logo upload
   - Search and filtering
   - **Soft delete implementation**
   - **Data integrity protection**
   - **Agent-client relationship management**
   - **Client edit functionality fixes**
3. Quote module – 3 days  
4. Job + Invoice modules – 3 days  
5. Vehicles + User management – 2 days  
6. Notifications + Dashboard – 2 days  
7. UI/UX polish, testing, deployment – 3 days

> ⚠️ Timeline is adjustable based on team size and testing cycles.

---

## ✅ Success Criteria

- All features from the original FlutterFlow app fully migrated
- Role-based access control enforced
- Functionality tested on Android and modern browsers
- Clean, responsive UI using Material 3
- All major business workflows supported and operational

---

## 🔧 Technical Implementation Details

### Client Management System Architecture
- **Data Models**: Client and Agent models with proper relationships
- **State Management**: Riverpod providers for clients and agents
- **Database Integration**: Supabase service with CRUD operations
- **UI Components**: Responsive cards with luxury design
- **Navigation**: Go Router with parameter support
- **File Upload**: Supabase Storage for company logos
- **Soft Delete**: Status-based deactivation with data preservation

### Agent-Client Integration
- **Relationship**: Agents linked to clients via `client_key` foreign key
- **UI Integration**: Agents tab in client detail screen
- **CRUD Operations**: Full create, read, update, delete functionality
- **Navigation**: Seamless flow between client and agent management
- **Responsive Design**: Mobile-optimized agent cards and forms

### Client Edit Functionality
- **Async Data Loading**: EditClientScreen wrapper for proper data fetching
- **Form Pre-population**: Existing client data loaded into edit form
- **State Management**: Proper loading, error, and success states
- **Update Logic**: Correctly updates existing client instead of creating new
- **User Experience**: Smooth navigation and feedback

