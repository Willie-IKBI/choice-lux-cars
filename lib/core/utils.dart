import 'package:intl/intl.dart';
import 'package:choice_lux_cars/core/constants.dart';

// Date and time formatting utilities
class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatDateLong(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  static String formatDateTime(DateTime dateTime) {
    return DateFormat(AppConstants.dateTimeFormat).format(dateTime);
  }

  static String formatTime(DateTime time) {
    return DateFormat(AppConstants.timeFormat).format(time);
  }

  static String formatDateISO(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDateTimeISO(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return formatDate(date);
    }
  }

  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  static DateTime? parseDate(String dateString) {
    try {
      return DateFormat(AppConstants.dateFormat).parse(dateString);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return DateFormat(AppConstants.dateTimeFormat).parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseISODateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }
}

// Currency formatting utilities
class CurrencyUtils {
  static String formatCurrency(double amount) {
    return '${AppConstants.currencySymbol}${amount.toStringAsFixed(2)}';
  }

  static String formatCurrencyWithCommas(double amount) {
    final formatter = NumberFormat.currency(
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static double? parseCurrency(String currencyString) {
    try {
      final cleanString = currencyString
          .replaceAll(AppConstants.currencySymbol, '')
          .replaceAll(',', '')
          .trim();
      return double.parse(cleanString);
    } catch (e) {
      return null;
    }
  }

  /// Format a number with spaces as thousand separator: 45000 -> "45 000"
  static String formatWithSpaces(num value) {
    final isNegative = value < 0;
    final absStr = value.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (var i = 0; i < absStr.length; i++) {
      if (i > 0 && (absStr.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(absStr[i]);
    }
    return isNegative ? '-${buffer.toString()}' : buffer.toString();
  }

  /// Format currency with R prefix and space-separated thousands: 45000 -> "R45 000"
  static String formatCompact(double amount) {
    return 'R${formatWithSpaces(amount)}';
  }
}

// Validation utilities
class ValidationUtils {
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  static bool isValidPassword(String password) {
    return password.length >= AppConstants.minPasswordLength;
  }

  static bool isValidPhoneNumber(String phone) {
    // Basic UK phone number validation
    final phoneRegex = RegExp(r'^(\+44|0)[1-9]\d{1,4}\s?\d{3,4}\s?\d{3,4}$');
    return phoneRegex.hasMatch(phone.replaceAll(RegExp(r'\s'), ''));
  }

  static bool isValidPostcode(String postcode) {
    // UK postcode validation
    final postcodeRegex = RegExp(
      r'^[A-Z]{1,2}[0-9R][0-9A-Z]?\s?[0-9][ABD-HJLNP-UW-Z]{2}$',
      caseSensitive: false,
    );
    return postcodeRegex.hasMatch(postcode.trim());
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    if (!isValidEmail(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (!isValidPassword(password)) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters long';
    }
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!isValidPhoneNumber(phone)) {
      return 'Please enter a valid phone number';
    }
    return null;
  }
}

// String utilities
class StringUtils {
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  static String capitalizeWords(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) => capitalize(word)).join(' ');
  }

  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  static String removeSpecialCharacters(String text) {
    return text.replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  static String generateInitials(String firstName, String lastName) {
    final first = firstName.isNotEmpty ? firstName[0].toUpperCase() : '';
    final last = lastName.isNotEmpty ? lastName[0].toUpperCase() : '';
    return '$first$last';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

// Enum utilities
class EnumUtils {
  static String formatEnum(dynamic enumValue) {
    return enumValue.toString().split('.').last;
  }

  static String formatEnumWithSpaces(dynamic enumValue) {
    final name = formatEnum(enumValue);
    return name
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim();
  }

  static String formatEnumTitle(dynamic enumValue) {
    return StringUtils.capitalizeWords(formatEnumWithSpaces(enumValue));
  }
}

// Extension methods
extension StringExtensions on String {
  String get capitalize => StringUtils.capitalize(this);
  String get capitalizeWords => StringUtils.capitalizeWords(this);
  String truncate(int maxLength) => StringUtils.truncate(this, maxLength);
  bool get isValidEmail => ValidationUtils.isValidEmail(this);
  bool get isValidPassword => ValidationUtils.isValidPassword(this);
  bool get isValidPhone => ValidationUtils.isValidPhoneNumber(this);
}

extension DateTimeExtensions on DateTime {
  String get formattedDate => DateUtils.formatDate(this);
  String get formattedDateTime => DateUtils.formatDateTime(this);
  String get formattedTime => DateUtils.formatTime(this);
  String get relativeDate => DateUtils.formatRelativeDate(this);
}

extension DoubleExtensions on double {
  String get formattedCurrency => CurrencyUtils.formatCurrency(this);
  String get formattedCurrencyWithCommas =>
      CurrencyUtils.formatCurrencyWithCommas(this);
}
