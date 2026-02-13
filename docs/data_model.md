
# 🗃️ Choice Lux Cars – Supabase Data Model Reference (Updated)

This document describes the full schema of the updated Supabase PostgreSQL data model used by the Choice Lux Cars app. It defines tables, fields, relationships, and constraints essential to building and managing business logic.

---

## 🔧 Tables Overview

- `agents`
- `app_version`
- `clients`
- `device_tokens`
- `driver_flow`
- `expenses`
- `invoices`
- `job_notification_log`
- `jobs`
- `login_attempts`
- `notifications`
- `profiles`
- `quotes`
- `quotes_transport_details`
- `transport`
- `trip_progress`
- `vehicles`

---

## 🧾 `agents`

| Column         | Type      | Description                           |
|----------------|-----------|---------------------------------------|
| id             | bigint    | Primary key (GENERATED ALWAYS AS IDENTITY) |
| agent_name     | text      | Agent's name                          |
| client_key     | bigint    | FK to `clients.id`                    |
| contact_number | text      | Phone number                          |
| contact_email  | text      | Email address                         |
| created_at     | timestamp | Creation timestamp                    |
| updated_at     | timestamp | Last update                           |
| is_deleted     | boolean   | Soft delete flag (default: false)     |

**Constraints:**
- `agents_pkey` - Primary key on `id`
- `agent_details_client_key_fkey` - Foreign key to `clients(id)`

---

## 🔢 `app_version`

| Column         | Type     | Description                  |
|----------------|----------|------------------------------|
| id             | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| version_number | text     | Version label                |
| is_mandatory   | boolean  | Require update? (default: false) |
| update_url     | text     | Link to update/download page |

**Constraints:**
- `app_version_pkey` - Primary key on `id`

---

## 👥 `clients`

| Column         | Type     | Description                  |
|----------------|----------|------------------------------|
| id             | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| company_name   | text     | Client's name                |
| contact_person | text     | Main contact name            |
| contact_number | text     | Phone                        |
| contact_email  | text     | Email                        |
| company_logo   | text     | Logo URL                     |
| status         | text     | Client status (default: 'active') |
| deleted_at     | timestamp| Soft delete timestamp        |
| created_at     | timestamp| Creation date                |
| updated_at     | timestamp| Last modified                |

**Status Values:**
- `active` - Currently active client (default)
- `pending` - Client awaiting approval/activation
- `vip` - VIP client with special privileges
- `inactive` - Soft deleted client (preserved data)

**Constraints:**
- `clients_pkey` - Primary key on `id`
- Check constraint ensuring status is one of: 'active', 'pending', 'vip', 'inactive'

**Soft Delete Implementation:**
- Clients are never permanently deleted by default
- `deleted_at` timestamp tracks when client was deactivated
- All related data (quotes, invoices, agents) remains intact
- Clients can be restored by updating status back to 'active'

---

## 🔒 `device_tokens`

| Column     | Type     | Description                      |
|------------|----------|----------------------------------|
| id         | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| profile_id | uuid     | FK to `profiles.id` (UNIQUE)     |
| token      | text     | FCM token (NOT NULL)             |
| last_seen  | timestamp| Last usage timestamp (default: now()) |

**Constraints:**
- `device_tokens_pkey` - Primary key on `id`
- `fk_device_tokens_profile` - Foreign key to `profiles(id)`
- Unique constraint on `profile_id`

---

## 🚗 `driver_flow`

Tracks each driver's activity in a job.

