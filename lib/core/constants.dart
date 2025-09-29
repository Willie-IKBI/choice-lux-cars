import 'package:choice_lux_cars/core/config/env.dart';

// User roles
enum UserRole { admin, manager, driver, driverManager, agent, unassigned }

// Job statuses
enum JobStatus {
  pending,
  assigned,
  started,
  inProgress, // Maps to 'in_progress' in database
  readyToClose, // Maps to 'ready_to_close' in database
  completed,
  cancelled,
}

// Quote statuses
enum QuoteStatus { draft, sent, accepted, rejected, expired }

// Invoice statuses
enum InvoiceStatus { pending, paid, overdue, cancelled }

// App constants
class AppConstants {
  // API endpoints
  // Production Supabase instance
  // URL: https://hgqrbekphumdlsifuamq.supabase.co
  static const String supabaseUrl = Env.supabaseUrl;
  static const String supabaseAnonKey = Env.supabaseAnonKey;

  // Firebase Configuration
  static const String firebaseApiKey = Env.firebaseApiKey;
  static const String firebaseAuthDomain = Env.firebaseAuthDomain;
  static const String firebaseProjectId = Env.firebaseProjectId;
  static const String firebaseStorageBucket = Env.firebaseStorageBucket;
  static const String firebaseMessagingSenderId = Env.firebaseSenderId;
  static const String firebaseAppId = Env.firebaseAppId;

  // Storage buckets
  static const String quotesBucket = 'quotes';
  static const String invoicesBucket = 'invoices';
  static const String vouchersBucket = 'vouchers';
  static const String jobPhotosBucket = 'job-photos';
  static const String clientPhotosBucket = 'client-photos';

  // App settings
  static const String appName = 'Choice Lux Cars';
  static const String appVersion = '1.0.0';

  // Limits
  static const int maxQuotesFree = 5;
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxPhotosPerJob = 10;

  // Date formats
  static const String dateFormat = 'dd/MM/yyyy';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';
  static const String timeFormat = 'HH:mm';

  // Currency
  static const String currency = 'GBP';
  static const String currencySymbol = '£';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}

// Error messages (non-auth related)
class ErrorMessages {
  static const String networkError =
      'Network error. Please check your connection.';
  static const String permissionError =
      'You don\'t have permission to perform this action.';
  static const String validationError =
      'Please check your input and try again.';
  static const String unknownError =
      'An unexpected error occurred. Please try again.';
  static const String fileTooLarge =
      'File size exceeds the maximum limit of 10MB.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String weakPassword =
      'Password must be at least 8 characters long.';
}

// Success messages
class SuccessMessages {
  static const String loginSuccess = 'Login successful!';
  static const String logoutSuccess = 'Logged out successfully.';
  static const String saveSuccess = 'Saved successfully!';
  static const String deleteSuccess = 'Deleted successfully!';
  static const String uploadSuccess = 'Uploaded successfully!';
  static const String emailSent = 'Email sent successfully!';
}

// Route names
class RouteNames {
  static const String login = 'login';
  static const String signup = 'signup';
  static const String dashboard = 'dashboard';
  static const String clients = 'clients';
  static const String quotes = 'quotes';
  static const String jobs = 'jobs';
  static const String invoices = 'invoices';
  static const String vehicles = 'vehicles';
  static const String vouchers = 'vouchers';
}

// Job status constants
class JobStatusConstants {
  static const String pending = 'pending';
  static const String assigned = 'assigned';
  static const String started = 'started';
  static const String inProgress = 'in_progress';
  static const String readyToClose = 'ready_to_close';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';
  static const String open = 'open';
}

// Job status display labels
class JobStatusLabels {
  static const String assigned = 'ASSIGNED';
  static const String started = 'STARTED';
  static const String inProgress = 'IN PROGRESS';
  static const String readyToClose = 'READY TO CLOSE';
  static const String completed = 'COMPLETED';
  static const String cancelled = 'CANCELLED';
  static const String open = 'OPEN';
}

// Currency and banking constants
class CurrencyConstants {
  static const String defaultCurrency = 'ZAR';
  static const String currencySymbol = 'R';
  static const String swiftCode = 'SBZAZAJJ';
  static const String bankName = 'Standard Bank';
  static const String accountName = 'Choice Lux Cars (Pty) Ltd';
  static const String accountNumber = '1234567890';
  static const String branchCode = '051001';
}

// Storage constants
class StorageConstants {
  static const String pdfDocumentsBucket = 'pdfdocuments';
  static const String invoicesFolder = 'invoices';
  static const String quotesFolder = 'quotes';
  static const String vouchersFolder = 'vouchers';
  static const String jobPhotosFolder = 'job-photos';
  static const String clientPhotosFolder = 'client-photos';
}

// Default values
class DefaultValues {
  static const String defaultPassengerName = 'Unnamed Job';
  static const String defaultClientName = 'Unknown Client';
  static const String defaultDriverName = 'Unassigned';
  static const String defaultVehicleName = 'Vehicle not assigned';
  static const String defaultJobNumberPrefix = 'Job #';
  static const String defaultCompanyName = 'Choice Lux Cars';
  static const String defaultCompanyWebsite = 'www.choiceluxcars.com';
}