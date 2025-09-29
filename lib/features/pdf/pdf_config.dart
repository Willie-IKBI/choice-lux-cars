/// PDF configuration constants to eliminate hardcoded values
/// 
/// This class centralizes all PDF-related configuration values used across:
/// - InvoicePdfService
/// - VoucherPdfService  
/// - QuotePdfService
class PdfConfig {
  // ---- LOGO CONFIGURATION --------------------------------------------------

  /// Default company logo URL
  static const String defaultLogoUrl = 
      'https://hgqrbekphumdlsifuamq.supabase.co/storage/v1/object/public/clc_images/app_images/logo%20-%20512.png';

  // ---- DIMENSIONS -----------------------------------------------------------

  /// Standard circle size for numbered terms
  static const double circleSize = 16.0;

  /// Standard icon size
  static const double iconSize = 24.0;

  /// Standard logo height
  static const double logoHeight = 30.0;

  /// Standard logo width  
  static const double logoWidth = 80.0;

  // ---- TYPOGRAPHY ----------------------------------------------------------

  /// Standard font size for body text
  static const double bodyFontSize = 10.0;

  /// Standard font size for labels
  static const double labelFontSize = 10.0;

  /// Standard font size for captions
  static const double captionFontSize = 8.0;

  /// Standard font size for titles
  static const double titleFontSize = 12.0;

  // ---- SPACING --------------------------------------------------------------

  /// Standard padding for containers
  static const double containerPadding = 12.0;

  /// Standard margin for elements
  static const double elementMargin = 8.0;

  /// Standard bottom padding for terms
  static const double termBottomPadding = 6.0;

  /// Standard bottom padding for key-value pairs
  static const double keyValueBottomPadding = 4.0;

  // ---- BORDERS -------------------------------------------------------------

  /// Standard border radius
  static const double borderRadius = 6.0;

  /// Standard border width
  static const double borderWidth = 0.5;

  /// Standard circle border radius
  static const double circleBorderRadius = 8.0;

  // ---- TABLE CONFIGURATION ------------------------------------------------

  /// Standard table column widths
  static const Map<int, double> tableColumnWidths = {
    0: 80.0,  // Date column
    1: 60.0,  // Time column
    2: 2.0,   // Pickup location (flex)
    3: 2.0,   // Dropoff location (flex)
  };

  // ---- COMPANY INFORMATION ------------------------------------------------

  /// Default company name
  static const String defaultCompanyName = 'Choice Lux Cars';

  /// Default company website
  static const String defaultCompanyWebsite = 'www.choiceluxcars.com';

  /// Default company email
  static const String defaultCompanyEmail = 'bookings@choiceluxcars.com';

  /// Default footer text
  static const String defaultFooterText = 'www.choiceluxcars.com | bookings@choiceluxcars.com';

  // ---- BANKING DETAILS ---------------------------------------------------

  /// Default bank name
  static const String defaultBankName = 'Standard Bank';

  /// Default account name
  static const String defaultAccountName = 'Choice Lux Cars (Pty) Ltd';

  /// Default account number
  static const String defaultAccountNumber = '1234567890';

  /// Default branch code
  static const String defaultBranchCode = '051001';

  /// Default swift code
  static const String defaultSwiftCode = 'SBZAZAJJ';

  // ---- CURRENCY & LOCALE -------------------------------------------------

  /// Default currency symbol
  static const String defaultCurrencySymbol = 'R';

  /// Default currency code
  static const String defaultCurrencyCode = 'ZAR';

  /// Default locale
  static const String defaultLocale = 'en_ZA';

  /// Default date format
  static const String defaultDateFormat = 'dd/MM/yyyy';

  /// Default time format
  static const String defaultTimeFormat = 'HH:mm';
}