| Column               | Type     | Description                          |
|----------------------|----------|--------------------------------------|
| id                   | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| job_id               | bigint   | FK to `jobs.id` (UNIQUE)             |
| vehicle_collected    | boolean  | Has vehicle been collected? (default: false) |
| vehicle_time         | timestamp| Vehicle collection time              |
| user                 | uuid     | Driver ID                            |
| odo_start_img        | text     | Image of starting odometer           |
| odo_start_reading    | numeric  | Starting odometer                    |
| pickup_arrive_loc    | text     | Location of pickup                   |
| pickup_arrive_time   | timestamp| Time arrived at pickup               |
| pickup_ind           | boolean  | Pickup indicator (default: false)    |
| payment_collected_ind| boolean  | Was payment collected? (default: false) |
| transport_completed_ind | boolean | Has transport completed? (default: false) |
| job_closed_odo       | numeric  | Final odometer reading               |
| job_closed_odo_img   | text     | Image of final odometer              |
| job_closed_time      | timestamp| When job was closed                  |
| current_step         | text     | Current step (default: 'vehicle_collection') |
| current_trip_index   | integer  | Current trip index (default: 1)      |
| progress_percentage  | integer  | Progress percentage (default: 0)     |
| last_activity_at     | timestamp| Last activity timestamp              |
| job_started_at       | timestamp| Job start timestamp                  |
| vehicle_collected_at | timestamp| Vehicle collection timestamp         |
| pdp_start_image      | text     | PDP start image                      |
| updated_at           | timestamp| Last update (default: now())         |
| driver_user          | uuid     | Driver user ID                       |
| pickup_loc           | text     | Pickup location                      |

**Constraints:**
- `driver_flow_pkey` - Primary key on `id`
- `driver_flow_job_id_fkey` - Foreign key to `jobs(id)`
- `driver_flow_driver_user_fkey` - Foreign key to `profiles(id)`
- Unique constraint on `job_id`

---

## 💸 `expenses`

| Column              | Type     | Description                  |
|---------------------|----------|------------------------------|
| id                  | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| job_id              | bigint   | FK to `jobs.id`              |
| expense_description | text     | Description                  |
| exp_amount          | numeric  | Cost                         |
| exp_date            | timestamp| Date incurred                |
| slip_image          | text     | Receipt image                |
| expense_location    | text     | Location of expense          |
| user                | text     | Username                     |
| other_description   | text     | Additional description       |
| created_at          | timestamp| Creation timestamp           |
| updated_at          | timestamp| Last update                  |

**Constraints:**
- `expenses_pkey` - Primary key on `id`

---

## 🧾 `invoices`

| Column         | Type     | Description                  |
|----------------|----------|------------------------------|
| id             | bigint   | Primary key (uses sequence)  |
| quote_id       | bigint   | FK to `quotes.id` (NOT NULL) |
| invoice_number | text     | Human-readable invoice number (NOT NULL) |
| invoice_date   | date     | Date issued (default: CURRENT_DATE) |
| pdf_url        | text     | Invoice file URL             |
| status         | text     | Status (default: 'Pending')  |
| job_allocated  | boolean  | Was job linked to invoice (default: false) |
| created_at     | timestamp| Creation timestamp (default: now()) |

**Constraints:**
- `invoices_pkey` - Primary key on `id`
- `invoices_quote_id_fkey` - Foreign key to `quotes(id)`

---

## 📋 `job_notification_log`

| Column         | Type     | Description                  |
|----------------|----------|------------------------------|
| id             | uuid     | Primary key (default: gen_random_uuid()) |
| job_id         | bigint   | FK to `jobs.id` (NOT NULL)   |
| driver_id      | uuid     | FK to `profiles.id` (NOT NULL) |
| is_reassignment| boolean  | Is reassignment? (default: false) |
| created_at     | timestamp| Creation timestamp (default: now()) |
| processed_at   | timestamp| Processing timestamp         |
| status         | text     | Status (default: 'pending')  |

**Constraints:**
- `job_notification_log_pkey` - Primary key on `id`
- `job_notification_log_job_id_fkey` - Foreign key to `jobs(id)`
- `job_notification_log_driver_id_fkey` - Foreign key to `profiles(id)`

---

## 📦 `jobs`

