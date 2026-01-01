# Data Schema Documentation

This document provides a comprehensive overview of the Choice Lux Cars database schema, including tables, columns, constraints, foreign keys, and Row Level Security (RLS) policies.

**Last Updated:** Current state as of documentation generation

## Table of Contents

- [Overview](#overview)
- [Tables](#tables)
  - [agents](#agents)
  - [app_notifications](#app_notifications)
  - [app_version](#app_version)
  - [branches](#branches)
  - [client_branches](#client_branches)
  - [clients](#clients)
  - [device_tokens](#device_tokens)
  - [driver_flow](#driver_flow)
  - [expenses](#expenses)
  - [invoices](#invoices)
  - [job_notification_log](#job_notification_log)
  - [jobs](#jobs)
  - [login_attempts](#login_attempts)
  - [notification_delivery_log](#notification_delivery_log)
  - [notifications_backup](#notifications_backup)
  - [profiles](#profiles)
  - [quotes](#quotes)
  - [quotes_transport_details](#quotes_transport_details)
  - [transport](#transport)
  - [trip_progress](#trip_progress)
  - [user_notification_preferences](#user_notification_preferences)
  - [vehicles](#vehicles)

## Overview

All tables have Row Level Security (RLS) enabled. The database uses role-based access control with the following user roles:
- `administrator` - Full system access
- `manager` - Management-level access
- `driver_manager` - Driver management access
- `driver` - Driver-level access
- `suspended` - Suspended users
- `super_admin` - Super administrator access

---

## Tables

### agents

**Purpose:** Stores agent information for client relationships and job assignments.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| agent_name | text | YES | - | Agent name |
| client_key | bigint | YES | - | Client reference key |
| contact_number | text | YES | - | Contact phone number |
| contact_email | text | YES | - | Contact email address |
| created_at | timestamptz | NO | now() | Creation timestamp |
| updated_at | timestamptz | NO | now() | Last update timestamp |
| is_deleted | boolean | NO | false | Soft delete flag |

**Primary Key:** `id`

**Foreign Keys:**
- `jobs.agent_id` → `agents.id`
- `quotes.agent_id` → `agents.id`

**RLS Status:** Enabled

**RLS Policies:**
- **All authenticated users:** Full access (ALL operations) - Policy: "agent rules"

---

### app_notifications

**Purpose:** Stores in-app notifications for users. Tracks notification delivery, read status, and expiration.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| user_id | uuid | NO | - | Foreign key to profiles.id |
| message | text | NO | - | Notification message |
| notification_type | text | NO | - | Type of notification |
| priority | text | YES | 'normal' | Priority level (low, normal, high, urgent) |
| job_id | text | YES | - | Related job identifier |
| action_data | jsonb | YES | - | Additional action data |
| is_read | boolean | YES | false | Read status |
| is_hidden | boolean | YES | false | Hidden status |
| read_at | timestamptz | YES | - | Read timestamp |
| dismissed_at | timestamptz | YES | - | Dismissed timestamp |
| expires_at | timestamptz | YES | - | Expiration timestamp |
| created_at | timestamptz | YES | now() | Creation timestamp |
| updated_at | timestamptz | YES | now() | Last update timestamp |

**Primary Key:** `id`

**Foreign Keys:**
- `user_id` → `profiles.id`

**Check Constraints:**
- `priority` must be one of: 'low', 'normal', 'high', 'urgent'

**RLS Status:** Enabled

**RLS Policies:**
- **Anonymous users:** INSERT only - Policy: "allow_anon_insert"
- **Authenticated users:** 
  - INSERT - Policy: "allow_authenticated_insert"
  - SELECT own notifications only - Policy: "allow_users_view_own" (user_id = auth.uid())
  - UPDATE own notifications only - Policy: "allow_users_update_own" (user_id = auth.uid())
- **Service role:** Full access (ALL operations) - Policy: "allow_service_role_all"

---

### app_version

**Purpose:** DEPRECATED - App version control (not used by Choice Lux Cars app as of Nov 2025).

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| version_number | text | YES | - | DEPRECATED - Version number |
| is_mandatory | boolean | YES | false | DEPRECATED - Mandatory update flag |
| update_url | text | YES | - | DEPRECATED - Update URL |

**Primary Key:** `id`

**RLS Status:** Enabled

**RLS Policies:**
- **Public:** Full access (ALL operations) - Policy: "Version Control"

---

### branches

**Purpose:** Stores Choice Lux Cars company branch locations. Used to allocate users, vehicles, and jobs to specific branches. NULL branch_id for users means Admin/National access.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| name | text | NO | - | Branch name (unique) |
| code | text | NO | - | Branch code (unique) |
| created_at | timestamptz | NO | now() | Creation timestamp |
| updated_at | timestamptz | NO | now() | Last update timestamp |

**Primary Key:** `id`

**Unique Constraints:**
- `name` - Unique
- `code` - Unique

**Foreign Keys:**
- `jobs.branch_id` → `branches.id`
- `profiles.branch_id` → `branches.id`
- `vehicles.branch_id` → `branches.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:** SELECT only - Policy: "branches_select_policy"

---

### client_branches

**Purpose:** Stores branch locations for clients. Supports soft delete via deleted_at.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| client_id | bigint | NO | - | Foreign key to clients.id |
| branch_name | text | NO | - | Branch name |
| created_at | timestamptz | NO | now() | Creation timestamp |
| updated_at | timestamptz | NO | now() | Last update timestamp |
| deleted_at | timestamptz | YES | - | Soft delete timestamp |

**Primary Key:** `id`

**Foreign Keys:**
- `quotes.branch_id` → `client_branches.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:** 
  - SELECT - Policy: "client_branches_select_policy"
  - INSERT - Policy: "client_branches_insert_policy"
  - UPDATE - Policy: "client_branches_update_policy"
  - DELETE - Policy: "client_branches_delete_policy"

---

### clients

**Purpose:** Stores client company information including contact details, billing information, and status.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| company_name | text | YES | - | Company name |
| contact_person | text | YES | - | Primary contact person |
| contact_number | text | YES | - | Contact phone number |
| contact_email | text | YES | - | Contact email address |
| company_logo | text | YES | - | Company logo URL |
| created_at | timestamptz | NO | now() | Creation timestamp |
| updated_at | timestamptz | NO | now() | Last update timestamp |
| status | text | NO | 'active' | Status (active, pending, vip, inactive) |
| deleted_at | timestamptz | YES | - | Soft delete timestamp |
| website_address | text | YES | - | Company website URL |
| company_registration_number | text | YES | - | Company registration number (CIPC/Companies House) |
| vat_number | text | YES | - | VAT registration number |
| billing_address | text | YES | - | Billing address |

**Primary Key:** `id`

**Check Constraints:**
- `status` must be one of: 'active', 'pending', 'vip', 'inactive'

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users & Service role:** Full access (ALL operations) - Policy: "Client Policy"

---

### device_tokens

**Purpose:** DEPRECATED - Stores device tokens for push notifications (not used by Choice Lux Cars app as of Nov 2025).

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| profile_id | uuid | NO | - | Foreign key to profiles.id (unique, DEPRECATED) |
| token | text | NO | - | Device token |
| last_seen | timestamptz | NO | now() | DEPRECATED - Last seen timestamp |

**Primary Key:** `id`

**Unique Constraints:**
- `profile_id` - Unique

**Foreign Keys:**
- `profile_id` → `profiles.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Public:** 
  - Full access with restrictions - Policy: "device_tokens_consolidated"
  - Administrators and managers: Full access
  - Other users: Access only to own records (profile_id = auth.uid()) and role must not be 'suspended'

---

### driver_flow

**Purpose:** Tracks driver workflow progress for jobs including vehicle collection, pickup/dropoff status, odometer readings, and job completion.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| job_id | bigint | YES | - | Foreign key to jobs.id (unique) |
| vehicle_collected | boolean | NO | false | Vehicle collection status |
| vehicle_time | timestamp | YES | - | Vehicle collection time |
| user | uuid | YES | - | Legacy user reference |
| odo_start_img | text | YES | - | Odometer start image URL |
| odo_start_reading | numeric | YES | - | Odometer start reading |
| pickup_arrive_loc | text | YES | - | Pickup arrival location |
| pickup_arrive_time | timestamptz | YES | - | Pickup arrival time |
| pickup_ind | boolean | YES | false | Pickup indicator |
| payment_collected_ind | boolean | YES | false | Payment collected indicator |
| transport_completed_ind | boolean | YES | false | Transport completed indicator |
| job_closed_odo | numeric | YES | - | Job closed odometer reading |
| job_closed_odo_img | text | YES | - | Job closed odometer image URL |
| job_closed_time | timestamp | YES | - | Job closed time |
| current_step | text | YES | 'vehicle_collection' | Current workflow step |
| current_trip_index | integer | YES | 1 | Current trip index |
| progress_percentage | integer | YES | 0 | Progress percentage |
| last_activity_at | timestamptz | YES | - | Last activity timestamp |
| job_started_at | timestamptz | YES | - | Job start timestamp |
| vehicle_collected_at | timestamptz | YES | - | Vehicle collection timestamp |
| pdp_start_image | text | YES | - | PDP start image URL |
| updated_at | timestamptz | YES | now() | Last update timestamp |
| driver_user | uuid | YES | - | Foreign key to profiles.id |
| pickup_loc | text | YES | - | Pickup location |

**Primary Key:** `id`

**Unique Constraints:**
- `job_id` - Unique

**Foreign Keys:**
- `driver_user` → `profiles.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - SELECT - Policy: "driver_flow_select_consolidated" (any authenticated user)
  - INSERT - Policy: "Authenticated users can insert driver_flow" (driver_user = auth.uid())
  - UPDATE - Policy: "Authenticated users can update driver_flow" (driver_user = auth.uid())
- **Public:**
  - DELETE - Policy: "Authenticated users can delete driver_flow" (driver_user = auth.uid())

---

### expenses

**Purpose:** Tracks job-related expenses including descriptions, amounts, dates, locations, and receipt images.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| job_id | bigint | YES | - | Foreign key to jobs.id |
| expense_description | text | YES | - | Expense description |
| exp_amount | numeric | YES | - | Expense amount |
| exp_date | timestamptz | YES | - | Expense date |
| slip_image | text | YES | - | Receipt/slip image URL |
| expense_location | text | YES | - | Expense location |
| user | text | YES | - | User identifier |
| other_description | text | YES | - | Additional description |
| created_at | timestamptz | NO | now() | Creation timestamp |
| updated_at | timestamptz | NO | now() | Last update timestamp |

**Primary Key:** `id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:** Full access (ALL operations) - Policy: "Allow authenticated access to expenses"

---

### invoices

**Purpose:** Stores invoice information linked to quotes, including invoice numbers, dates, status, and PDF URLs.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | nextval('invoices_id_seq') | Primary key |
| quote_id | bigint | NO | - | Foreign key to quotes.id |
| invoice_number | text | NO | - | Invoice number |
| invoice_date | date | YES | CURRENT_DATE | Invoice date |
| pdf_url | text | YES | - | DEPRECATED - PDF URL (not used as of Nov 2025) |
| status | text | YES | 'Pending' | Invoice status |
| created_at | timestamptz | YES | now() | Creation timestamp |
| job_allocated | boolean | YES | false | DEPRECATED - Job allocation flag (not used as of Nov 2025) |

**Primary Key:** `id`

**Foreign Keys:**
- `quote_id` → `quotes.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - SELECT - Policy: "invoices_select_policy"
  - INSERT - Policy: "invoices_insert_policy"
  - UPDATE - Policy: "invoices_update_policy"
  - DELETE - Policy: "invoices_delete_policy"

---

### job_notification_log

**Purpose:** Logs job notification events for drivers, tracking notification status and processing.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| job_id | bigint | NO | - | Foreign key to jobs.id |
| driver_id | uuid | NO | - | Foreign key to profiles.id |
| is_reassignment | boolean | YES | false | DEPRECATED - Reassignment flag (not used as of Nov 2025) |
| created_at | timestamptz | YES | now() | Creation timestamp |
| processed_at | timestamptz | YES | - | DEPRECATED - Processing timestamp (not used as of Nov 2025) |
| status | text | YES | 'pending' | Notification status |

**Primary Key:** `id`

**Foreign Keys:**
- `driver_id` → `profiles.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - SELECT - Policy: "job_notification_log_select_policy"
  - INSERT - Policy: "job_notification_log_insert_policy"
  - UPDATE - Policy: "job_notification_log_update_policy"
  - DELETE - Policy: "job_notification_log_delete_policy"

---

### jobs

**Purpose:** Core jobs table storing job assignments, status, client information, driver assignments, and branch allocation. Branch allocation is managed via branch_id (FK to branches table).

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| client_id | bigint | YES | - | Foreign key to clients.id |
| vehicle_id | bigint | YES | - | Foreign key to vehicles.id |
| driver_id | uuid | YES | - | Foreign key to profiles.id |
| order_date | date | YES | - | Order date |
| amount | numeric | YES | - | Job amount |
| amount_collect | boolean | YES | false | Payment collection flag |
| passenger_name | text | YES | - | Passenger name |
| passenger_contact | text | YES | - | Passenger contact |
| agent_id | bigint | NO | - | Foreign key to agents.id |
| job_status | text | YES | 'assigned' | Job status |
| pax | numeric | YES | - | Number of passengers |
| cancel_reason | text | YES | - | Cancellation reason |
| driver_confirm_ind | boolean | YES | false | Driver confirmation indicator |
| job_start_date | date | YES | - | Scheduled start date for notification expiration |
| number_bags | text | YES | - | Number of bags |
| quote_no | bigint | YES | - | Quote number reference |
| created_at | timestamptz | NO | now() | Creation timestamp |
| updated_at | timestamptz | NO | now() | Last update timestamp |
| voucher_pdf | text | YES | - | Voucher PDF URL |
| notes | text | YES | - | Job notes |
| created_by | text | YES | - | Creator identifier |
| is_confirmed | boolean | YES | false | Confirmation status |
| confirmed_at | timestamptz | YES | - | Confirmation timestamp |
| confirmed_by | uuid | YES | - | Foreign key to auth.users.id |
| job_number | text | YES | - | Human-readable job number (unique) |
| invoice_pdf | text | YES | - | Invoice PDF URL (Supabase Storage) |
| manager_id | uuid | YES | - | Foreign key to profiles.id |
| cancelled_by | uuid | YES | - | Foreign key to auth.users.id |
| cancelled_at | timestamptz | YES | - | Cancellation timestamp |
| branch_id | bigint | YES | - | Foreign key to branches.id (Choice Lux Cars branch) |

**Primary Key:** `id`

**Unique Constraints:**
- `job_number` - Unique

**Foreign Keys:**
- `agent_id` → `agents.id`
- `branch_id` → `branches.id`
- `driver_id` → `profiles.id`
- `manager_id` → `profiles.id`
- `vehicle_id` → `vehicles.id`
- `confirmed_by` → `auth.users.id`
- `cancelled_by` → `auth.users.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - SELECT - Policy: "jobs_select_policy"
  - INSERT - Policy: "jobs_insert_policy"
  - UPDATE - Policy: "jobs_update_policy"
  - DELETE - Policy: "jobs_delete_policy"

---

### login_attempts

**Purpose:** DEPRECATED - Logs login attempts (not used by Choice Lux Cars app as of Nov 2025).

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| attempted_at | timestamptz | YES | now() | DEPRECATED - Attempt timestamp |
| ip_address | text | YES | - | DEPRECATED - IP address |
| email | text | YES | - | Email address |
| user_agent | text | YES | - | DEPRECATED - User agent |
| success | boolean | YES | - | Success flag |

**Primary Key:** `id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - SELECT - Policy: "login_attempts_select_policy"
  - INSERT - Policy: "login_attempts_insert_policy"

---

### notification_delivery_log

**Purpose:** Tracks delivery attempts for push notifications, including FCM responses, success status, and retry counts.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| notification_id | uuid | NO | - | Foreign key to app_notifications.id |
| user_id | uuid | NO | - | Foreign key to profiles.id |
| fcm_token | text | YES | - | FCM token used |
| fcm_response | jsonb | YES | - | FCM API response |
| sent_at | timestamptz | YES | now() | Send timestamp |
| success | boolean | YES | false | Delivery success status |
| error_message | text | YES | - | Error message if failed |
| retry_count | integer | YES | 0 | Retry attempt count |

**Primary Key:** `id`

**Foreign Keys:**
- `notification_id` → `app_notifications.id`
- `user_id` → `profiles.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Public:**
  - SELECT own records only - Policy: "Users can view their own delivery logs" (user_id = auth.uid())

---

### notifications_backup

**Purpose:** Backup table for notifications (legacy/archival).

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | uuid | NO | - | Primary key |
| user_id | uuid | YES | - | User identifier |
| created_at | timestamptz | YES | - | Creation timestamp |
| message | text | YES | - | Notification message |
| suppressed | boolean | YES | - | Suppressed flag |
| job_id | bigint | YES | - | Job identifier |
| is_read | boolean | YES | - | Read status |
| notification_type | varchar(50) | YES | - | Notification type |
| updated_at | timestamptz | YES | - | Last update timestamp |
| is_hidden | boolean | YES | - | Hidden status |
| dismissed_at | timestamptz | YES | - | Dismissed timestamp |
| priority | text | YES | - | Priority level |
| action_data | jsonb | YES | - | Action data |
| expires_at | timestamptz | YES | - | Expiration timestamp |
| read_at | timestamptz | YES | - | Read timestamp |

**Primary Key:** `id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:** SELECT only - Policy: "notifications_backup_select_policy"

---

### profiles

**Purpose:** User profiles table storing driver and staff information, including licenses, certifications, FCM tokens, branch allocation, and notification preferences.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | uuid | NO | - | Primary key (FK to auth.users.id) |
| display_name | text | YES | - | Display name |
| profile_image | text | YES | - | Profile image URL |
| address | text | YES | - | Address |
| number | text | YES | - | Phone number |
| kin | text | YES | - | Next of kin name |
| kin_number | text | YES | - | Next of kin contact |
| role | user_role_enum | YES | - | User role (administrator, manager, driver_manager, driver, suspended, super_admin) |
| driver_licence | text | YES | - | Driver license number |
| driver_lic_exp | date | YES | - | Driver license expiry |
| pdp | text | YES | - | PDP license number |
| pdp_exp | date | YES | - | PDP expiry date |
| user_email | text | YES | - | User email |
| traf_reg | text | YES | - | Traffic registration |
| traf_exp_date | date | YES | - | Traffic registration expiry |
| fcm_token | text | YES | - | FCM token for mobile/Android push notifications |
| status | text | YES | 'active' | Status (active, deactivated, unassigned) |
| fcm_token_web | text | YES | - | FCM token for web platform push notifications |
| branch_id | bigint | YES | - | Foreign key to branches.id (NULL = Admin/National access) |
| notification_prefs | jsonb | YES | '{}' | Per-user push notification preferences (JSONB) |

**Primary Key:** `id`

**Check Constraints:**
- `status` must be one of: 'active', 'deactivated', 'unassigned'

**Foreign Keys:**
- `id` → `auth.users.id`
- `branch_id` → `branches.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - Full access - Policy: "Profile Policy"
  - SELECT fcm_token - Policy: "Authenticated can read fcm_token"
  - UPDATE own profile only - Policy: "profiles_update_consolidated" (id = auth.uid())

---

### quotes

**Purpose:** Stores quote information including client details, transport requirements, amounts, and status.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| job_date | date | YES | - | Job date |
| vehicle_type | text | YES | - | Vehicle type |
| quote_status | text | YES | - | Quote status |
| pax | numeric | YES | - | Number of passengers |
| luggage | text | YES | - | Luggage information |
| passenger_name | text | YES | - | Passenger name |
| passenger_contact | text | YES | - | Passenger contact |
| notes | text | YES | - | Notes |
| quote_pdf | text | YES | - | Quote PDF URL |
| client_id | bigint | YES | - | Foreign key to clients.id |
| agent_id | bigint | YES | - | Foreign key to agents.id |
| quote_date | date | YES | - | Quote date |
| quote_amount | numeric | YES | - | Quote amount |
| quote_title | text | YES | - | Quote title |
| quote_description | text | YES | - | Quote description |
| driver_id | uuid | YES | - | Driver identifier |
| vehicle_id | bigint | YES | - | Vehicle identifier |
| created_at | timestamptz | NO | now() | Creation timestamp |
| updated_at | timestamptz | NO | now() | Last update timestamp |
| location | text | YES | - | Location |
| branch_id | bigint | YES | - | Foreign key to client_branches.id |

**Primary Key:** `id`

**Foreign Keys:**
- `agent_id` → `agents.id`
- `branch_id` → `client_branches.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - SELECT - Policy: "quotes_select_policy"
  - INSERT - Policy: "quotes_insert_policy"
  - UPDATE - Policy: "quotes_update_policy"
  - DELETE - Policy: "quotes_delete_policy"

---

### quotes_transport_details

**Purpose:** This is a duplicate of transport_details. Stores transport details for quotes including pickup/dropoff locations, dates, amounts, and notes.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| quote_id | bigint | YES | - | Foreign key to quotes.id |
| pickup_date | timestamp | YES | - | Pickup date/time |
| pickup_location | text | YES | - | Pickup location |
| dropoff_location | varchar | YES | - | Dropoff location |
| amount | numeric | YES | - | Transport amount |
| notes | text | YES | - | Notes |

**Primary Key:** `id`

**Foreign Keys:**
- `quote_id` → `quotes.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - SELECT - Policy: "quotes_transport_details_select_policy"
  - INSERT - Policy: "quotes_transport_details_insert_policy"
  - UPDATE - Policy: "quotes_transport_details_update_policy"
  - DELETE - Policy: "quotes_transport_details_delete_policy"

---

### transport

**Purpose:** Stores transport trip details for jobs including pickup/dropoff locations, times, status, and amounts.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| job_id | bigint | YES | - | Foreign key to jobs.id |
| pickup_date | timestamp | YES | - | Pickup date/time |
| pickup_location | text | YES | - | Pickup location |
| dropoff_location | varchar | YES | - | Dropoff location |
| notes | text | YES | - | Notes |
| client_pickup_time | timestamp | YES | - | Client pickup time |
| client_dropoff_time | timestamp | YES | - | Client dropoff time |
| amount | numeric | YES | - | Transport amount |
| created_at | timestamptz | NO | now() | Creation timestamp |
| updated_at | timestamptz | NO | now() | Last update timestamp |
| status | text | YES | 'pending' | Status (pending, pickup_arrived, passenger_onboard, dropoff_arrived, completed) |
| pickup_arrived_at | timestamptz | YES | - | DEPRECATED - Pickup arrival timestamp (not used as of Nov 2025) |
| passenger_onboard_at | timestamptz | YES | - | DEPRECATED - Passenger onboard timestamp (not used as of Nov 2025) |
| dropoff_arrived_at | timestamptz | YES | - | DEPRECATED - Dropoff arrival timestamp (not used as of Nov 2025) |

**Primary Key:** `id`

**Check Constraints:**
- `status` must be one of: 'pending', 'pickup_arrived', 'passenger_onboard', 'dropoff_arrived', 'completed'

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - SELECT - Policy: "Allow authenticated read transport"
  - INSERT - Policy: "Allow authenticated insert transport"
  - UPDATE - Policy: "Allow authenticated update transport"
  - DELETE - Policy: "Allow authenticated delete transport"

---

### trip_progress

**Purpose:** Tracks progress for individual trips within a job, including status, GPS coordinates, and timestamps for each trip stage.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| job_id | bigint | NO | - | Foreign key to jobs.id |
| trip_index | integer | NO | - | Trip index within job (unique with job_id) |
| status | text | NO | 'pending' | Trip status |
| pickup_arrived_at | timestamptz | YES | - | Pickup arrival timestamp |
| passenger_onboard_at | timestamptz | YES | - | Passenger onboard timestamp |
| dropoff_arrived_at | timestamptz | YES | - | Dropoff arrival timestamp |
| completed_at | timestamptz | YES | - | Completion timestamp |
| pickup_gps_lat | numeric | YES | - | Pickup GPS latitude |
| pickup_gps_lng | numeric | YES | - | Pickup GPS longitude |
| dropoff_gps_lat | numeric | YES | - | Dropoff GPS latitude |
| dropoff_gps_lng | numeric | YES | - | Dropoff GPS longitude |
| notes | text | YES | - | Trip notes |
| created_at | timestamptz | NO | now() | Creation timestamp |
| updated_at | timestamptz | NO | now() | Last update timestamp |

**Primary Key:** `id`

**Unique Constraints:**
- `(job_id, trip_index)` - Composite unique constraint

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - SELECT - Policy: "Authenticated users can read trip_progress" (access if: job driver_id = auth.uid() OR job manager_id = auth.uid() OR user role is administrator/manager/driver_manager)
  - UPDATE - Policy: "Drivers can update their trip_progress" (job driver_id = auth.uid())

---

### user_notification_preferences

**Purpose:** Stores user notification preferences and settings including notification types, quiet hours, and delivery preferences.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | uuid | NO | gen_random_uuid() | Primary key |
| user_id | uuid | NO | - | Foreign key to auth.users.id (unique) |
| job_assignments | boolean | YES | true | Receive job assignment notifications |
| job_reassignments | boolean | YES | true | Receive job reassignment notifications |
| job_status_changes | boolean | YES | true | Receive job status change notifications |
| job_cancellations | boolean | YES | true | Receive job cancellation notifications |
| payment_reminders | boolean | YES | true | Receive payment reminder notifications |
| system_alerts | boolean | YES | true | Receive system alert notifications |
| push_notifications | boolean | YES | true | Receive push notifications |
| in_app_notifications | boolean | YES | true | Show in-app notifications |
| email_notifications | boolean | YES | false | Receive email notifications |
| sound_enabled | boolean | YES | true | Play sound for notifications |
| vibration_enabled | boolean | YES | true | Vibrate for notifications |
| high_priority_only | boolean | YES | false | Only show high priority notifications |
| quiet_hours_enabled | boolean | YES | false | Enable quiet hours |
| quiet_hours_start | time | YES | '22:00:00' | Quiet hours start time (HH:MM) |
| quiet_hours_end | time | YES | '07:00:00' | Quiet hours end time (HH:MM) |
| created_at | timestamptz | YES | now() | Creation timestamp |
| updated_at | timestamptz | YES | now() | Last update timestamp |

**Primary Key:** `id`

**Unique Constraints:**
- `user_id` - Unique

**Foreign Keys:**
- `user_id` → `auth.users.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:**
  - SELECT own preferences only - Policy: "Users can view own notification preferences" (user_id = auth.uid())
  - INSERT own preferences only - Policy: "Users can insert own notification preferences" (user_id = auth.uid())
  - UPDATE own preferences only - Policy: "Users can update own notification preferences" (user_id = auth.uid())

---

### vehicles

**Purpose:** Vehicle descriptions and information including make, model, registration, fuel type, status, and branch allocation.

**Columns:**

| Column Name | Type | Nullable | Default | Description |
|------------|------|----------|---------|-------------|
| id | bigint | NO | auto-increment | Primary key |
| make | text | YES | - | Vehicle make |
| model | text | YES | - | Vehicle model |
| reg_plate | text | YES | - | Registration plate |
| reg_date | date | YES | - | Registration date |
| fuel_type | text | YES | - | Fuel type |
| vehicle_image | text | YES | - | Vehicle image URL |
| status | text | YES | - | Vehicle status |
| created_at | timestamptz | NO | now() | Creation timestamp |
| updated_at | timestamptz | NO | now() | Last update timestamp |
| license_expiry_date | date | YES | - | License expiry date |
| branch_id | bigint | YES | - | Foreign key to branches.id (Choice Lux Cars branch allocation) |

**Primary Key:** `id`

**Foreign Keys:**
- `branch_id` → `branches.id`
- `jobs.vehicle_id` → `vehicles.id`

**RLS Status:** Enabled

**RLS Policies:**
- **Authenticated users:** Full access (ALL operations) - Policy: "vehicle_details_policy"

---

## RLS Policy Summary by Role

### Administrator (`administrator`)
- **agents:** Full access
- **app_notifications:** Full access (via service_role policy)
- **branches:** SELECT
- **client_branches:** Full access
- **clients:** Full access
- **device_tokens:** Full access
- **driver_flow:** SELECT all, INSERT/UPDATE/DELETE own
- **expenses:** Full access
- **invoices:** Full access
- **job_notification_log:** Full access
- **jobs:** Full access
- **login_attempts:** SELECT, INSERT
- **notification_delivery_log:** SELECT own
- **notifications_backup:** SELECT
- **profiles:** Full access, UPDATE own
- **quotes:** Full access
- **quotes_transport_details:** Full access
- **transport:** Full access
- **trip_progress:** SELECT (if job manager/driver or admin role), UPDATE (if job driver)
- **user_notification_preferences:** SELECT/INSERT/UPDATE own
- **vehicles:** Full access

### Manager (`manager`)
- **agents:** Full access
- **app_notifications:** Full access (via service_role policy)
- **branches:** SELECT
- **client_branches:** Full access
- **clients:** Full access
- **device_tokens:** Full access
- **driver_flow:** SELECT all, INSERT/UPDATE/DELETE own
- **expenses:** Full access
- **invoices:** Full access
- **job_notification_log:** Full access
- **jobs:** Full access
- **login_attempts:** SELECT, INSERT
- **notification_delivery_log:** SELECT own
- **notifications_backup:** SELECT
- **profiles:** Full access, UPDATE own
- **quotes:** Full access
- **quotes_transport_details:** Full access
- **transport:** Full access
- **trip_progress:** SELECT (if job manager/driver or manager role), UPDATE (if job driver)
- **user_notification_preferences:** SELECT/INSERT/UPDATE own
- **vehicles:** Full access

### Driver Manager (`driver_manager`)
- **agents:** Full access
- **app_notifications:** Full access (via service_role policy)
- **branches:** SELECT
- **client_branches:** Full access
- **clients:** Full access
- **device_tokens:** Full access (if own record or admin/manager role)
- **driver_flow:** SELECT all, INSERT/UPDATE/DELETE own
- **expenses:** Full access
- **invoices:** Full access
- **job_notification_log:** Full access
- **jobs:** Full access
- **login_attempts:** SELECT, INSERT
- **notification_delivery_log:** SELECT own
- **notifications_backup:** SELECT
- **profiles:** Full access, UPDATE own
- **quotes:** Full access
- **quotes_transport_details:** Full access
- **transport:** Full access
- **trip_progress:** SELECT (if job manager/driver or driver_manager role), UPDATE (if job driver)
- **user_notification_preferences:** SELECT/INSERT/UPDATE own
- **vehicles:** Full access

### Driver (`driver`)
- **agents:** Full access
- **app_notifications:** SELECT/INSERT/UPDATE own
- **branches:** SELECT
- **client_branches:** Full access
- **clients:** Full access
- **device_tokens:** SELECT/INSERT/UPDATE/DELETE own (if not suspended)
- **driver_flow:** SELECT all, INSERT/UPDATE/DELETE own records
- **expenses:** Full access
- **invoices:** Full access
- **job_notification_log:** Full access
- **jobs:** Full access
- **login_attempts:** SELECT, INSERT
- **notification_delivery_log:** SELECT own
- **notifications_backup:** SELECT
- **profiles:** Full access, UPDATE own
- **quotes:** Full access
- **quotes_transport_details:** Full access
- **transport:** Full access
- **trip_progress:** SELECT (if assigned as driver), UPDATE (if assigned as driver)
- **user_notification_preferences:** SELECT/INSERT/UPDATE own
- **vehicles:** Full access

---

## Notes

1. **Branch Allocation:** The `branches` table stores Choice Lux Cars company branches (Durban, Cape Town, Johannesburg). Users, vehicles, and jobs can be allocated to branches via `branch_id`. NULL `branch_id` for users indicates Admin/National access.

2. **Client Branches:** The `client_branches` table stores branch locations for clients (different from company branches). Quotes reference client branches.

3. **Deprecated Fields:** Several fields are marked as DEPRECATED and not used by the Choice Lux Cars app as of November 2025. These are retained for backward compatibility.

4. **RLS Policies:** All tables have RLS enabled. Policies are generally permissive for authenticated users, with restrictions based on ownership or role.

5. **Foreign Key Relationships:** The schema maintains referential integrity through foreign key constraints. Some relationships are optional (nullable foreign keys).

6. **User Roles:** The `profiles.role` column uses a custom enum type `user_role_enum` with values: administrator, manager, driver_manager, driver, suspended, super_admin.

