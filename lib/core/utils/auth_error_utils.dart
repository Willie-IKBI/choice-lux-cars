import 'package:choice_lux_cars/core/logging/log.dart';

/// Custom auth error class to prevent red screens
class AuthError implements Exception {
  final String message;
  final String? originalError;
  final String? code;
  final String? field;

  AuthError(this.message, [this.originalError, this.code, this.field]);

  @override
  String toString() => message;
}

/// Centralized authentication error handling utilities
class AuthErrorUtils {
  /// Convert any error to a safe AuthError
  static AuthError toAuthError(dynamic error) {
    try {
      if (error is String) {
        return _parseStringError(error);
      } else if (error is Map<String, dynamic>) {
        return _parseMapError(error);
      } else {
        return _parseGenericError(error);
      }
    } catch (e) {
      Log.e('Error in AuthErrorUtils.toAuthError: $e');
      return AuthError(
        'An unexpected error occurred',
        null,
        'unknown_error',
        null,
      );
    }
  }

  /// Get user-friendly error message from any auth error
  static String getErrorMessage(Object? error) {
    return toAuthError(error).message;
  }

  /// Get field-specific error message for form validation
  static String? getFieldError(String errorMessage, String fieldName) {
    try {
      final lowerMessage = errorMessage.toLowerCase();
      final lowerField = fieldName.toLowerCase();

      if (lowerMessage.contains(lowerField)) {
        return errorMessage;
      }

      return null;
    } catch (e) {
      Log.e('Error in AuthErrorUtils.getFieldError: $e');
      return null;
    }
  }

  /// Parse string errors
  static AuthError _parseStringError(String error) {
    return AuthError(error, error);
  }

  /// Parse map errors
  static AuthError _parseMapError(Map<String, dynamic> error) {
    final message = error['message']?.toString() ?? 'Unknown error';
    final code = error['code']?.toString();
    final field = error['field']?.toString();
    return AuthError(message, null, code, field);
  }

  /// Parse generic errors
  static AuthError _parseGenericError(dynamic error) {
    final message = error?.toString() ?? 'Unknown error';
    return AuthError(message, message);
  }
}