| Column           | Type     | Description                          |
|------------------|----------|--------------------------------------|
| id               | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| client_id        | bigint   | FK to `clients.id`                   |
| vehicle_id       | bigint   | FK to `vehicles.id`                  |
| driver_id        | uuid     | Supabase user ID                     |
| order_date       | date     | Job order date                       |
| amount           | numeric  | Quoted amount                        |
| amount_collect   | boolean  | Whether to collect payment (default: false) |
| passenger_name   | text     | Passenger name                       |
| passenger_contact| text     | Passenger contact                    |
| agent_id         | bigint   | FK to `agents.id` (NOT NULL)         |
| job_status       | text     | Current status (default: 'assigned') |
| pax              | numeric  | Number of passengers                 |
| location         | text     | Job location                         |
| cancel_reason    | text     | Cancellation reason                  |
| driver_confirm_ind| boolean | Driver confirmation (default: false) |
| job_start_date   | date     | Start date                           |
| number_bags      | text     | Number of bags                       |
| quote_no         | bigint   | Link to original quote               |
| created_at       | timestamp| Creation timestamp                   |
| updated_at       | timestamp| Last update                          |
| voucher_pdf      | text     | URL to generated voucher             |
| notes            | text     | Extra notes                          |
| created_by       | text     | Created by user                      |
| is_confirmed     | boolean  | Job confirmed (default: false)       |
| confirmed_at     | timestamp| Confirmation timestamp               |
| confirmed_by     | uuid     | FK to `auth.users(id)`               |
| job_number       | text     | Unique job number                    |
| closed_by        | uuid     | FK to `profiles.id` – user who closed the job (set when completed) |
| closed_at        | timestamptz | When the job was closed             |
| closed_by_admin_ind | boolean | True when closed by administrator/super_admin (overrides trip/vehicle checks); used for reporting |
| admin_close_comment | text  | Mandatory comment when closed by admin (`closed_by_admin_ind = true`) |

**Constraints:**
- `jobs_pkey` - Primary key on `id`
- `order_details_client_id_fkey` - Foreign key to `clients(id)`
- `jobs_confirmed_by_fkey` - Foreign key to `auth.users(id)`
- `jobs_closed_by_fkey` - Foreign key to `profiles(id)` for `closed_by`
- `check_admin_close_comment_required` - When `closed_by_admin_ind` is true, `admin_close_comment` must be non-empty
- Unique constraint on `job_number`

---

## 📥 `login_attempts`

| Column      | Type     | Description               |
|-------------|----------|---------------------------|
| id          | uuid     | Primary key (default: gen_random_uuid()) |
| attempted_at| timestamp| Attempt timestamp (default: now()) |
| ip_address  | text     | IP at login               |
| email       | text     | Attempted email           |
| user_agent  | text     | Browser/device info       |
| success     | boolean  | Was it successful?        |

**Constraints:**
- `login_attempts_pkey` - Primary key on `id`

---

## 🔔 `notifications`

| Column            | Type     | Description                  |
|-------------------|----------|------------------------------|
| id                | uuid     | Primary key (default: gen_random_uuid()) |
| user_id           | uuid     | FK to `profiles(id)` (NOT NULL) |
| created_at        | timestamp| When it was sent (default: now()) |
| body              | text     | Message content (NOT NULL)   |
| suppressed        | boolean  | Suppressed flag (default: false) |
| job_id            | bigint   | FK to `jobs(id)`             |
| is_read           | boolean  | Read status (default: false) |
| notification_type | varchar  | Type (default: 'job_assignment') |
| updated_at        | timestamp| Last update (default: now()) |
| is_hidden         | boolean  | Hidden flag (default: false) |

**Constraints:**
- `notifications_pkey` - Primary key on `id`
- `notifications_user_id_fkey` - Foreign key to `profiles(id)`
- `notifications_job_id_fkey` - Foreign key to `jobs(id)`

---

## 🙋‍♂️ `profiles`

