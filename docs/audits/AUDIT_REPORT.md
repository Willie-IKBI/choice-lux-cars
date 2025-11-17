# AUDIT_REPORT

## 1. Tables & Columns Usage
Detection method: string-level scan across `lib/**/*.dart` followed by spot verification inside the relevant models/services. A sampled reference for each heavily used entity is included below; absence findings are strictly “not referenced anywhere in Flutter code” and should be double-checked before any destructive change.

### `vehicles`
- Referenced: `id`, `make`, `model`, `reg_plate`, `reg_date`, `fuel_type`, `vehicle_image`, `status`, `created_at`, `updated_at`, `license_expiry_date` (see the `Vehicle.fromJson` mapper that reads/writes every column).

```1:64:lib/features/vehicles/models/vehicle.dart
class Vehicle {
  ...
  factory Vehicle.fromJson(Map<String, dynamic> json) => Vehicle(
    id: json['id'] as int?,
    make: json['make'] as String? ?? '',
    model: json['model'] as String? ?? '',
    regPlate: json['reg_plate'] as String? ?? '',
    regDate: json['reg_date'] != null
        ? DateTime.parse(json['reg_date'])
        : DateTime(2000, 1, 1),
    fuelType: json['fuel_type'] as String? ?? '',
    vehicleImage: json['vehicle_image'] as String?,
    status: json['status'] as String? ?? 'Active',
    licenseExpiryDate: ...
```

### `agents`
- Referenced: `id`, `agent_name`, `client_key`, `contact_number`, `contact_email`, `created_at`, `updated_at`, `is_deleted`.
- Not referenced: _none_.

### `app_notifications`
- Referenced: `id`, `user_id`, `job_id`, `message`, `notification_type`, `priority`, `action_data`, `is_read`, `is_hidden`, `read_at`, `dismissed_at`, `expires_at`, `created_at`, `updated_at`.

```1:82:lib/features/notifications/models/notification.dart
class AppNotification {
  final String id;
  final String userId;
  final String jobId;
  final String message;
  final bool isRead;
  final bool isHidden;
  final String notificationType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? readAt;
  final DateTime? dismissedAt;
  final String priority;
  final Map<String, dynamic>? actionData;
  final DateTime? expiresAt;
  ...
```

### `app_version`
- Referenced: only `id`.
- Not referenced: `version_number`, `is_mandatory`, `update_url`.

### `clients`
- Referenced: all columns (`company_name`, contact fields, website, registration, VAT, billing, status, timestamps, etc.).
- Not referenced: _none_.

### `device_tokens`
- Referenced: `id`, `token`.
- Not referenced: `profile_id`, `last_seen` (no code links tokens back to profiles or updates heartbeat timestamps).

### `driver_flow`
- Referenced: `id`, `job_id`, `vehicle_collected`, `user`, `odo_start_reading`, `pickup_arrive_loc`, `pickup_arrive_time`, `pickup_ind`, `transport_completed_ind`, `job_closed_odo`, `job_closed_time`, `current_step`, `current_trip_index`, `progress_percentage`, `last_activity_at`, `job_started_at`, `vehicle_collected_at`, `pdp_start_image`, `updated_at`, `driver_user`, `pickup_loc`.
- Not referenced: `vehicle_time`, `odo_start_img`, `payment_collected_ind`, `job_closed_odo_img`.

### `expenses`
- Referenced: `id`, `job_id`, `user`, `created_at`, `updated_at`.
- Not referenced: `expense_description`, `exp_amount`, `exp_date`, `slip_image`, `expense_location`, `other_description`.

### `invoices`
- Referenced: `id`, `quote_id`, `invoice_number`, `invoice_date`, `status`, `created_at`.
- Not referenced: `pdf_url`, `job_allocated`.

### `job_notification_log`
- Referenced: `id`, `job_id`, `driver_id`, `created_at`, `status`.
- Not referenced: `is_reassignment`, `processed_at`.

### `jobs`
- Referenced: every column (IDs, monetary fields, passenger info, status flags, timestamps, documents, etc.).

```1818:1846:supabase/migrations/20250110000000_baseline.sql
CREATE TABLE IF NOT EXISTS "public"."jobs" (
    "id" bigint NOT NULL,
    "client_id" bigint,
    "vehicle_id" bigint,
    "driver_id" "uuid",
    "order_date" "date",
    "amount" numeric,
    ...
    "job_number" "text",
    "invoice_pdf" "text"
);
```

