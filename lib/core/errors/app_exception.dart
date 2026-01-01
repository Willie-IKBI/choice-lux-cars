/// Sealed class for application exceptions
///
/// Provides a type-safe way to handle different types of errors
/// that can occur in the application.
sealed class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => 'AppException: $message';
}

/// Exception for network-related errors
class NetworkException extends AppException {
  const NetworkException(super.message);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception for authentication-related errors
class AuthException extends AppException {
  const AuthException(super.message);

  @override
  String toString() => 'AuthException: $message';
}

/// Exception for validation-related errors
class ValidationException extends AppException {
  const ValidationException(super.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Exception for unknown or unexpected errors
class UnknownException extends AppException {
  const UnknownException(super.message);

  @override
  String toString() => 'UnknownException: $message';
}
