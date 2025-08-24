import 'package:intl/intl.dart';

/// Centralized date utilities to eliminate duplicate functions
class DateUtils {
  /// Format date to 'MMM dd, yyyy' format
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date to 'dd MMM yyyy' format
  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Format date to 'MMM dd, yyyy HH:mm' format
  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy HH:mm').format(date);
  }

  /// Format date to 'HH:mm' format
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  /// Format date to 'yyyy-MM-dd' format
  static String formatDateISO(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format date to 'yyyy-MM-dd HH:mm:ss' format
  static String formatDateTimeISO(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }

  /// Parse ISO date string to DateTime
  static DateTime? parseISODateTime(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;
    try {
      return DateTime.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// Format relative time (e.g., "2 hours ago", "3 days ago")
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

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && 
           date.month == yesterday.month && 
           date.day == yesterday.day;
  }

  /// Get days until date
  static int getDaysUntil(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    return difference.inDays;
  }

  /// Get days since date
  static int getDaysSince(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    return difference.inDays;
  }
}
