import 'dart:developer' as dev;

class Log {
  static void d(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(message, error: error, stackTrace: stackTrace);
  }
}