| Column         | Type     | Description                     |
|----------------|----------|---------------------------------|
| id             | uuid     | FK to `auth.users.id` (NOT NULL) |
| display_name   | text     | User's name                     |
| profile_image  | text     | Image URL                       |
| address        | text     | Address                         |
| number         | text     | Phone                           |
| kin            | text     | Emergency contact               |
| kin_number     | text     | Emergency contact number        |
| role           | enum     | User role (admin, driver, etc.) |
| driver_licence | text     | License number                  |
| driver_lic_exp | date     | License expiry                  |
| pdp            | text     | PDP number                      |
| pdp_exp        | date     | PDP expiry                      |
| user_email     | text     | Email                           |
| traf_reg       | text     | Traffic registration            |
| traf_exp_date  | date     | Expiry date                     |
| fcm_token      | text     | Device token for FCM            |
| status         | text     | Status (default: 'active')      |

**Status Values:**
- `active` - Active user (default)
- `deactivated` - Deactivated user
- `unassigned` - Unassigned user

**Constraints:**
- `profiles_pkey` - Primary key on `id`
- `profile_id_fkey` - Foreign key to `auth.users(id)`
- Check constraint ensuring status is one of: 'active', 'deactivated', 'unassigned'

---

## 📝 `quotes`

| Column            | Type     | Description                  |
|-------------------|----------|------------------------------|
| id                | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| job_date          | date     | Intended date                |
| vehicle_type      | text     | Vehicle type                 |
| quote_status      | text     | Draft, sent, accepted, etc.  |
| pax               | numeric  | Number of passengers         |
| luggage           | text     | Luggage description          |
| passenger_name    | text     | Passenger name               |
| passenger_contact | text     | Passenger contact            |
| notes             | text     | Additional notes             |
| quote_pdf         | text     | PDF URL                      |
| client_id         | bigint   | FK to `clients.id`           |
| agent_id          | bigint   | FK to `agents.id`            |
| quote_date        | date     | Date issued                  |
| quote_amount      | numeric  | Total quoted amount          |
| quote_title       | text     | Title of quote               |
| quote_description | text     | Optional description         |
| driver_id         | uuid     | Assigned driver              |
| vehicle_id        | bigint   | FK to `vehicles.id`          |
| created_at        | timestamp| Creation timestamp           |
| updated_at        | timestamp| Last update                  |
| location          | text     | Route summary                |

**Constraints:**
- `quotes_pkey` - Primary key on `id`
- `quotes_company_id_fkey` - Foreign key to `clients(id)`
- `quote_details_agent_id_fkey` - Foreign key to `agents(id)`

---

## 🚚 `quotes_transport_details`

| Column         | Type     | Description                      |
|----------------|----------|----------------------------------|
| id             | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| quote_id       | bigint   | FK to `quotes.id`                |
| pickup_date    | timestamp| Scheduled time                   |
| pickup_location| text     | From                             |
| dropoff_location| varchar | To                               |
| amount         | numeric  | Subtotal                         |
| notes          | text     | Notes per leg                    |

**Constraints:**
- `quotes_transport_details_pkey` - Primary key on `id`
- `quotes_transport_details_job_id_fkey` - Foreign key to `quotes(id)`

---

## 🚗 `transport`

| Column             | Type     | Description                  |
|--------------------|----------|------------------------------|
| id                 | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| job_id             | bigint   | FK to `jobs.id`              |
| pickup_date        | timestamp| When to pick up              |
| pickup_location    | text     | Where                        |
| dropoff_location   | varchar  | Where                        |
| notes              | text     | Notes                         |
| client_pickup_time | timestamp| Actual time out              |
| client_dropoff_time| timestamp| Actual time in               |
| amount             | numeric  | Amount                        |
| created_at         | timestamp| Creation timestamp           |
| updated_at         | timestamp| Last update                  |
| status             | enum     | Trip status                   |

**Constraints:**
- `transport_pkey` - Primary key on `id`

---

## 🚶 `trip_progress`

