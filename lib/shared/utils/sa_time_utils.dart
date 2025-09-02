import 'package:intl/intl.dart';

/// Centralized South African timezone utilities
/// Ensures all timestamps are consistently in SAST (UTC+2)
class SATimeUtils {
  /// South African timezone identifier
  static const String _saTimezone = 'Africa/Johannesburg';
  
  /// Get current time in South African timezone
  static DateTime getCurrentSATime() {
    final now = DateTime.now().toUtc();
    // SAST is UTC+2
    return now.add(const Duration(hours: 2));
  }
  
  /// Convert any DateTime to South African time
  static DateTime convertToSATime(DateTime dateTime) {
    if (dateTime.isUtc) {
      return dateTime.add(const Duration(hours: 2));
    } else {
      // If it's already local time, convert to UTC first then to SA
      final utc = dateTime.toUtc();
      return utc.add(const Duration(hours: 2));
    }
  }
  
  /// Format DateTime for display in South African time
  static String formatSATime(DateTime dateTime) {
    final saTime = convertToSATime(dateTime);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(saTime);
  }
  
  /// Format DateTime for database storage (ISO8601 in SA time)
  static String formatSATimeForDatabase(DateTime dateTime) {
    final saTime = convertToSATime(dateTime);
    return saTime.toIso8601String();
  }
  
  /// Parse ISO8601 string and convert to South African time
  static DateTime? parseSATimeFromDatabase(String? dateTimeString) {
    if (dateTimeString == null || dateTimeString.isEmpty) return null;
    try {
      final parsed = DateTime.parse(dateTimeString);
      return convertToSATime(parsed);
    } catch (e) {
      return null;
    }
  }
  
  /// Get current SA time as ISO8601 string for database storage
  static String getCurrentSATimeISO() {
    return getCurrentSATime().toIso8601String();
  }
  
  /// Check if a DateTime is in South African timezone
  static bool isInSATimezone(DateTime dateTime) {
    // SAST is UTC+2, so check if the time difference is approximately 2 hours
    final utc = dateTime.toUtc();
    final difference = dateTime.difference(utc);
    return (difference.inHours == 2 || difference.inHours == 1); // Account for DST
  }
  
  /// Get South African timezone offset string
  static String getSATimezoneOffset() {
    final now = DateTime.now();
    final saTime = getCurrentSATime();
    final offset = saTime.difference(now.toUtc());
    final hours = offset.inHours;
    final minutes = offset.inMinutes % 60;
    return '${hours >= 0 ? '+' : ''}${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}
