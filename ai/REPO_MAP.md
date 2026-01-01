# Choice Lux Cars — Repository Map

**Generated:** 2025-01-XX  
**Audience:** CLC-ARCH, CLC-BUILD, CLC-REVIEW  
**Purpose:** Directory and file mapping for quick navigation

---

## Root Structure

```
choice-lux-cars/
├── ai/                    # Architecture documentation (this folder)
├── android/               # Android platform files
├── assets/                # Images, fonts, PDF templates
├── build/                 # Build artifacts (generated)
├── docs/                  # Project documentation
├── ios/                   # iOS platform files
├── lib/                   # Main application code
├── supabase/              # Supabase config, migrations, functions
├── test/                  # Test files
├── web/                   # Web platform files
└── pubspec.yaml           # Dependencies
```

---

## lib/ Structure

### lib/app/ — App Bootstrap & Globals
```
app/
├── app.dart               # Main app widget, GoRouter configuration
├── theme.dart             # ChoiceLuxTheme (light/dark themes)
├── theme_tokens.dart      # AppTokens extension (brand colors, spacing)
└── theme_helpers.dart     # BuildContext extension for theme access
```

### lib/core/ — Cross-Cutting Concerns
```
core/
├── config/
│   └── env.dart           # Environment variables (Supabase, Firebase)
├── constants/
│   ├── app_constants.dart      # App-wide constants
│   └── notification_constants.dart
├── constants.dart         # Legacy constants (enums, error messages)
├── errors/
│   └── app_exception.dart # Custom exception types
├── logging/
│   └── log.dart           # Log utility (Log.d, Log.e, etc.)
├── router/
│   └── guards.dart        # RouterGuards for auth/role-based routing
├── services/
│   ├── supabase_service.dart      # Supabase client wrapper, auth, profile
│   ├── fcm_service.dart           # Firebase Cloud Messaging service
│   ├── firebase_service.dart      # Firebase initialization
│   ├── upload_service.dart        # File upload to Supabase Storage
│   ├── job_deadline_check_service.dart
│   └── preferences_service.dart
├── supabase/
│   └── supabase_client_provider.dart  # Riverpod provider for SupabaseClient
├── types/
│   └── result.dart        # Result<T> type (success/error)
└── utils/
    ├── auth_error_utils.dart
    └── logger.dart
```

### lib/features/ — Vertical Slices

#### lib/features/auth/ — Authentication
```
auth/
├── auth.dart              # Barrel export
├── login/
│   └── login_screen.dart
├── signup/
│   └── signup_screen.dart
├── forgot_password/
│   └── forgot_password_screen.dart
├── reset_password/
│   └── reset_password_screen.dart
├── pending_approval_screen.dart
├── providers/
│   └── auth_provider.dart # AuthNotifier, UserProfileNotifier, providers
```

#### lib/features/jobs/ — Job Management
```
jobs/
├── jobs.dart              # Barrel export
├── jobs_screen.dart        # Main jobs list screen
├── data/
│   ├── jobs_repository.dart      # JobsRepository (Supabase queries)
│   └── trips_repository.dart     # TripsRepository
├── models/
│   ├── job.dart           # Job model
│   ├── trip.dart          # Trip model
│   └── job_step.dart      # JobStep enum
├── providers/
│   ├── jobs_provider.dart        # JobsProvider (StateNotifier)
│   └── trips_provider.dart       # TripsProvider
├── screens/
│   ├── create_job_screen.dart
│   ├── job_summary_screen.dart
│   ├── job_progress_screen.dart
│   ├── trip_management_screen.dart
│   └── admin_monitoring_screen.dart
├── services/
│   ├── driver_flow_api_service.dart
│   └── job_assignment_service.dart
└── widgets/
    ├── job_card.dart
    ├── job_list_card.dart
    ├── job_monitoring_card.dart
    ├── trip_edit_modal.dart
    ├── add_trip_modal.dart
    ├── step_indicator.dart
    ├── progress_bar.dart
    ├── odometer_capture_widget.dart
    ├── gps_capture_widget.dart
    ├── driver_activity_card.dart
    ├── active_jobs_summary.dart
    ├── vehicle_collection_modal.dart
    └── pickup_arrival_modal.dart
```

