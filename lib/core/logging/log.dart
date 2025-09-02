import 'dart:developer' as dev;

/// Centralized logging utility for the application
///
/// Provides consistent logging methods that can be easily configured
/// and replaced across the entire codebase.
class Log {
  /// Debug logging - only active in debug mode
  static void d(String msg, [Object? err, StackTrace? st]) {
    assert(() {
      dev.log(msg, error: err, stackTrace: st, name: 'debug');
      return true;
    }());
  }

  /// Error logging - always active
  static void e(String msg, [Object? err, StackTrace? st]) {
    dev.log(msg, error: err, stackTrace: st, name: 'error', level: 1000);
  }
}
