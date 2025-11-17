# 🚗 Choice Lux Cars

A professional mobile-first application designed to streamline operations for a luxury car rental company. Built with Flutter, Riverpod, and Supabase.

## 📱 Features

- **Authentication & Role Management** - Secure login with role-based access (Admin, Manager, Driver, Driver Manager)
- **Client Management** - Complete CRM functionality for managing client information
- **Quote Generation** - Create, edit, and generate PDF quotes with line items and VAT
- **Job Management** - Track job assignments, status updates, and photo uploads
- **Invoice Generation** - Generate invoices from completed jobs with PDF export
- **Vehicle Management** - Fleet tracking and vehicle assignment
- **Voucher System** - Generate vouchers without pricing for promotional use
- **Push Notifications** - Real-time updates via Firebase Cloud Messaging
- **Responsive Design** - Works on Android and Web (mobile + desktop)

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.22+, Material 3
- **State Management**: Riverpod 2.5+
- **Routing**: GoRouter 14.2+
- **Backend**: Supabase (Auth, Postgres DB, Storage)
- **Notifications**: Firebase Cloud Messaging
- **PDF Generation**: pdf + printing packages

## 📚 Documentation

All specs, deployment notes, and audits live in [`docs/`](docs/README.md). Start with `docs/README.md` for quick links to product flows, Supabase/Firebase guides, and the latest audit reports.

## 📁 Project Structure

```
lib/
├── app/                    # App-level configuration
│   ├── app.dart           # Main app widget with ProviderScope
│   ├── theme.dart         # Material 3 theming
│   └── router.dart        # GoRouter configuration
├── core/                  # Core utilities and services
│   ├── constants.dart     # App constants, enums, and messages
│   ├── utils.dart         # Utility functions and extensions
│   └── services/          # Core services
│       ├── supabase_service.dart
│       ├── pdf_service.dart
│       ├── fcm_service.dart
│       └── auth_service.dart
├── features/              # Feature modules
│   ├── auth/              # Authentication
│   │   ├── login/
│   │   └── signup/
│   ├── dashboard/         # Main dashboard
│   ├── clients/           # Client management
│   ├── quotes/            # Quote generation
│   ├── jobs/              # Job management
│   ├── invoices/          # Invoice generation
│   ├── vehicles/          # Vehicle management
│   ├── notifications/     # Push notifications
│   └── vouchers/          # Voucher system
├── shared/                # Shared components
│   ├── widgets/           # Reusable widgets
│   └── layout/            # Layout components
└── main.dart              # App entry point
```

## 🚀 Getting Started

### Prerequisites

- Flutter 3.22+ installed
- Dart 3.8+ installed
- Supabase account and project
- Firebase project (for FCM)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd choice_lux_cars
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Update `lib/core/constants.dart` with your Supabase URL and anon key
   - Set up your database tables (see Database Schema below)

4. **Configure Firebase (for FCM)**
   - Add your Firebase configuration files
   - Set up Firebase Cloud Messaging

5. **Run the app**
   ```bash
   flutter run
   ```

### Environment Configuration

The app uses `--dart-define` flags to securely configure API keys and URLs. Run the app with these flags:

```bash
flutter run --dart-define=SUPABASE_URL=your_supabase_url \
  --dart-define=SUPABASE_ANON_KEY=your_supabase_anon_key \
  --dart-define=FIREBASE_API_KEY=your_firebase_api_key \
  --dart-define=FIREBASE_PROJECT_ID=your_firebase_project_id \
  --dart-define=FIREBASE_APP_ID=your_firebase_app_id \
  --dart-define=FIREBASE_SENDER_ID=your_firebase_sender_id \
  --dart-define=FIREBASE_AUTH_DOMAIN=your_firebase_auth_domain \
  --dart-define=FIREBASE_STORAGE_BUCKET=your_firebase_storage_bucket
```

**Required Environment Variables:**
- `SUPABASE_URL`: Your Supabase project URL
- `SUPABASE_ANON_KEY`: Your Supabase anonymous/public key
- `FIREBASE_API_KEY`: Your Firebase API key
- `FIREBASE_PROJECT_ID`: Your Firebase project ID
- `FIREBASE_APP_ID`: Your Firebase app ID
- `FIREBASE_SENDER_ID`: Your Firebase messaging sender ID
- `FIREBASE_AUTH_DOMAIN`: Your Firebase auth domain
- `FIREBASE_STORAGE_BUCKET`: Your Firebase storage bucket

> **Note**: Never commit API keys or sensitive configuration to version control. The app is configured to load these values from build-time flags.

## 🗄️ Database Schema

### Core Tables

#### `profiles`
- `id` (UUID, primary key)
- `role` (enum: admin, manager, driver, driver_manager)
- `display_name` (text)
- `fcm_token` (text)
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### `clients`
- `id` (UUID, primary key)
- `business_name` (text)
- `contact_person` (text)
- `email` (text)
- `phone` (text)
- `address` (text)
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### `quotes`
- `id` (UUID, primary key)
- `client_id` (UUID, foreign key)
- `status` (enum: draft, sent, accepted, rejected, expired)
- `total_amount` (decimal)
- `vat_amount` (decimal)
- `pdf_url` (text)
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### `jobs`
- `id` (UUID, primary key)
- `quote_id` (UUID, foreign key)
- `client_id` (UUID, foreign key)
- `vehicle_id` (UUID, foreign key)
- `driver_id` (UUID, foreign key)
- `status` (enum: pending, assigned, in_progress, completed, cancelled)
- `pickup_location` (text)
- `dropoff_location` (text)
- `pickup_photos` (text[])
- `dropoff_photos` (text[])
- `created_at` (timestamp)
- `updated_at` (timestamp)

#### `vehicles`
- `id` (UUID, primary key)
- `make` (text)
- `model` (text)
- `year` (integer)
- `license_plate` (text)
- `color` (text)
- `status` (enum: available, in_use, maintenance)
- `created_at` (timestamp)
- `updated_at` (timestamp)

## 🔧 Development

### Code Style

- Follow Flutter/Dart conventions
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

### State Management

- Use Riverpod for all state management
- Create providers for each feature
- Use `@riverpod` annotation for code generation

### Testing

- Write unit tests for business logic
- Write widget tests for UI components
- Use `flutter_test` package

### Git Workflow

- Use feature branches for new development
- Write descriptive commit messages
- Create pull requests for code review

## 📦 Build & Deploy

### Android
```bash
flutter build apk --release
```

### Web
```bash
flutter build web --release
```

### Deploy to Firebase Hosting
```bash
firebase deploy --only hosting
```

### Live Demo
- **Web App**: https://choice-lux-cars-8d510.web.app
- **GitHub Repository**: https://github.com/Willie-IKBI/choice-lux-cars

### Automatic Deployment
The app is automatically deployed to Firebase Hosting when changes are pushed to the `master` branch. Pull requests also get preview deployments.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔄 Migration from FlutterFlow

This project is being migrated from FlutterFlow to a clean Flutter architecture. The migration includes:

- ✅ Project structure setup
- ✅ Dependencies configuration
- ✅ Basic routing and navigation
- ✅ Theme configuration
- ⏳ Authentication implementation
- ⏳ Feature modules implementation
- ⏳ PDF generation
- ⏳ Push notifications
- ⏳ Database integration
- ⏳ Testing and deployment

See `tasks.md` for the complete migration checklist.