#### lib/features/quotes/ — Quote Management
```
quotes/
├── quotes.dart            # Barrel export
├── quotes_screen.dart     # Main quotes list screen
├── data/
│   └── quotes_repository.dart    # QuotesRepository
├── models/
│   ├── quote.dart         # Quote model
│   └── quote_transport_detail.dart
├── providers/
│   └── quotes_provider.dart      # QuotesProvider
├── screens/
│   ├── create_quote_screen.dart
│   ├── quote_details_screen.dart
│   └── quote_transport_details_screen.dart
├── services/
│   └── quote_pdf_service.dart    # PDF generation
└── widgets/
    └── quote_card.dart
```

#### lib/features/invoices/ — Invoice Management
```
invoices/
├── invoices.dart          # Barrel export
├── invoices_screen.dart   # Main invoices list screen
├── models/
│   └── invoice_data.dart # InvoiceData model (from RPC)
├── providers/
│   ├── invoice_controller.dart   # InvoiceController (StateNotifier)
│   └── can_create_invoice_provider.dart
├── services/
│   ├── invoice_repository.dart   # Fetches invoice data via RPC
│   ├── invoice_pdf_service.dart  # PDF generation
│   ├── invoice_config_service.dart
│   └── invoice_sharing_service.dart
└── widgets/
    └── invoice_action_buttons.dart
```

#### lib/features/vouchers/ — Voucher Management
```
vouchers/
├── vouchers.dart          # Barrel export
├── vouchers_screen.dart   # Main vouchers list screen
├── models/
│   └── voucher_data.dart  # VoucherData model (from RPC)
├── providers/
│   └── voucher_controller.dart   # VoucherController
├── screens/
│   └── pdf_viewer_screen.dart
├── services/
│   ├── voucher_repository.dart   # Fetches voucher data via RPC
│   ├── voucher_pdf_service.dart  # PDF generation
│   └── voucher_sharing_service.dart
└── widgets/
    └── voucher_action_buttons.dart
```

#### lib/features/clients/ — Client Management
```
clients/
├── clients.dart           # Barrel export
├── clients_screen.dart    # Main clients list screen
├── inactive_clients_screen.dart
├── data/
│   ├── clients_repository.dart   # ClientsRepository
│   └── agents_repository.dart    # AgentsRepository
├── models/
│   ├── client.dart        # Client model
│   ├── agent.dart         # Agent model
│   └── client_branch.dart # ClientBranch model
├── providers/
│   ├── clients_provider.dart     # ClientsProvider
│   ├── agents_provider.dart      # AgentsProvider
│   └── client_stats_provider.dart
├── screens/
│   ├── add_edit_client_screen.dart
│   ├── edit_client_screen.dart
│   ├── client_detail_screen.dart
│   └── add_edit_agent_screen.dart
└── widgets/
    ├── client_card.dart
    ├── agent_card.dart
    └── branch_management_modal.dart
```

#### lib/features/vehicles/ — Vehicle Management
```
vehicles/
├── vehicles.dart          # Barrel export
├── vehicles_screen.dart   # Main vehicles list screen
├── vehicle_editor_screen.dart
├── data/
│   └── vehicles_repository.dart  # VehiclesRepository
├── models/
│   └── vehicle.dart      # Vehicle model
├── providers/
│   └── vehicles_provider.dart    # VehiclesProvider
└── widgets/
    ├── vehicle_card.dart
    └── license_status_badge.dart
```

#### lib/features/users/ — User Management
```
users/
├── users.dart            # Barrel export
├── users_screen.dart     # Main users list screen
├── user_detail_screen.dart
├── user_profile_screen.dart
├── data/
│   └── users_repository.dart     # UsersRepository
├── models/
│   └── user_profile.dart # UserProfile model
├── providers/
│   └── users_provider.dart       # UsersProvider
└── widgets/
    ├── user_card.dart
    └── user_form.dart
```

#### lib/features/notifications/ — Notifications
```
notifications/
├── notifications.dart    # Barrel export
├── models/
│   └── notification.dart # AppNotification model
├── providers/
│   └── notification_provider.dart  # NotificationNotifier
├── screens/
│   ├── notification_list_screen.dart
│   └── notification_preferences_screen.dart
├── services/
│   ├── notification_service.dart      # NotificationService
│   └── notification_preferences_service.dart
└── widgets/
    └── notification_card.dart
```

