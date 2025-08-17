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
  static AuthError toAuthError(Object? error) {
    if (error == null) {
      return AuthError('An unknown error occurred');
    }
    
    if (error is AuthError) {
      return error;
    }
    
    try {
      final errorString = error.toString().toLowerCase();
      
      // Handle common authentication errors
      if (errorString.contains('invalid login credentials') ||
          errorString.contains('invalid email or password') ||
          errorString.contains('invalid credentials')) {
        return AuthError('Invalid email or password. Please check your credentials and try again.', error.toString());
      } else if (errorString.contains('email not confirmed') ||
                 errorString.contains('email not verified')) {
        return AuthError('Please check your email and confirm your account before signing in.', error.toString());
      } else if (errorString.contains('too many requests') ||
                 errorString.contains('rate limit') ||
                 errorString.contains('too many attempts')) {
        return AuthError('Too many login attempts. Please wait a moment before trying again.', error.toString());
      } else if (errorString.contains('user not found') ||
                 errorString.contains('email not found') ||
                 errorString.contains('no user found')) {
        return AuthError('No account found with this email address. Please check your email or sign up.', error.toString());
      } else if (errorString.contains('network') ||
                 errorString.contains('connection') ||
                 errorString.contains('timeout') ||
                 errorString.contains('unable to connect')) {
        return AuthError('Network error. Please check your internet connection and try again.', error.toString());
      } else if (errorString.contains('server error') ||
                 errorString.contains('internal server error') ||
                 errorString.contains('500') ||
                 errorString.contains('502') ||
                 errorString.contains('503')) {
        return AuthError('Server error. Please try again later.', error.toString());
      } else if (errorString.contains('invalid email') ||
                 errorString.contains('malformed email')) {
        return AuthError('Please enter a valid email address.', error.toString());
      } else if (errorString.contains('password too short') ||
                 errorString.contains('password requirements')) {
        return AuthError('Password does not meet requirements.', error.toString());
      }
      
      // Return a sanitized version of the error message
      final sanitizedMessage = error.toString().replaceAll('Exception:', '').replaceAll('Error:', '').trim();
      return AuthError(sanitizedMessage, error.toString());
    } catch (e) {
      print('Error in AuthErrorUtils.toAuthError: $e');
      return AuthError('An unexpected error occurred. Please try again.', error.toString());
    }
  }

  /// Get user-friendly error message from any auth error
  static String getErrorMessage(Object? error) {
    return toAuthError(error).message;
  }

  /// Get field-specific error message for form validation
  static String? getFieldError(String fieldName, Object? error) {
    try {
      if (error == null) return null;
      
      final errorString = error.toString().toLowerCase();
      
      switch (fieldName) {
        case 'email':
          if (errorString.contains('user not found') || errorString.contains('email not found')) {
            return 'No account found with this email address';
          } else if (errorString.contains('email not confirmed')) {
            return 'Please confirm your email address first';
          } else if (errorString.contains('invalid email')) {
            return 'Please enter a valid email address';
          }
          break;
        case 'password':
          if (errorString.contains('invalid login credentials') || errorString.contains('invalid password')) {
            return 'Incorrect password';
          } else if (errorString.contains('password too short')) {
            return 'Password is too short';
          }
          break;
      }
      
      return null;
    } catch (e) {
      print('Error in AuthErrorUtils.getFieldError: $e');
      return null;
    }
  }
}
