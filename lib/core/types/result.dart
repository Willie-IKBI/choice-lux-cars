import 'package:choice_lux_cars/core/errors/app_exception.dart';

/// Result type for handling success/failure outcomes
///
/// Provides a type-safe way to handle operations that can succeed
/// or fail, without throwing exceptions.
class Result<T> {
  final T? data;
  final AppException? error;

  const Result._({this.data, this.error});

  /// Create a successful result with data
  const Result.success(T data) : this._(data: data);

  /// Create a failed result with an error
  const Result.failure(AppException error) : this._(error: error);

  /// Check if the result is successful
  bool get isSuccess => error == null;

  /// Check if the result is a failure
  bool get isFailure => error != null;

  /// Get the data, throwing if this is a failure result
  T get requireValue {
    if (isSuccess) {
      return data as T;
    }
    throw error!;
  }

  /// Get the error, throwing if this is a success result
  AppException get requireError {
    if (isFailure) {
      return error!;
    }
    throw StateError('Result is successful, no error available');
  }

  /// Transform the data if successful, otherwise return the error
  Result<R> map<R>(R Function(T) transform) {
    if (isSuccess) {
      return Result.success(transform(data as T));
    }
    return Result.failure(error!);
  }

  /// Transform the data if successful, otherwise return the error
  Result<R> flatMap<R>(Result<R> Function(T) transform) {
    if (isSuccess) {
      return transform(data as T);
    }
    return Result.failure(error!);
  }

  /// Execute a function if the result is successful
  Result<T> onSuccess(void Function(T) action) {
    if (isSuccess) {
      action(data as T);
    }
    return this;
  }

  /// Execute a function if the result is a failure
  Result<T> onFailure(void Function(AppException) action) {
    if (isFailure) {
      action(error!);
    }
    return this;
  }
}