| Column              | Type     | Description                  |
|---------------------|----------|------------------------------|
| id                  | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| job_id              | bigint   | FK to `jobs.id`              |
| trip_index          | integer  | Trip index (NOT NULL)         |
| pickup_arrived_at   | timestamp| Pickup arrival time          |
| pickup_gps_lat      | numeric  | Pickup GPS latitude           |
| pickup_gps_lng      | numeric  | Pickup GPS longitude          |
| pickup_gps_accuracy | numeric  | Pickup GPS accuracy           |
| passenger_onboard_at| timestamp| Passenger onboard time       |
| dropoff_arrived_at  | timestamp| Dropoff arrival time         |
| dropoff_gps_lat     | numeric  | Dropoff GPS latitude          |
| dropoff_gps_lng     | numeric  | Dropoff GPS longitude         |
| dropoff_gps_accuracy| numeric  | Dropoff GPS accuracy          |
| status              | text     | Status (default: 'pending')   |
| notes               | text     | Notes                         |
| created_at          | timestamp| Creation timestamp (default: now()) |
| updated_at          | timestamp| Last update (default: now()) |

**Status Values:**
- `pending` - Pending (default)
- `pickup_arrived` - Arrived at pickup
- `onboard` - Passenger onboard
- `dropoff_arrived` - Arrived at dropoff
- `completed` - Trip completed

**Constraints:**
- `trip_progress_pkey` - Primary key on `id`
- `trip_progress_job_id_fkey` - Foreign key to `jobs(id)`
- Check constraint ensuring status is one of: 'pending', 'pickup_arrived', 'onboard', 'dropoff_arrived', 'completed'

---

## 🚘 `vehicles`

| Column        | Type     | Description                  |
|---------------|----------|------------------------------|
| id            | bigint   | Primary key (GENERATED ALWAYS AS IDENTITY) |
| make          | text     | Vehicle make                 |
| model         | text     | Vehicle model                |
| reg_plate     | text     | Registration plate           |
| reg_date      | date     | Registration date            |
| fuel_type     | text     | Fuel type                    |
| vehicle_image | text     | Image URL                    |
| status        | text     | Available, In service, etc.  |
| created_at    | timestamp| Creation timestamp           |
| updated_at    | timestamp| Last update                  |
| license_expiry_date | date | License expiry date          |

**Constraints:**
- `vehicles_pkey` - Primary key on `id`

---

## 🔗 Key Relationships

### Job Flow
1. **Quote** → **Job** (via `quote_no`)
2. **Job** → **Driver Flow** (1:1 via `job_id`)
3. **Job** → **Trip Progress** (1:many via `job_id`)
4. **Job** → **Transport** (1:many via `job_id`)
5. **Job** → **Expenses** (1:many via `job_id`)

### User Management
1. **Profiles** → **Jobs** (via `driver_id`)
2. **Profiles** → **Device Tokens** (1:1 via `profile_id`)
3. **Profiles** → **Notifications** (1:many via `user_id`)

### Client Management
1. **Clients** → **Agents** (1:many via `client_key`)
2. **Clients** → **Quotes** (1:many via `client_id`)
3. **Clients** → **Jobs** (1:many via `client_id`)

### Notification System
1. **Jobs** → **Job Notification Log** (1:many via `job_id`)
2. **Jobs** → **Notifications** (1:many via `job_id`)
3. **Profiles** → **Notifications** (1:many via `user_id`)

---

## 📊 Indexes and Performance

The database includes several indexes for performance optimization:

- Primary key indexes on all tables
- Foreign key indexes for relationship queries
- Status-based indexes for filtering
- Timestamp indexes for chronological queries
- Unique constraints where appropriate

---

## 🔒 Security and Access Control

- Row Level Security (RLS) policies are implemented on sensitive tables
- Foreign key constraints ensure referential integrity
- Check constraints validate data integrity
- Soft delete patterns preserve data while maintaining referential integrity