### `login_attempts`
- Referenced: `id`, `email`, `success`.
- Not referenced: `attempted_at`, `ip_address`, `user_agent`.

### `notification_delivery_log`
- Referenced: `id`, `notification_id`, `user_id`, `fcm_token`, `success`.
- Not referenced: `fcm_response`, `sent_at`, `error_message`, `retry_count`.

### `notifications_backup`
- Referenced: all columns except `suppressed`.
- Not referenced: `suppressed` (legacy flag never read).

### `profiles`
- Referenced: `id`, `display_name`, `profile_image`, `address`, `number`, `kin`, `kin_number`, `role`, `driver_licence`, `driver_lic_exp`, `pdp`, `pdp_exp`, `user_email`, `fcm_token`, `status`, `fcm_token_web`.
- Not referenced: `traf_reg`, `traf_exp_date`.

### `quotes`
- Referenced: all columns (IDs, metadata, descriptions, status, timestamps, location).
- Not referenced: _none_.

### `quotes_transport_details`
- Referenced: all columns.
- Not referenced: _none_.

### `transport`
- Referenced: `id`, `job_id`, `pickup_date`, `pickup_location`, `dropoff_location`, `notes`, `client_pickup_time`, `client_dropoff_time`, `amount`, `created_at`, `updated_at`, `status`.
- Not referenced: `pickup_arrived_at`, `passenger_onboard_at`, `dropoff_arrived_at`.

```2041:2054:supabase/migrations/20250110000000_baseline.sql
CREATE TABLE IF NOT EXISTS "public"."transport" (
    "id" bigint NOT NULL,
    "job_id" bigint,
    "pickup_date" timestamp without time zone,
    "pickup_location" "text",
    "dropoff_location" character varying,
    "notes" "text",
    "client_pickup_time" timestamp without time zone,
    "client_dropoff_time" timestamp without time zone,
    "amount" numeric,
    "created_at" timestamp with time zone ...,
    "status" "text" DEFAULT 'pending'::"text",
    "pickup_arrived_at" timestamp with time zone,
    "passenger_onboard_at" timestamp with time zone,
    "dropoff_arrived_at" timestamp with time zone
);
```

### `user_notification_preferences`
- Referenced: all columns (each boolean flag plus quiet hours and timestamps).
- Not referenced: _none_.

## 2. Functions / RPCs / Triggers
- **Used RPCs** (explicit `SupabaseClient.rpc` calls):
  - `public.cleanup_expired_notifications` – invoked when admins purge notifications.  
    ```76:166:lib/features/notifications/services/notification_service.dart
    final response = await _supabase.rpc(
      'get_notification_stats',
      params: {'user_uuid': currentUser.id},
    );
    ...
    await _supabase.rpc(
      'mark_notifications_as_read',
      params: {'notification_ids': notificationIds},
    );
    ```
  - `public.get_notification_stats` – described above; used for dashboard stats.
  - `public.mark_notifications_as_read` – bulk mark endpoint from same service block.
  - `public.get_invoice_data_for_pdf` – used by `InvoiceRepository` for PDF generation.  
    ```9:35:lib/features/invoices/services/invoice_repository.dart
    final response = await _supabase.rpc(
      'get_invoice_data_for_pdf',
      params: {'p_job_id': int.parse(jobId)},
    );
    ```
  - `public.get_voucher_data_for_job` – used by `VoucherRepository` before uploading vouchers.  
    ```10:28:lib/features/vouchers/services/voucher_repository.dart
    final response = await _supabase.rpc(
      'get_voucher_data_for_job',
      params: {'p_job_id': jobId},
    );
    ```
- **Unused RPCs / Functions**: `app_auth.create_user_profile`, `public.arrive_at_dropoff`, `block_notifications_insert`, `calculate_job_progress`, `clean_text`, `copy_quote_transport_to_job`, `create_user_profile`, `current_user_role`, `get_driver_current_job`, `get_invoice_data_for_job`, `get_job_progress`, `get_quote_data_for_pdf`, `get_trip_progress`, `get_voucher_data_for_pdf`, `handle_notifications_insert`, `http_post_for_cron`, `insert_notification`, `log_notification_created`, `notify_driver_progress`, `set_updated_at`, `suppress_notifications_insert`, `update_driver_flow_activity`, `update_expired_quotes`, `update_job_total`, `update_trip_progress_timestamp`, `updatelastmessage`, `upsert_device_token`.
- **Triggers**: `new_user_trigger` (ties Supabase Auth to profile creation) is not referenced anywhere in Flutter – it only runs server-side and the app never queries it explicitly.
- **Views**: none defined in the schema files.

