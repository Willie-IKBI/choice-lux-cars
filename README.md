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

3. **Configure Supabase and Firebase**
   - Set environment variables (or use `--dart-define`) for API keys
   - See [GOOGLE_MAPS_SETUP.md](GOOGLE_MAPS_SETUP.md) for Firebase and Maps setup
   - Set up your database tables (see Database Schema below)

4. **Run the app**
   ```bash
   # Set env vars then run, or use run_production.ps1 (Windows)
   $env:SUPABASE_URL="https://xxx.supabase.co"
   $env:SUPABASE_ANON_KEY="your_anon_key"
   $env:FIREBASE_API_KEY="your_firebase_key"
   $env:FIREBASE_VAPID_KEY="your_vapid_key"   # required for web push
   flutter run -d chrome
   ```

### Environment Configuration

The app uses `--dart-define` flags (or environment variables via build scripts). Required for all platforms:

- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Supabase anonymous/public key
- `FIREBASE_API_KEY` - Firebase API key
- `FIREBASE_VAPID_KEY` - **Required for web push** (from Firebase Console → Cloud Messaging → Web push certificates)

Optional: `FIREBASE_PROJECT_ID`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`

Use `run_production.ps1` (reads from env) or pass flags directly. See [scripts/README.md](scripts/README.md) and [docs/VERCEL_DEPLOYMENT.md](docs/VERCEL_DEPLOYMENT.md) for Vercel deployment.

> **Note**: Never commit API keys or sensitive configuration to version control.

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
# Set env vars first (FIREBASE_API_KEY, FIREBASE_VAPID_KEY, GOOGLE_MAPS_API_KEY, SUPABASE_URL, SUPABASE_ANON_KEY)
./scripts/build-web.sh
# or on Windows: .\scripts\build-web.ps1
```

### Test Production Build Locally (Before Deploy)
```powershell
# Set env vars first, then:
.\scripts\preview-web.ps1
# or: npm run preview
```
Builds and serves at `http://localhost:3000` for manual testing before deploying.

### Deploy to Vercel
The web app is deployed to [Vercel](https://vercel.com). Connect your repository; builds use `scripts/vercel-build.sh`. **Set all required env vars** in Vercel Project Settings (see [docs/VERCEL_DEPLOYMENT.md](docs/VERCEL_DEPLOYMENT.md)).

### Live Demo
- **Web App**: https://choice-lux-cars-app.vercel.app
- **GitHub Repository**: https://github.com/Willie-IKBI/choice-lux-cars

### Automatic Deployment
The app is automatically deployed to Vercel when changes are pushed to the connected branch. Pull requests get preview deployments.

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
