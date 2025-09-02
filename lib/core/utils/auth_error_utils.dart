import 'package:choice_lux_cars/core/logging/log.dart';

/// Custom auth error class to prevent red screens
class AuthError implements Exception {
  final String message;
  final String? originalError;
  
  AuthError(this.message, [this.originalError]);
  
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
        code: 'unknown_error',
        message: 'An unexpected error occurred',
        field: null,
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
}
