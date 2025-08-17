// User roles
enum UserRole {
  admin,
  manager,
  driver,
  driverManager,
  agent,
  unassigned,
}

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
enum QuoteStatus {
  draft,
  sent,
  accepted,
  rejected,
  expired,
}

// Invoice statuses
enum InvoiceStatus {
  pending,
  paid,
  overdue,
  cancelled,
}

// App constants
class AppConstants {
  // API endpoints
  // Production Supabase instance
  // For local development, use: http://127.0.0.1:54321 and local anon key
  static const String supabaseUrl = 'https://hgqrbekphumdlsifuamq.supabase.co';
  static const String supabaseAnonKey = 'sb_publishable_bGWh1bK234YwSEU8YLWu5g_gfqxDQAH';
  
  // Firebase Configuration
  static const String firebaseApiKey = 'AIzaSyDHtTfl-FLRmImEmizLaauW-NMc6rVp_AM';
  static const String firebaseAuthDomain = 'choice-lux-cars-8d510.firebaseapp.com';
  static const String firebaseProjectId = 'choice-lux-cars-8d510';
  static const String firebaseStorageBucket = 'choice-lux-cars-8d510.firebasestorage.app';
  static const String firebaseMessagingSenderId = '522491134348';
  static const String firebaseAppId = '1:522491134348:web:3ac424d68338b3ddb7d6a9';
  
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
  static const String networkError = 'Network error. Please check your connection.';
  static const String permissionError = 'You don\'t have permission to perform this action.';
  static const String validationError = 'Please check your input and try again.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  static const String fileTooLarge = 'File size exceeds the maximum limit of 10MB.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String weakPassword = 'Password must be at least 8 characters long.';
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