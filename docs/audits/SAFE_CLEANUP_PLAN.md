# SAFE_CLEANUP_PLAN

## 1. Clearly unused items (safe to mark as deprecated)
Use schema comments or metadata tables to flag these so future migrations can drop them after monitoring.

| Item | Evidence | Non-breaking action |
| --- | --- | --- |
| `app_version.version_number`, `is_mandatory`, `update_url` | Flutter only ever selects the row `id`; no code references the other fields. | `COMMENT ON COLUMN` (or Supabase dashboard description) stating “deprecated / unused by Choice Lux Cars app as of Nov 2025.” |
| `device_tokens.profile_id`, `device_tokens.last_seen` | Push stack only stores token strings and never updates profile linkage or heartbeat. | Add column comments marking them unused; optionally add a migration checklist entry reminding backend devs before removal. |
| `driver_flow.vehicle_time`, `odo_start_img`, `payment_collected_ind`, `job_closed_odo_img` | Driver workflow screens never read/write these columns. | Set explicit default comments like “legacy placeholder—safe to remove once confirmed.” |
| `expenses.expense_description`, `exp_amount`, `exp_date`, `slip_image`, `expense_location`, `other_description` | Expense UI only lists job linkage + metadata, no detailed expense capture. | Mark columns as deprecated via comments; add TODO in migration planning doc referencing this audit. |
| `invoices.pdf_url`, `invoices.job_allocated` | Invoice pipeline writes files to storage and links via `jobs.invoice_pdf`; other fields unused. | Add `COMMENT` clarifying they’re superseded by storage URLs; log it in deployment guide. |
| `job_notification_log.is_reassignment`, `processed_at` | Assignment history viewer only needs status + timestamps already used. | Add comment “not consumed by Flutter; leave for backend integrations only if required.” |
| `login_attempts.attempted_at`, `ip_address`, `user_agent` | Auth flow never queries audit data. | Mark columns as unused but potentially useful for security; leave note to analytics team. |
| `notification_delivery_log.fcm_response`, `sent_at`, `error_message`, `retry_count` | Push log viewer shows only `success`/token; details never surface. | Comment each column as “available for future troubleshooting; currently unused.” |
| `notifications_backup.suppressed` | Backup table rewrite removed flag usage. | Add schema comment and mention in README’s Supabase appendix. |
| `profiles.traf_reg`, `traf_exp_date` | No UI element references traffic registration info. | Comment columns as deprecated. |
| `transport.pickup_arrived_at`, `passenger_onboard_at`, `dropoff_arrived_at` | Trip progress screens rely on separate `trip_progress` table; transport rows never update these. | Mark columns deprecated and document that trip milestones moved elsewhere. |

## 2. Possibly unused / needs further checking
Items not referenced in Flutter, but may be exercised by cron jobs, Edge functions, or admin tooling.

| Item | Non-breaking action |
| --- | --- |
| RPCs: `app_auth.create_user_profile`, `public.arrive_at_dropoff`, `block_notifications_insert`, `calculate_job_progress`, `clean_text`, `copy_quote_transport_to_job`, `create_user_profile`, `current_user_role`, `get_driver_current_job`, `get_invoice_data_for_job`, `get_job_progress`, `get_quote_data_for_pdf`, `get_trip_progress`, `get_voucher_data_for_pdf`, `handle_notifications_insert`, `http_post_for_cron`, `insert_notification`, `log_notification_created`, `notify_driver_progress`, `set_updated_at`, `suppress_notifications_insert`, `update_driver_flow_activity`, `update_expired_quotes`, `update_job_total`, `update_trip_progress_timestamp`, `updatelastmessage`, `upsert_device_token` | Add a Supabase “function registry” markdown where each RPC lists its owner and consumer; annotate every unreferenced RPC with “needs verification—no Flutter usage as of Nov 2025.” This keeps them documented without deleting anything. |
| Trigger `new_user_trigger` | Document inside Supabase Studio (or schema comment) that the trigger mirrors Auth users → `profiles`, and confirm with backend owners whether redundancies exist. |
| Columns in `app_version`, `device_tokens`, `driver_flow`, etc., if other services might still use them | Before marking as deprecated, add telemetry logging (e.g., Supabase row-level auditing) to see whether any non-Flutter client updates them. |

## 3. App ↔ DB mismatches to fix carefully
Focus on additive or documenting changes so existing data/API contracts keep working.

| Mismatch | Non-breaking action |
| --- | --- |
| DTO fields like `bank_name`, `currency`, `subtotal`, `payment_terms`, `transport_details`, `number_passangers` exist only in RPC projections | Create a documented view or stable RPC contract (`view_invoice_payload`, `view_voucher_payload`) that materializes these virtual fields. Keep current RPCs but add inline comments describing each derived key’s origin, so future schema changes don’t silently break the projections. |
| `jobs.pax` vs app’s `number_passengers`/`number_passangers` | Introduce a computed column or view exposing `jobs.pax AS number_passengers`, or adjust RPC output to include both spellings while retaining the original column. Clearly document this mapping in Supabase docs. |
| Transport timestamps: app expects string `pickup_time`/`time` values, DB stores timestamps (`client_pickup_time`) | Update `get_voucher_data_for_job` / `get_invoice_data_for_pdf` to add explicit comments (or return both raw timestamp and formatted string) so engineers know the projection is lossy. No table changes needed. |
| Banking details hard-coded into RPC response, not stored anywhere | Add a small `settings_banking_details` table or config JSON and have the RPC read from it while keeping existing hard-coded defaults as fallbacks. This lets ops update details without code deploys and doesn’t break current behaviour. |
| `device_tokens` table doesn’t capture profile linkage (`profile_id` unused) | Instead of dropping the column, add a Supabase row-level comment encouraging future work to populate it (e.g., when mobile apps start storing profile IDs). |

> All proposed steps keep the live schema intact: we’re only adding documentation, views, or secondary columns and noting deprecations. Actual `DROP`, `RENAME`, or destructive actions should wait until each item has monitoring/ownership.*** End Patch