## 3. App → DB Mismatches
- **JSON fields without backing columns**: The Flutter models consume keys such as `bank_name`, `account_number`, `client_contact_person`, `client_billing_address`, `currency`, `subtotal`, `transport_details`, etc., coming from RPC payloads rather than raw tables (see `InvoiceData.fromJson` and `VoucherData.fromJson`).  

```1:168:lib/features/invoices/models/invoice_data.dart
  final String? clientContactPerson;
  ...
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String currency;
  final BankingDetails bankingDetails;
  ...
  clientContactPerson: json['client_contact_person'] as String?,
  ...
  subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
  taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
```

- **Typo’d / alias-only fields**: `VoucherData` expects `number_passangers`, `client_registration`, `transport_details`, etc., none of which exist as columns; they are spellings/aliases produced by `get_voucher_data_for_job`.  

```1:84:lib/features/vouchers/models/voucher_data.dart
      numberPassengers: (json['number_passangers'] is num)
          ? (json['number_passangers'] as num).toInt()
          : int.tryParse(json['number_passangers']?.toString() ?? '0') ?? 0,
      transport:
          (json['transport_details'] as List<dynamic>?)
              ?.map(...)
```

- **Type mismatch**: `InvoiceData.numberPassengers` and `VoucherData.numberPassengers` rely on RPC fields (`number_passengers` / `number_passangers`) but the table column is `jobs.pax numeric` (`20250110000000_baseline.sql`). Any direct `.select('pax')` mapping would fail unless the RPC keeps aliasing `pax` into those names.
- **Transport timestamps**: The app expects per-trip `pickup_time`/`time` strings in the voucher/invoice transport detail objects, but the base table only stores `client_pickup_time` as a timestamp. Converting to/from strings is handled inside RPCs; any direct table fetch would miss those convenience fields.
- **Banking details**: Invoice PDFs rely on nested `banking_details` JSON (bank name, account number, branch code, swift, etc.) that do not live in any table; they come from literals inside `get_invoice_data_for_pdf`.

## 4. Potential Cleanup Candidates (NON-DESTRUCTIVE)
_Marking only as “candidates”; validate usage in other deployments or backend jobs before removing._

- **Tables/columns**:  
  - `app_version.version_number`, `app_version.is_mandatory`, `app_version.update_url`.  
  - `device_tokens.profile_id`, `device_tokens.last_seen`.  
  - `driver_flow.vehicle_time`, `driver_flow.odo_start_img`, `driver_flow.payment_collected_ind`, `driver_flow.job_closed_odo_img`.  
  - `expenses.expense_description`, `exp_amount`, `exp_date`, `slip_image`, `expense_location`, `other_description`.  
  - `invoices.pdf_url`, `invoices.job_allocated`.  
  - `job_notification_log.is_reassignment`, `job_notification_log.processed_at`.  
  - `login_attempts.attempted_at`, `ip_address`, `user_agent`.  
  - `notification_delivery_log.fcm_response`, `sent_at`, `error_message`, `retry_count`.  
  - `notifications_backup.suppressed`.  
  - `profiles.traf_reg`, `profiles.traf_exp_date`.  
  - `transport.pickup_arrived_at`, `transport.passenger_onboard_at`, `transport.dropoff_arrived_at`.
- **RPCs / triggers**: all functions listed as unused above plus the `new_user_trigger` can be revisited. Some may still be important for cron jobs, RLS hooks, or Supabase auth workflows even though the Flutter app never references them directly.
- **App-only DTO fields**: keys such as `bank_name`, `currency`, `payment_terms`, `transport_details`, `number_passangers` exist solely inside RPC outputs. If you want a thinner schema, consider moving those projections into the app layer or a materialized view before pruning anything.

> **Reminder:** every candidate here is identified strictly via absence in the Flutter source. Keep the backup dumps (e.g., `supabase/backup-pre-repair.sql`) handy and confirm there are no other consumers (Edge functions, cron jobs, BI tooling) before dropping columns, RPCs, or triggers.

