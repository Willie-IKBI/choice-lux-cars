
# 🗃️ Choice Lux Cars – Supabase Data Model Reference (Corrected)

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
- `jobs`
- `login_attempts`
- `notifications`
- `profiles`
- `quotes`
- `quotes_transport_details`
- `transport`
- `vehicles`

---

## 🧾 `agents`

| Column         | Type      | Description                           |
|----------------|-----------|---------------------------------------|
| id             | bigint    | Primary key                           |
| agent_name     | text      | Agent’s name                          |
| client_key     | bigint    | FK to `clients.id`                    |
| contact_number | text      | Phone number                          |
| contact_email  | text      | Email address                         |
| created_at     | timestamp | Creation timestamp                    |
| updated_at     | timestamp | Last update                           |

---

## 🔢 `app_version`

| Column         | Type     | Description                  |
|----------------|----------|------------------------------|
| id             | bigint   | Primary key                  |
| version_number | text     | Version label                |
| is_mandatory   | boolean  | Require update?              |
| update_url     | text     | Link to update/download page |

---

## 👥 `clients`

| Column         | Type     | Description                  |
|----------------|----------|------------------------------|
| id             | bigint   | Primary key                  |
| company_name   | text     | Client's name                |
| contact_person | text     | Main contact name            |
| contact_number | text     | Phone                        |
| contact_email  | text     | Email                        |
| company_logo   | text     | Logo URL                     |
| status         | text     | Client status (active, pending, vip, inactive) |
| deleted_at     | timestamp| Soft delete timestamp        |
| created_at     | timestamp| Creation date                |
| updated_at     | timestamp| Last modified                |

**Status Values:**
- `active` - Currently active client (default)
- `pending` - Client awaiting approval/activation
- `vip` - VIP client with special privileges
- `inactive` - Soft deleted client (preserved data)

**Soft Delete Implementation:**
- Clients are never permanently deleted by default
- `deleted_at` timestamp tracks when client was deactivated
- All related data (quotes, invoices, agents) remains intact
- Clients can be restored by updating status back to 'active'

---

## 🔒 `device_tokens`

| Column     | Type     | Description                      |
|------------|----------|----------------------------------|
| id         | bigint   | Primary key                      |
| profile_id | uuid     | FK to `profiles.id`              |
| token      | text     | FCM token                        |
| last_seen  | timestamp| Last usage timestamp             |

---

## 🚗 `driver_flow`

Tracks each driver's activity in a job.

| Column               | Type     | Description                          |
|----------------------|----------|--------------------------------------|
| id                   | bigint   | Primary key                          |
| job_id               | bigint   | FK to `jobs.id`                      |
| user                 | uuid     | Driver ID                            |
| vehicle_collected    | boolean  | Has vehicle been collected?          |
| transport_completed_ind | bool | Has transport completed?             |
| pickup_arrive_time   | timestamp| Time arrived at pickup               |
| pickup_arrive_loc    | text     | Location of pickup                   |
| job_closed_time      | timestamp| When job was closed                  |
| job_closed_odo       | numeric  | Final odometer reading               |
| job_closed_odo_img   | text     | Image of final odometer              |
| odo_start_reading    | numeric  | Starting odometer                    |
| odo_start_img        | text     | Image of starting odometer           |
| payment_collected_ind| boolean  | Was payment collected?               |

---

## 💸 `expenses`

| Column              | Type     | Description                  |
|---------------------|----------|------------------------------|
| id                  | bigint   | Primary key                  |
| job_id              | bigint   | FK to `jobs.id`              |
| expense_description | text     | Description                  |
| exp_amount          | numeric  | Cost                         |
| exp_date            | timestamp| Date incurred                |
| slip_image          | text     | Receipt image                |
| user                | text     | Username                     |

---

## 🧾 `invoices`

| Column         | Type     | Description                  |
|----------------|----------|------------------------------|
| id             | bigint   | Primary key                  |
| quote_id       | bigint   | FK to `quotes.id`            |
| invoice_number | text     | Human-readable invoice number|
| pdf_url        | text     | Invoice file URL             |
| invoice_date   | date     | Date issued                  |
| status         | text     | Pending, Paid, etc.          |
| job_allocated  | boolean  | Was job linked to invoice    |

---

## 📦 `jobs`

