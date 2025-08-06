# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Core Flutter Commands
- **Run app**: `flutter run` (for debug mode)
- **Run on web**: `flutter run -d chrome`
- **Build for production**: `flutter build apk --release` (Android) or `flutter build web --release` (Web)
- **Install dependencies**: `flutter pub get`
- **Clean build**: `flutter clean && flutter pub get`
- **Analyze code**: `flutter analyze`
- **Run tests**: `flutter test`

### Code Generation (Riverpod)
- **Generate providers**: `dart run build_runner build`
- **Watch for changes**: `dart run build_runner watch --delete-conflicting-outputs`

### Deployment
- **Deploy to Firebase Hosting**: `firebase deploy --only hosting`
- **Build web for deployment**: `flutter build web --release`

## Architecture Overview

### Technology Stack
- **Frontend**: Flutter 3.22+ with Material 3 Design
- **State Management**: Riverpod 2.5+ with code generation (@riverpod annotations)
- **Routing**: GoRouter 14.2+ with programmatic navigation
- **Backend**: Supabase (PostgreSQL database, Auth, Storage)
- **Push Notifications**: Firebase Cloud Messaging (FCM)
- **PDF Generation**: `pdf` + `printing` packages
- **File Handling**: `image_picker`, `file_picker`

### Project Structure
- **Feature-based architecture**: Each feature (clients, jobs, vehicles, etc.) has its own folder with models, providers, screens, and widgets
- **Shared components**: Common widgets and layouts in `lib/shared/`
- **Core services**: Supabase, Firebase, and utility services in `lib/core/`
- **Centralized routing**: All routes defined in `lib/app/app.dart`
- **Role-based access control**: Implemented through auth provider and route guards

## Key Architecture Patterns

### State Management with Riverpod
- Uses `@riverpod` annotation for code generation
- Providers follow naming convention: `[feature]Provider`, `[feature]NotifierProvider`
- Auth state managed globally through `authProvider` and `userProfileProvider`
- Each feature has dedicated providers (e.g., `clientsProvider`, `jobsProvider`)

### Authentication & Authorization
- **Supabase Auth**: Handles user authentication with email/password
- **Role-based routing**: Routes protected based on user roles (admin, manager, driver, driver_manager, agent, unassigned)
- **Profile management**: User profiles stored in `profiles` table with role assignments
- **Route guards**: Implemented in GoRouter's redirect logic in `lib/app/app.dart:52-91`

### Database Architecture (Supabase)
Key tables and relationships:
- **profiles**: User information and roles
- **clients**: Company client information
- **agents**: Client representatives (many-to-one with clients)
- **vehicles**: Fleet management
- **jobs**: Job assignments linking clients, vehicles, and drivers
- **transport**: Trip details for jobs
- **quotes**: Quote generation and management
- **invoices**: Invoice generation from completed jobs

### Error Handling Strategy
- **Global error handling**: Configured in `main.dart:12-25` to prevent red screens
- **Service-level error handling**: Each service method handles and re-throws appropriate errors
- **UI error handling**: AsyncValue pattern from Riverpod for loading/error/data states
- **User-friendly messages**: Error messages mapped to user-friendly text in auth provider

### File Upload & Storage
- **Supabase Storage**: Used for PDFs, images, and documents
- **Organized buckets**: `quotes`, `invoices`, `vouchers`, `job-photos`, `client-photos`
- **File size limits**: 10MB max file size (defined in `AppConstants.maxFileSize`)

## Development Guidelines

### Code Organization
- Follow feature-based folder structure
- Use descriptive file and class names
- Keep models in dedicated `models/` folders within features
- Providers should be in `providers/` folders within features
- Screens go in `screens/` folders, widgets in `widgets/` folders

### Naming Conventions
- **Files**: snake_case (e.g., `client_detail_screen.dart`)
- **Classes**: PascalCase (e.g., `ClientDetailScreen`)
- **Variables/methods**: camelCase (e.g., `clientProvider`)
- **Constants**: UPPER_SNAKE_CASE (e.g., `MAX_FILE_SIZE`)
- **Enums**: PascalCase with descriptive names (e.g., `UserRole`, `JobStatus`)

### State Management Best Practices
- Use `@riverpod` annotation for new providers
- Implement proper loading/error states with AsyncValue
- Cache data appropriately in providers
- Use `ref.invalidate()` to refresh data after mutations
- Follow Riverpod's pattern for provider dependencies

### Navigation Patterns
- Use GoRouter's named routes defined in `lib/app/app.dart`
- Pass data through route parameters or `extra` parameter for complex objects
- Always use `context.go()` for navigation, not `context.push()` for main navigation
- Implement proper back button handling in custom app bars

### Firebase Cloud Messaging Integration
- FCM tokens automatically managed in auth flow
- Notifications handled in `FirebaseService`
- Background message handler configured in `main.dart:43`
- Token updates handled on sign in/sign up

### Responsive Design
- Use `ResponsiveGrid` widget for grid layouts
- Mobile-first approach with breakpoints defined in responsive widgets
- Test on both mobile and desktop web views
- Use `MediaQuery` for screen size-dependent logic

## Configuration Management

### Environment Setup
- Supabase configuration in `lib/core/constants.dart:40-42`
- Firebase configuration in `lib/core/constants.dart:44-50`
- Storage bucket names defined as constants
- App-wide settings in `AppConstants` class

### Asset Management
- Images in `assets/images/`
- Fonts in `assets/fonts/`
- PDF templates in `assets/pdf_templates/`
- All assets must be registered in `pubspec.yaml:93-96`

## Testing Strategy
- Widget tests in `test/` directory
- Use Flutter's built-in testing framework
- Test file naming: `*_test.dart`
- Focus on testing business logic and user interactions

## Deployment Process
- **Web deployment**: Automatic deployment to Firebase Hosting on push to master
- **Android**: Manual APK builds using `flutter build apk --release`
- **GitHub Actions**: Configured for CI/CD with preview deployments on PRs

## Important Notes
- **No hot reload issues**: The app is configured to handle service initialization failures gracefully
- **Material 3 theming**: Custom theme defined in `lib/app/theme.dart`
- **Dark mode support**: Theme mode set to dark by default in `lib/app/app.dart:43`
- **Error resilience**: Services continue to work even if Firebase or Supabase initialization fails
- **Role-based access**: Always check user role before allowing access to features
- **Soft deletes**: Most entities use soft delete patterns (status = 'inactive' + deleted_at timestamp)