#### lib/features/dashboard/ — Dashboard
```
dashboard/
├── dashboard.dart        # Barrel export
└── dashboard_screen.dart # Main dashboard screen
```

#### lib/features/insights/ — Analytics & Insights
```
insights/
├── insights.dart         # Barrel export
├── data/
│   └── insights_repository.dart  # InsightsRepository
├── models/
│   └── insights_data.dart
├── providers/
│   ├── insights_provider.dart
│   ├── jobs_insights_provider.dart
│   ├── client_insights_provider.dart
│   ├── driver_insights_provider.dart
│   ├── vehicle_insights_provider.dart
│   └── financial_insights_provider.dart
├── screens/
│   ├── insights_screen.dart
│   ├── jobs_insights_tab.dart
│   ├── client_insights_tab.dart
│   ├── driver_insights_tab.dart
│   ├── vehicle_insights_tab.dart
│   ├── financial_insights_tab.dart
│   ├── insights_jobs_list_screen.dart
│   └── completed_jobs_details_screen.dart
└── widgets/
    └── insights_card.dart
```

#### lib/features/branches/ — Branch Management
```
branches/
├── branches.dart         # Barrel export
├── data/
│   └── branches_repository.dart  # BranchesRepository
├── models/
│   └── branch.dart       # Branch model
└── providers/
    └── branches_provider.dart    # BranchesProvider
```

#### lib/features/pdf/ — PDF Shared Utilities
```
pdf/
├── pdf.dart              # Barrel export
├── pdf_config.dart       # PDF configuration constants
├── pdf_theme.dart        # PdfTheme (shared styling)
└── pdf_utilities.dart    # Logo loading, helpers
```

### lib/shared/ — Reusable UI Components
```
shared/
├── shared.dart           # Barrel export
├── mixins/
│   ├── image_picker_mixin.dart
│   └── gps_capture_mixin.dart
├── screens/
│   └── pdf_viewer_screen.dart
├── services/
│   └── pdf_viewer_service.dart
├── utils/
│   ├── status_color_utils.dart   # Status color helpers
│   ├── date_utils.dart
│   ├── sa_time_utils.dart        # South Africa timezone utils
│   ├── snackbar_utils.dart
│   ├── driver_flow_utils.dart
│   └── background_pattern_utils.dart
└── widgets/
    ├── dashboard_card.dart
    ├── luxury_app_bar.dart
    ├── luxury_button.dart
    ├── luxury_drawer.dart
    ├── notification_bell.dart
    ├── status_pill.dart
    ├── pagination_widget.dart
    ├── responsive_grid.dart
    ├── job_completion_dialog.dart
    └── system_safe_scaffold.dart
```

---

## Key Entry Points

### Application Entry
- **`lib/main.dart`** — App initialization, Supabase/Firebase setup, ProviderScope

### Routing
- **`lib/app/app.dart`** — GoRouter configuration, route definitions, guards

### State Management
- **`lib/main.dart`** — ProviderScope wrapper
- **`lib/features/*/providers/`** — Feature-specific providers

### Services
- **`lib/core/services/supabase_service.dart`** — Supabase client, auth, profile
- **`lib/core/services/fcm_service.dart`** — FCM token management, notifications
- **`lib/core/services/upload_service.dart`** — File uploads to Supabase Storage

### Repositories
- **`lib/features/*/data/*_repository.dart`** — Feature-specific data access

### PDF Generation
- **`lib/features/pdf/pdf_theme.dart`** — Shared PDF styling
- **`lib/features/quotes/services/quote_pdf_service.dart`** — Quote PDFs
- **`lib/features/invoices/services/invoice_pdf_service.dart`** — Invoice PDFs
- **`lib/features/vouchers/services/voucher_pdf_service.dart`** — Voucher PDFs

---

## File Count Summary

- **Features:** 11 feature modules
- **Screens:** ~40+ screen files
- **Providers:** ~20+ provider files
- **Repositories:** ~10+ repository files
- **Services:** ~15+ service files
- **Models:** ~15+ model files
- **Widgets:** ~50+ widget files

**Total Dart Files:** ~150+ (excluding generated files)

---

## Notes

- **No FlutterFlow artifacts** found in lib/ (clean migration)
- **No `*_model.dart` files** (using domain models instead)
- **Consistent naming:** snake_case for files, PascalCase for classes
- **Barrel exports:** Each feature has a `{feature}.dart` barrel file