| Column           | Type     | Description                          |
|------------------|----------|--------------------------------------|
| id               | bigint   | Primary key                          |
| client_id        | bigint   | FK to `clients.id`                   |
| vehicle_id       | bigint   | FK to `vehicles.id`                  |
| agent_id         | bigint   | FK to `agents.id`                    |
| driver_id        | uuid     | Supabase user ID                     |
| order_date       | date     | Job order date                       |
| job_status       | text     | Current status                       |
| amount           | numeric  | Quoted amount                        |
| amount_collect   | boolean  | Whether to collect payment           |
| passenger_name   | text     |                                      |
| passenger_contact| text     |                                      |
| number_bags      | text     |                                      |
| job_start_date   | date     | Start date                           |
| notes            | text     | Extra notes                          |
| quote_no         | bigint   | Link to original quote               |
| voucher_pdf      | text     | URL to generated voucher             |
| cancel_reason    | text     |                                      |

---

## 📥 `login_attempts`

| Column      | Type     | Description               |
|-------------|----------|---------------------------|
| id          | uuid     | Primary key               |
| ip_address  | text     | IP at login               |
| email       | text     | Attempted email           |
| user_agent  | text     | Browser/device info       |
| success     | boolean  | Was it successful?        |
| attempted_at| timestamp| Attempt timestamp         |

---

## 🔔 `notifications`

| Column    | Type     | Description                  |
|-----------|----------|------------------------------|
| id        | uuid     | Primary key                  |
| user_id   | uuid     | FK to `auth.users`           |
| body      | text     | Message content              |
| created_at| timestamp| When it was sent             |

---

## 🙋‍♂️ `profiles`

| Column         | Type     | Description                     |
|----------------|----------|---------------------------------|
| id             | uuid     | FK to `auth.users.id`           |
| display_name   | text     | User’s name                     |
| role           | enum     | User role (admin, driver, etc.) |
| driver_licence | text     | License number                  |
| driver_lic_exp | date     | License expiry                  |
| pdp            | text     | PDP number                      |
| pdp_exp        | date     | PDP expiry                      |
| traf_reg       | text     | Traffic registration            |
| traf_exp_date  | date     | Expiry date                     |
| profile_image  | text     | Image URL                       |
| fcm_token      | text     | Device token for FCM            |
| address        | text     | Address                         |
| number         | text     | Phone                           |
| kin            | text     | Emergency contact               |
| kin_number     | text     | Emergency contact number        |
| user_email     | text     | Email                           |

---

## 📝 `quotes`

| Column            | Type     | Description                  |
|-------------------|----------|------------------------------|
| id                | bigint   | Primary key                  |
| quote_status      | text     | Draft, sent, accepted, etc.  |
| client_id         | bigint   | FK to `clients.id`           |
| agent_id          | bigint   | FK to `agents.id`            |
| vehicle_id        | bigint   | FK to `vehicles.id`          |
| driver_id         | uuid     | Assigned driver              |
| quote_date        | date     | Date issued                  |
| quote_amount      | numeric  | Total quoted amount          |
| quote_title       | text     | Title of quote               |
| quote_description | text     | Optional description         |
| quote_pdf         | text     | PDF URL                      |
| passenger_name    | text     |                              |
| passenger_contact | text     |                              |
| job_date          | date     | Intended date                |
| pax               | numeric  | Number of passengers         |
| luggage           | text     | Luggage description          |
| location          | text     | Route summary                |
| notes             | text     | Additional notes             |

---

## 🚚 `quotes_transport_details`

| Column         | Type     | Description                      |
|----------------|----------|----------------------------------|
| id             | bigint   | Primary key                      |
| quote_id       | bigint   | FK to `quotes.id`                |
| pickup_date    | timestamp| Scheduled time                   |
| pickup_location| text     | From                             |
| dropoff_location| text    | To                               |
| amount         | numeric  | Subtotal                         |
| notes          | text     | Notes per leg                    |

---

## 🚗 `transport`

| Column             | Type     | Description                  |
|--------------------|----------|------------------------------|
| id                 | bigint   | Primary key                  |
| job_id             | bigint   | FK to `jobs.id`              |
| pickup_date        | timestamp| When to pick up              |
| pickup_location    | text     | Where                        |
| dropoff_location   | text     | Where                        |
| client_pickup_time | timestamp| Actual time out              |
| client_dropoff_time| timestamp| Actual time in               |
| notes              | text     |                              |
| amount             | numeric  |                              |
| status             | enum     | trip status                  |

---

## 🚘 `vehicles`

| Column        | Type     | Description                  |
|---------------|----------|------------------------------|
| id            | bigint   | Primary key                  |
| make          | text     | Vehicle make                 |
| model         | text     | Vehicle model                |
| reg_plate     | text     | Registration plate           |
| reg_date      | date     | Registration date            |
| feul_type     | text     | Fuel type                    |
| vehicle_image | text     | Image URL                    |
| status        | text     | Available, In service, etc.  |

